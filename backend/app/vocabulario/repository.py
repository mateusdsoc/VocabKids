"""Repositório do domínio vocabulário — banco global (SQLAlchemy Core).

Leitura no apresentável (decisão do Bloco 3). Expõe o conteúdo do card (palavra +
sinônimos); as **questões/respostas não saem por aqui** — são servidas pela
sessão, server-side, sem vazar a resposta correta.
"""
from sqlalchemy import select
from sqlalchemy.engine import Row
from sqlalchemy.ext.asyncio import AsyncConnection

from app import schema


async def listar_palavras(
    conn: AsyncConnection, depois_de: int | None, limite: int
) -> list[Row]:
    """Página de palavras ordenada por id (cursor estável). Pede `limite` linhas."""
    stmt = select(
        schema.palavra.c.id,
        schema.palavra.c.lema,
        schema.palavra.c.nivel_dificuldade,
    ).order_by(schema.palavra.c.id)
    if depois_de is not None:
        stmt = stmt.where(schema.palavra.c.id > depois_de)
    stmt = stmt.limit(limite)
    return list((await conn.execute(stmt)).all())


async def buscar_palavra(conn: AsyncConnection, palavra_id: int) -> Row | None:
    stmt = select(
        schema.palavra.c.id,
        schema.palavra.c.lema,
        schema.palavra.c.definicao,
        schema.palavra.c.exemplo_uso,
        schema.palavra.c.nivel_dificuldade,
        schema.palavra.c.audio_url,
    ).where(schema.palavra.c.id == palavra_id)
    return (await conn.execute(stmt)).first()


async def listar_sinonimos(conn: AsyncConnection, palavra_id: int) -> list[str]:
    stmt = (
        select(schema.palavra_sinonimo.c.texto)
        .where(schema.palavra_sinonimo.c.palavra_id == palavra_id)
        .order_by(schema.palavra_sinonimo.c.id)
    )
    return list((await conn.execute(stmt)).scalars().all())
