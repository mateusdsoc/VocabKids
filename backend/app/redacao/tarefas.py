"""Tarefas da fila do pipeline de redação (Bloco 2b) — orquestração e estados.

Máquina de estados em `redacao.status` (única fonte de verdade):

    enviada → processando → analisada
                        ↘ erro_ingestao | erro_analise   (permanentes, do miolo)

Cada etapa é uma task com **retry/backoff exponencial**: exceção não-domínio
(banco/storage fora do ar) relança e a fila reagenda; falha PERMANENTE do miolo
(`pipeline.ErroIngestao`/`ErroAnalise`) vira `status erro_*` e o job termina
normalmente do ponto de vista da fila — o erro pertence à redação, não à
infraestrutura. Reprocessar é seguro: cada task checa o status antes de agir
(job atrasado sobre estado superado retorna sem efeito).

Corrida com o commit da API: o defer sai durante a request, mas a transação da
API comita depois (middleware `db_transacao`) e a fila usa conexão própria — o
worker pode acordar antes do commit. Por isso "redação não encontrada" na
ingestão relança (transitório) e o retry resolve.
"""
import json
from datetime import datetime, timezone

import procrastinate

from app.db import engine
from app.fila import fila
from app.redacao import pipeline
from app.redacao import repository as repo
from app.redacao.storage import armazenamento

_RETRY = procrastinate.RetryStrategy(max_attempts=5, exponential_wait=2)


@fila.task(name="redacao.ingestao", retry=_RETRY)
async def ingestao(redacao_id: int) -> None:
    """Etapa 1 — arquivos → `texto_extraido`; encadeia a análise."""
    async with engine.begin() as conn:
        red = await repo.buscar_redacao(conn, redacao_id)
        if red is None:
            # Provável corrida com o commit do envio — transitório, retry.
            raise RuntimeError(f"redação {redacao_id} ainda não visível")
        if red.status not in ("enviada", "processando"):
            return  # estado superado (reenvio/erro/analisada) — nada a fazer
        await repo.atualizar_status(conn, redacao_id, "processando")

    storage = armazenamento()
    paginas = [await storage.ler(c) for c in json.loads(red.arquivo_ref or "[]")]
    try:
        texto = await pipeline.extrair_texto(red.formato, paginas)
    except pipeline.ErroIngestao:
        async with engine.begin() as conn:
            await repo.atualizar_status(conn, redacao_id, "erro_ingestao")
        return

    if texto is None:
        return  # stub (fatia 3) — fica em processando, sem inventar resultado
    async with engine.begin() as conn:
        await repo.gravar_texto(conn, redacao_id, texto)
    await analise.defer_async(redacao_id=redacao_id)


@fila.task(name="redacao.analise", retry=_RETRY)
async def analise(redacao_id: int) -> None:
    """Etapa 2 — `texto_extraido` → `redacao_analise`; encadeia a extração."""
    async with engine.begin() as conn:
        red = await repo.buscar_redacao(conn, redacao_id)
        if red is None:
            raise RuntimeError(f"redação {redacao_id} não encontrada")
        if red.status != "processando" or red.texto_extraido is None:
            return  # estado superado ou chegada fora de ordem

    try:
        anotacoes = await pipeline.analisar(red.texto_extraido)
    except pipeline.ErroAnalise:
        async with engine.begin() as conn:
            await repo.atualizar_status(conn, redacao_id, "erro_analise")
        return

    if anotacoes is None:
        return  # stub (fatia 4) — fica em processando
    async with engine.begin() as conn:
        await repo.gravar_analise(conn, redacao_id, anotacoes)
    await extracao_atribuicao.defer_async(redacao_id=redacao_id)


@fila.task(name="redacao.extracao_atribuicao", retry=_RETRY)
async def extracao_atribuicao(redacao_id: int) -> None:
    """Etapa 3+4 — palavras da análise → trilha; fecha em `analisada`.

    Fatia 5 dá corpo à extração/atribuição (Hunspell/spaCy, buscar_ou_gerar,
    `aluno_palavra` com gatilho). Aqui a lista vazia do stub já finaliza: a
    análise existe; palavras são o elo com a trilha, não pré-requisito.
    """
    async with engine.begin() as conn:
        red = await repo.buscar_redacao(conn, redacao_id)
        if red is None:
            raise RuntimeError(f"redação {redacao_id} não encontrada")
        if red.status != "processando":
            return
        registro = await repo.buscar_analise(conn, redacao_id)
        if registro is None:
            return  # chegada fora de ordem — a análise encadeia de novo

    palavras = await pipeline.extrair_palavras(registro.anotacoes)
    # Fatia 5: gravar redacao_palavra + buscar_ou_gerar + atribuir à trilha.
    _ = palavras

    async with engine.begin() as conn:
        await repo.finalizar_analisada(
            conn, redacao_id, datetime.now(timezone.utc)
        )
