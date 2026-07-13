"""Lógica de domínio do identidade — sem SQL cru nem detalhe de HTTP."""
from sqlalchemy.ext.asyncio import AsyncConnection

from app.errors import ApiError
from app.identidade import repository as repo
from app.identidade.auth import criar_token
from app.progressao.meta import meta_efetiva
from app.progressao.semana import inicio_da_semana


async def acessar_por_codigo_turma(
    conn: AsyncConnection, codigo_turma: str, nome: str
) -> dict:
    """Acesso provisório da fatia A: entra por código de turma.

    Encontra a turma pelo código; acha-ou-cria o aluno (por nome) e devolve a
    sessão (JWT assinado com expiração — ver `auth.py`).
    """
    nome = nome.strip()
    turma = await repo.buscar_turma_por_codigo(conn, codigo_turma.strip())
    if turma is None:
        raise ApiError(
            404,
            "turma_nao_encontrada",
            "Código de turma inválido ou inexistente.",
            {"codigo_turma": codigo_turma},
        )

    aluno = await repo.buscar_aluno_na_turma(conn, turma.id, nome)
    novo = aluno is None
    if novo:
        usuario_id = await repo.criar_aluno(conn, turma.escola_id, turma.id, nome)
        nome_final = nome
    else:
        usuario_id = aluno.id
        nome_final = aluno.nome

    return {
        "token": criar_token(usuario_id, "aluno"),
        "usuario_id": usuario_id,
        "nome": nome_final,
        "turma": {"id": turma.id, "nome": turma.nome, "ano_escolar": turma.ano_escolar},
        "novo": novo,
    }


async def perfil(conn: AsyncConnection, usuario_id: int) -> dict:
    """Perfil + progresso do aluno (`GET /v1/me`)."""
    p = await repo.buscar_perfil(conn, usuario_id)
    if p is None:
        raise ApiError(404, "usuario_nao_encontrado", "Usuário não encontrado.")

    prog = await repo.buscar_progresso(conn, usuario_id)
    progresso = {
        "xp_total": prog.xp_total if prog else 0,
        "no_atual_id": prog.no_atual_id if prog else None,
        "palavras_dominadas": prog.palavras_dominadas if prog else 0,
        "nivel_dificuldade_atual": prog.nivel_dificuldade_atual if prog else 1,
    }

    # Meta da semana (§3.5): mesmo corte (segunda-feira) e mesmo default por
    # ano que o painel do professor — aluno e professor leem o mesmo número.
    meta_semanal = None
    if p.turma_id:
        config = await repo.meta_config_da_turma(conn, p.turma_id)
        atual = await repo.dominadas_na_semana(conn, usuario_id, inicio_da_semana())
        meta_semanal = {"atual": atual, "alvo": meta_efetiva(config, p.ano_escolar)}

    return {
        "usuario_id": p.usuario_id,
        "nome": p.nome,
        "papel": p.papel,
        "escola": {"id": p.escola_id, "nome": p.escola_nome} if p.escola_id else None,
        "turma": (
            {"id": p.turma_id, "nome": p.turma_nome, "ano_escolar": p.ano_escolar}
            if p.turma_id
            else None
        ),
        "progresso": progresso,
        "meta_semanal": meta_semanal,
    }
