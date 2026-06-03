"""Repositório do diagnóstico (SQLAlchemy Core).

Lê questões de reconhecimento (N1) por nível e grava o nível final. NÃO escreve
em `aluno_questao` — as respostas do diagnóstico não são aprendizado e não devem
entrar no sinal da adaptação.
"""
from sqlalchemy import func, select, update
from sqlalchemy.engine import Row
from sqlalchemy.ext.asyncio import AsyncConnection

from app import schema


async def ler_ano_escolar(conn: AsyncConnection, usuario_id: int) -> int | None:
    u, a = schema.usuario, schema.associacao
    at, t = schema.associacao_turma, schema.turma
    stmt = (
        select(t.c.ano_escolar)
        .select_from(
            u.join(a, a.c.usuario_id == u.c.id)
            .join(at, at.c.associacao_id == a.c.id)
            .join(t, t.c.id == at.c.turma_id)
        )
        .where(u.c.id == usuario_id, a.c.papel == "aluno")
        .limit(1)
    )
    return (await conn.execute(stmt)).scalar_one_or_none()


async def buscar_questao_n1(
    conn: AsyncConnection, nivel: int, usadas: list[int]
) -> Row | None:
    """Questão N1 (reconhecimento) de uma palavra mais próxima do nível-alvo,
    ainda não usada nesta rodada (testa a dificuldade do conteúdo)."""
    q, p = schema.questao, schema.palavra
    distancia = func.abs(p.c.nivel_dificuldade - nivel)
    stmt = (
        select(q.c.id, q.c.enunciado, q.c.opcoes)
        .select_from(q.join(p, p.c.id == q.c.palavra_id))
        .where(q.c.nivel == 1, q.c.status == "ativa")
    )
    if usadas:
        stmt = stmt.where(q.c.id.notin_(usadas))
    stmt = stmt.order_by(distancia, q.c.id).limit(1)
    return (await conn.execute(stmt)).first()


async def ler_resposta(conn: AsyncConnection, questao_id: int) -> str | None:
    q = schema.questao
    return (
        await conn.execute(
            select(q.c.resposta_correta).where(q.c.id == questao_id)
        )
    ).scalar_one_or_none()


async def definir_nivel(conn: AsyncConnection, usuario_id: int, nivel: int) -> None:
    p = schema.aluno_progresso
    await conn.execute(
        update(p)
        .where(p.c.usuario_id == usuario_id)
        .values(nivel_dificuldade_atual=nivel)
    )
