"""Orquestração da redação B2C — atribuição de tema, envio, pipeline de análise.

Pipeline (§7.3, versão desta sessão — ver pendências abaixo):

    enviar_redacao()
      1. validar tamanho vs rubrica da faixa           (rubrica.validar_tamanho)
      2. UMA chamada ao Analisador: triagem (R-RD-7) + análise pedagógica
      3. risco_sinalizado → 'revisao_humana', sem gravar análise nem notificar
         a criança; sem análise → grava anotações + palavras extraídas

⚠️ Pendências explícitas desta sessão (sem infra disponível para resolver
agora — ver `design/notas-implementacao.md`, Fase 4, 25/08):

- **Roda SÍNCRONO no request**, não em fila (`procrastinate`, citado no plano
  original) — não há worker configurado neste repo. Aceitável para validar o
  MVP, mas a criança espera a chamada de LLM terminar (segundos) com a tela
  presa; sob carga real isso não escala e vira fila de verdade.
- **Atribuição automática é "preguiçosa"** (`garantir_atribuicao_atual`, ao
  listar): sem cron/scheduler no repo, o próximo tema só nasce quando o app
  pergunta (`GET /redacoes`), não no dia exato dos 15 — equivalente na
  prática (só importa quando a criança abre o app), mas divergente da leitura
  literal de R-RD-1 ("a cada 15 dias").
- **R-RD-5** (notificar o responsável quando uma redação cai em revisão
  humana, "texto acolhedor pré-aprovado") não está implementado — não existe
  canal de notificação/push no repo ainda. `redacao.risco_motivo` fica
  gravado para a Fase 5 (Área do Responsável) mostrar, mas ninguém é avisado
  ativamente até lá.
- **§7.3 passo 4 (buscar_ou_gerar_e_atribuir palavra_gatilho → trilha)** não
  está implementado: `redacao_palavra` grava as palavras fracas/superutilizadas
  extraídas, mas nada as transforma em `palavra` real nem as enfileira na
  revisão pessoal do aluno. O próprio plano (§10.1 passo 5) exige revisão
  humana por amostragem antes de qualquer palavra gerada por LLM entrar em
  produção — automatizar isso sem essa camada seria pular a única salvaguarda
  de qualidade que o plano pede. Fica como trabalho de conteúdo, não como bug.
"""
from datetime import datetime, timedelta, timezone

from sqlalchemy.ext.asyncio import AsyncConnection

from app.errors import ApiError
from app.redacao import repository as repo
from app.redacao.analisador import Analisador, ResultadoAnalise
from app.redacao.rubrica import validar_tamanho

DIAS_ENTRE_TEMAS = 15
EXTRAS_MAX_POR_MES = 2  # R-RD-4


async def garantir_atribuicao_atual(conn: AsyncConnection, usuario_id: int) -> None:
    """Cria a próxima atribuição automática se não houver nenhuma, ou se a
    última tiver >= DIAS_ENTRE_TEMAS. Ver a nota de "atribuição preguiçosa" no
    docstring do módulo — não é um cron, é best-effort no momento do GET."""
    faixa = await repo.faixa_etaria_do_perfil(conn, usuario_id)
    if faixa is None:
        return  # não é um perfil_crianca (ex.: aluno B2B congelado) — sem redação automática

    atual = await repo.atribuicao_mais_recente(conn, usuario_id)
    if atual is not None:
        limite = datetime.now(timezone.utc) - timedelta(days=DIAS_ENTRE_TEMAS)
        if atual.created_at >= limite:
            return

    tema = await repo.tema_disponivel(conn, faixa_etaria=faixa, usuario_id=usuario_id)
    if tema is None:
        return  # catálogo esgotado para a faixa (ver pendência de conteúdo, §10.4) — sem atribuição nova
    await repo.criar_atribuicao(
        conn, usuario_id=usuario_id, tema_catalogo_id=tema.id, tema=tema.titulo, origem="automatica"
    )


async def listar_redacoes(conn: AsyncConnection, usuario_id: int) -> dict:
    await garantir_atribuicao_atual(conn, usuario_id)
    linhas = await repo.listar_atribuicoes(conn, usuario_id)
    extras_usados = await repo.contar_extras_do_mes(conn, usuario_id)
    return {
        "itens": [
            {
                "id": linha.id,
                "tema": linha.tema,
                "prazo": linha.prazo,
                "origem": linha.origem,
                "redacao_id": linha.redacao_id,
                "status": linha.status,
            }
            for linha in linhas
        ],
        "extras_restantes_no_mes": max(0, EXTRAS_MAX_POR_MES - extras_usados),
    }


async def pedir_tema_extra(conn: AsyncConnection, usuario_id: int) -> dict:
    faixa = await repo.faixa_etaria_do_perfil(conn, usuario_id)
    if faixa is None:
        raise ApiError(404, "perfil_nao_encontrado", "Perfil de criança não encontrado.")

    usados = await repo.contar_extras_do_mes(conn, usuario_id)
    if usados >= EXTRAS_MAX_POR_MES:
        raise ApiError(
            429,
            "limite_de_temas_extras",
            f"Limite de {EXTRAS_MAX_POR_MES} temas extras por mês já foi atingido.",
        )

    tema = await repo.tema_disponivel(conn, faixa_etaria=faixa, usuario_id=usuario_id)
    if tema is None:
        raise ApiError(409, "catalogo_esgotado", "Não há mais temas novos disponíveis para esta faixa agora.")

    atribuicao_id = await repo.criar_atribuicao(
        conn, usuario_id=usuario_id, tema_catalogo_id=tema.id, tema=tema.titulo, origem="sob_demanda"
    )
    return {"atribuicao_id": atribuicao_id, "tema": tema.titulo}


async def enviar_redacao(
    conn: AsyncConnection,
    *,
    usuario_id: int,
    atribuicao_id: int,
    formato: str,
    texto_extraido: str,
    analisador: Analisador,
) -> dict:
    atribuicao = await repo.buscar_atribuicao(conn, atribuicao_id)
    if atribuicao is None or atribuicao.usuario_id != usuario_id:
        raise ApiError(404, "atribuicao_nao_encontrada", "Atribuição de redação não encontrada.")

    faixa = await repo.faixa_etaria_do_perfil(conn, usuario_id)
    if faixa is None:
        raise ApiError(404, "perfil_nao_encontrado", "Perfil de criança não encontrado.")

    redacao_id = await repo.criar_envio(
        conn, atribuicao_id=atribuicao_id, usuario_id=usuario_id, formato=formato, texto_extraido=texto_extraido
    )

    validacao = validar_tamanho(faixa, texto_extraido)
    if not validacao.ok:
        await repo.marcar_erro_ingestao(conn, redacao_id, validacao.motivo)
        return {"redacao_id": redacao_id, "status": "erro_ingestao"}

    try:
        resultado: ResultadoAnalise = await analisador.analisar(
            texto=texto_extraido, faixa_etaria=faixa, tema=atribuicao.tema
        )
    except ApiError:
        raise
    except Exception:
        await repo.marcar_erro_analise(conn, redacao_id)
        return {"redacao_id": redacao_id, "status": "erro_analise"}

    if resultado.risco_sinalizado:
        # R-RD-7: NENHUMA análise pedagógica é gravada/mostrada quando há risco.
        await repo.marcar_revisao_humana(conn, redacao_id, resultado.risco_motivo)
        return {"redacao_id": redacao_id, "status": "revisao_humana"}

    dimensoes = sorted({a.dimensao for a in resultado.anotacoes})
    await repo.gravar_analise(
        conn,
        redacao_id,
        pontos_fortes=resultado.pontos_fortes,
        anotacoes=[
            {
                "dimensao": a.dimensao,
                "titulo": a.titulo,
                "comentario": a.comentario,
                "sugestoes": a.sugestoes,
                "ancoras": [{"trecho": n.trecho, "ocorrencia": n.ocorrencia} for n in a.ancoras],
            }
            for a in resultado.anotacoes
        ],
        dimensoes=dimensoes,
        niveis_dimensao=resultado.niveis_dimensao,
    )
    await repo.gravar_palavras(conn, redacao_id, resultado.palavras)
    return {"redacao_id": redacao_id, "status": "analisada"}


def _resolver_ancoras(texto: str, marcas: list[dict]) -> list[dict]:
    """(trecho, ocorrência) → offsets [inicio, fim) em code points — o backend
    resolve a posição em vez de confiar em offset cru do LLM (mesmo contrato
    da fatia A mockada). Marca não encontrada é descartada (anotação vira
    holística), nunca quebra a tela."""
    ancoras = []
    for marca in marcas:
        trecho, ocorrencia = marca["trecho"], marca["ocorrencia"]
        pos, achados = -1, 0
        while achados < ocorrencia:
            pos = texto.find(trecho, pos + 1)
            if pos == -1:
                break
            achados += 1
        if pos != -1:
            ancoras.append({"inicio": pos, "fim": pos + len(trecho), "trecho": trecho, "ocorrencia": ocorrencia})
    return ancoras


async def obter_analise(conn: AsyncConnection, *, usuario_id: int, redacao_id: int) -> dict:
    redacao = await repo.buscar_redacao(conn, redacao_id)
    if redacao is None or redacao.usuario_id != usuario_id:
        raise ApiError(404, "redacao_nao_encontrada", "Redação não encontrada.")

    if redacao.status != "analisada":
        return {
            "redacao_id": redacao_id,
            "status": redacao.status,
            "texto_extraido": "" if redacao.status == "revisao_humana" else (redacao.texto_extraido or ""),
            "analise": None,
            "palavras_novas": [],
        }

    linha_analise = await repo.buscar_analise(conn, redacao_id)
    bruto = linha_analise.anotacoes
    texto = redacao.texto_extraido or ""
    analise = {
        "versao": bruto["versao"],
        "dimensoes": bruto["dimensoes"],
        "pontos_fortes": bruto["pontos_fortes"],
        "anotacoes": [
            {**a, "ancoras": _resolver_ancoras(texto, a["ancoras"])} for a in bruto["anotacoes"]
        ],
    }
    return {
        "redacao_id": redacao_id,
        "status": "analisada",
        "texto_extraido": texto,
        "analise": analise,
        "palavras_novas": [],  # ver pendência §7.3 passo 4 no docstring do módulo
    }
