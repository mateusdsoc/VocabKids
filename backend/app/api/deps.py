"""Dependências compartilhadas da camada de API.

Acesso a dados com SQLAlchemy Core (decisão #2 do Bloco 3): queries explícitas,
sem ORM pesado. A conexão é transacional por request — commita no fim, faz
rollback em exceção.
"""
from collections.abc import AsyncIterator

from sqlalchemy.ext.asyncio import AsyncConnection

from app.db import engine


async def get_conn() -> AsyncIterator[AsyncConnection]:
    """Conexão transacional por request.

    FastAPI cacheia a dependência dentro do request, então rotas e sub-deps
    (ex.: a resolução de identidade) compartilham a mesma conexão/transação.
    """
    async with engine.begin() as conn:
        yield conn
