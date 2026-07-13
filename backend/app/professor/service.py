"""Lógica do domínio professor — fatia C: dados reais + escopo (§3.11).

Escopo por associação: professor enxerga (e configura) **só as turmas de
`associacao_turma`**; coordenador enxerga a escola inteira, só leitura. As
rotas já garantem o papel (`require_papel`); aqui garantimos o alcance.

Semana e meta usam as regras puras de `progressao/` — aluno (Home) e professor
(painel) leem o mesmo corte de segunda-feira e o mesmo default por ano.
"""
from datetime import date, datetime

from sqlalchemy.ext.asyncio import AsyncConnection

from app.errors import ApiError
from app.identidade.auth import UsuarioAutenticado
from app.professor import repository as repo
from app.progressao.meta import meta_efetiva
from app.progressao.semana import inicio_da_semana

def _fora_do_escopo() -> ApiError:
    return ApiError(403, "sem_permissao", "Fora do seu escopo de turmas/escola.")


async def _contexto(conn: AsyncConnection, usuario: UsuarioAutenticado):
    ctx = await repo.associacao_na_escola(conn, usuario.id)
    if ctx is None:
        raise ApiError(403, "sem_permissao", "Usuário sem vínculo com escola.")
    return ctx


async def _turmas_visiveis(conn: AsyncConnection, usuario_id: int, ctx) -> list[int]:
    if ctx.papel == "professor":
        return await repo.turma_ids_do_professor(conn, usuario_id)
    return await repo.turma_ids_da_escola(conn, ctx.escola_id)


def _status_para_professor(status_envio: str | None) -> str:
    """Traduz o status interno do pipeline para a linguagem do professor.

    Sem envio → pendente; analisada → analisada; o resto (enviada,
    processando, erro_*) → em_analise — erro de OCR/análise é problema
    interno de reprocesso, não um estado que o professor resolva.
    """
    if status_envio is None:
        return "pendente"
    if status_envio == "analisada":
        return "analisada"
    return "em_analise"


def _data_iso(dt: datetime | None) -> str | None:
    return dt.date().isoformat() if dt else None


async def _linhas_de_turmas(conn: AsyncConnection, turma_ids: list[int]) -> list[dict]:
    """Linhas agregadas por turma (painel da escola / lista de turmas)."""
    if not turma_ids:
        return []
    inicio = inicio_da_semana()
    turmas = await repo.turmas_por_ids(conn, turma_ids)
    totais = await repo.alunos_total_por_turma(conn, turma_ids)
    ativos = await repo.ativos_na_semana_por_turma(conn, turma_ids, inicio)
    dominadas = await repo.dominadas_na_semana_por_turma(conn, turma_ids, inicio)
    return [
        {
            "id": t.id,
            "nome": t.nome,
            "ano_escolar": t.ano_escolar,
            "alunos_total": totais.get(t.id, 0),
            "alunos_ativos": ativos.get(t.id, 0),
            "palavras_dominadas_semana": dominadas.get(t.id, 0),
            "meta_semanal": meta_efetiva(t.meta_config, t.ano_escolar),
        }
        for t in turmas
    ]


async def listar_turmas(conn: AsyncConnection, usuario: UsuarioAutenticado) -> dict:
    ctx = await _contexto(conn, usuario)
    linhas = await _linhas_de_turmas(
        conn, await _turmas_visiveis(conn, usuario.id, ctx)
    )
    return {"mock": False, "turmas": linhas}


async def painel_turma(
    conn: AsyncConnection, usuario: UsuarioAutenticado, turma_id: int
) -> dict:
    ctx = await _contexto(conn, usuario)
    turmas = await repo.turmas_por_ids(conn, [turma_id])
    if not turmas:
        raise ApiError(404, "turma_nao_encontrada", "Turma não encontrada.")
    turma = turmas[0]
    if turma_id not in await _turmas_visiveis(conn, usuario.id, ctx):
        raise _fora_do_escopo()

    inicio = inicio_da_semana()
    alunos = await repo.alunos_do_painel(conn, turma_id, inicio)
    ativos = await repo.ativos_na_semana_por_turma(conn, [turma_id], inicio)
    meta = meta_efetiva(turma.meta_config, turma.ano_escolar)
    return {
        "mock": False,
        "turma_id": turma.id,
        "turma_nome": turma.nome,
        "ano_escolar": turma.ano_escolar,
        "alunos_total": len(alunos),
        "alunos_ativos": ativos.get(turma_id, 0),
        # Soma das linhas — mesma fonte que a lista, sem query extra.
        "palavras_dominadas_semana": sum(a.dominadas_semana for a in alunos),
        "meta_semanal": meta,
        "sinal_turma": await repo.sinal_das_turmas(conn, [turma_id]),
        "alunos": [
            {
                "id": a.id,
                "nome": a.nome,
                "palavras_semana": a.dominadas_semana,
                "meta_semana": meta,
                "palavras_dominadas": a.dominadas_total,
            }
            for a in alunos
        ],
    }


async def painel_escola(conn: AsyncConnection, usuario: UsuarioAutenticado) -> dict:
    ctx = await _contexto(conn, usuario)
    turma_ids = await repo.turma_ids_da_escola(conn, ctx.escola_id)
    linhas = await _linhas_de_turmas(conn, turma_ids)
    return {
        "mock": False,
        "escola_nome": ctx.escola_nome,
        "turmas_total": len(linhas),
        "alunos_ativos": sum(l["alunos_ativos"] for l in linhas),
        "alunos_total": sum(l["alunos_total"] for l in linhas),
        "palavras_dominadas_semana": sum(
            l["palavras_dominadas_semana"] for l in linhas
        ),
        "sinal_escola": await repo.sinal_das_turmas(conn, turma_ids),
        "turmas": linhas,
    }


async def detalhe_aluno(
    conn: AsyncConnection, usuario: UsuarioAutenticado, aluno_id: int
) -> dict:
    ctx = await _contexto(conn, usuario)
    aluno = await repo.aluno_com_turma(conn, aluno_id)
    if aluno is None:
        raise ApiError(404, "aluno_nao_encontrado", "Aluno não encontrado.")
    if ctx.papel == "professor":
        if aluno.turma_id not in await repo.turma_ids_do_professor(conn, usuario.id):
            raise _fora_do_escopo()
    elif aluno.escola_id != ctx.escola_id:
        raise _fora_do_escopo()

    inicio = inicio_da_semana()
    contadores = await repo.contadores_do_aluno(conn, aluno_id)
    turma = (await repo.turmas_por_ids(conn, [aluno.turma_id]))[0]
    return {
        "mock": False,
        "id": aluno.id,
        "nome": aluno.nome,
        "turma_id": aluno.turma_id,
        "turma_nome": aluno.turma_nome,
        "ano_escolar": aluno.ano_escolar,
        "palavras_semana": await repo.dominadas_na_semana(conn, aluno_id, inicio),
        "meta_semana": meta_efetiva(turma.meta_config, turma.ano_escolar),
        "palavras_dominadas": contadores.dominadas,
        "palavras_em_progresso": contadores.em_progresso,
        "palavras": [
            {"texto": p.texto, "estado": p.estado, "origem": p.origem}
            for p in await repo.palavras_notaveis(conn, aluno_id)
        ],
        "redacoes": [
            {
                "id": r.id,
                "tema": r.tema,
                "status": _status_para_professor(r.status),
                "enviada_em": _data_iso(r.enviada_em),
            }
            for r in await repo.redacoes_do_aluno(conn, aluno_id, aluno.turma_id)
        ],
    }


async def _turma_do_professor(
    conn: AsyncConnection, usuario: UsuarioAutenticado, turma_id: int
):
    """Guarda das ações de configuração: turma existe e é do professor."""
    ctx = await _contexto(conn, usuario)
    if not await repo.turmas_por_ids(conn, [turma_id]):
        raise ApiError(404, "turma_nao_encontrada", "Turma não encontrada.")
    if turma_id not in await repo.turma_ids_do_professor(conn, usuario.id):
        raise _fora_do_escopo()
    return ctx


async def atribuir_redacao(
    conn: AsyncConnection,
    usuario: UsuarioAutenticado,
    turma_id: int,
    tema: str,
    prazo: str | None,
) -> dict:
    ctx = await _turma_do_professor(conn, usuario, turma_id)
    atribuicao_id = await repo.criar_atribuicao(
        conn,
        turma_id,
        ctx.associacao_id,
        tema,
        date.fromisoformat(prazo) if prazo else None,
    )
    return {
        "mock": False,
        "id": atribuicao_id,
        "turma_id": turma_id,
        "tema": tema,
        "prazo": prazo,
    }


async def atualizar_meta(
    conn: AsyncConnection, usuario: UsuarioAutenticado, turma_id: int, meta: int
) -> dict:
    await _turma_do_professor(conn, usuario, turma_id)
    await repo.upsert_meta(conn, turma_id, meta)
    return {"mock": False, "turma_id": turma_id, "meta_semanal": meta}
