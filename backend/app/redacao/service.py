"""Serviço do domínio redação — lado do aluno (fatia 1 do completo).

Cobre a lista (`GET /redacoes`) e o envio (`POST .../envio`). O pipeline
assíncrono (OCR → análise → extração → atribuição, Bloco 2b) entra nas fatias
seguintes: aqui o envio para em `status='enviada'`.

Decisões da fatia 1 (datadas em design/notas-implementacao.md):
- O tipo do arquivo é validado pela **assinatura** (magic bytes), não pelo
  content-type declarado — o cliente não é confiável e foto renomeada não passa.
- Fotos (jpeg/png/webp) → `formato='manuscrita'`, até MAX_PAGINAS por envio;
  um único PDF → `formato='digital'`. Misturar os dois é rejeitado.
- Reenvio **substitui** o anterior enquanto a análise não saiu; depois de
  `analisada`, 409 (a análise vinculou palavras à trilha — trocar o texto por
  baixo dela quebraria o vínculo).
"""
import json
import secrets
from datetime import datetime, timezone

from sqlalchemy.ext.asyncio import AsyncConnection

from app.errors import ApiError
from app.redacao import repository as repo
from app.redacao.schemas import EnvioOut, RedacaoAlunoOut, RedacoesAlunoOut
from app.redacao.storage import armazenamento

MAX_PAGINAS = 6
MAX_BYTES_POR_ARQUIVO = 10 * 1024 * 1024  # fotos de celular ficam bem abaixo

# Assinaturas aceitas → (extensão, formato do envio).
_ASSINATURAS: list[tuple[bytes, str, str]] = [
    (b"\xff\xd8\xff", "jpg", "manuscrita"),
    (b"\x89PNG\r\n\x1a\n", "png", "manuscrita"),
    (b"%PDF", "pdf", "digital"),
]


def _identificar(conteudo: bytes) -> tuple[str, str] | None:
    """(extensão, formato) pela assinatura do arquivo; None = não reconhecido."""
    for assinatura, extensao, formato in _ASSINATURAS:
        if conteudo.startswith(assinatura):
            return extensao, formato
    # WEBP: RIFF????WEBP (o tamanho vem entre o RIFF e o WEBP).
    if conteudo[:4] == b"RIFF" and conteudo[8:12] == b"WEBP":
        return "webp", "manuscrita"
    return None


def _paginas(arquivo_ref: str | None) -> int:
    return len(json.loads(arquivo_ref)) if arquivo_ref else 0


async def listar(conn: AsyncConnection, usuario_id: int) -> RedacoesAlunoOut:
    turma_id = await repo.turma_do_aluno(conn, usuario_id)
    if turma_id is None:
        return RedacoesAlunoOut(itens=[])
    linhas = await repo.atribuicoes_do_aluno(conn, usuario_id, turma_id)
    return RedacoesAlunoOut(
        itens=[
            RedacaoAlunoOut(
                atribuicao_id=li.atribuicao_id,
                tema=li.tema,
                prazo=li.prazo,
                redacao=(
                    None
                    if li.redacao_id is None
                    else EnvioOut(
                        redacao_id=li.redacao_id,
                        status=li.status,
                        enviada_em=li.enviada_em,
                        paginas=_paginas(li.arquivo_ref),
                    )
                ),
            )
            for li in linhas
        ]
    )


async def enviar(
    conn: AsyncConnection,
    usuario_id: int,
    atribuicao_id: int,
    arquivos: list[bytes],
) -> EnvioOut:
    turma_id = await repo.turma_do_aluno(conn, usuario_id)
    atribuicao = await repo.buscar_atribuicao(conn, atribuicao_id)
    if atribuicao is None or atribuicao.turma_id != turma_id:
        # Fora da turma responde igual a inexistente — não vaza o que existe.
        raise ApiError(
            404, "atribuicao_nao_encontrada", "Redação não encontrada para a sua turma."
        )

    if not arquivos:
        raise ApiError(422, "envio_vazio", "Envie pelo menos uma página.")
    if len(arquivos) > MAX_PAGINAS:
        raise ApiError(
            422,
            "paginas_demais",
            f"Um envio pode ter no máximo {MAX_PAGINAS} páginas.",
            {"maximo": MAX_PAGINAS},
        )

    identificados: list[tuple[bytes, str, str]] = []  # (conteudo, extensao, formato)
    for indice, conteudo in enumerate(arquivos):
        if len(conteudo) > MAX_BYTES_POR_ARQUIVO:
            raise ApiError(
                413,
                "arquivo_grande",
                "Arquivo grande demais (máx. 10 MB por página).",
                {"pagina": indice + 1},
            )
        tipo = _identificar(conteudo)
        if tipo is None:
            raise ApiError(
                422,
                "arquivo_invalido",
                "Formato não suportado — envie fotos (JPG/PNG) ou um PDF.",
                {"pagina": indice + 1},
            )
        identificados.append((conteudo, *tipo))

    formatos = {formato for _, _, formato in identificados}
    if formatos == {"digital"} and len(identificados) > 1:
        raise ApiError(
            422, "arquivo_invalido", "Envio digital é um único PDF."
        )
    if len(formatos) > 1:
        raise ApiError(
            422, "arquivo_invalido", "Não misture fotos e PDF no mesmo envio."
        )
    formato = formatos.pop()

    anterior = await repo.buscar_envio(conn, atribuicao_id, usuario_id)
    if anterior is not None and anterior.status == "analisada":
        raise ApiError(
            409,
            "redacao_ja_analisada",
            "Esta redação já foi analisada e não pode ser reenviada.",
        )

    # Grava as páginas antes de tocar o banco: se o envio falhar no meio, sobra
    # no máximo lixo órfão no storage (inofensivo), nunca uma linha sem arquivo.
    storage = armazenamento()
    lote = secrets.token_hex(4)  # chaves novas a cada envio — reenvio não colide
    chaves: list[str] = []
    for numero, (conteudo, extensao, _) in enumerate(identificados, start=1):
        chave = f"atribuicao_{atribuicao_id}/usuario_{usuario_id}/{lote}_p{numero}.{extensao}"
        await storage.salvar(chave, conteudo)
        chaves.append(chave)

    enviada_em = datetime.now(timezone.utc)
    arquivo_ref = json.dumps(chaves)
    if anterior is None:
        redacao_id = await repo.criar_envio(
            conn, atribuicao_id, usuario_id, formato, arquivo_ref, enviada_em
        )
    else:
        redacao_id = anterior.id
        await repo.substituir_envio(conn, redacao_id, formato, arquivo_ref, enviada_em)
        # Arquivos do envio substituído: remoção melhor-esforço (se falhar, é
        # só espaço ocupado — nunca derruba um envio que já deu certo).
        for chave in json.loads(anterior.arquivo_ref or "[]"):
            try:
                await storage.remover(chave)
            except OSError:
                pass

    return EnvioOut(
        redacao_id=redacao_id,
        status="enviada",
        enviada_em=enviada_em,
        paginas=len(chaves),
    )
