"""App FastAPI — ponto de entrada.

No apresentável (fatia A) o backend é síncrono (sem OCR/LLM em runtime). As rotas de
domínio (identidade, sessão, trilha…) entram aqui à medida que forem implementadas.
"""
from fastapi import FastAPI
from sqlalchemy import text
from starlette.requests import Request

from app.api.v1 import api_router
from app.db import engine
from app.errors import register_error_handlers

app = FastAPI(title="VocabBR Kids API", version="0.1.0")
register_error_handlers(app)
app.include_router(api_router)


@app.middleware("http")
async def db_transacao(request: Request, call_next):
    """Transação por request, commitada ANTES de a resposta sair.

    Centraliza o ciclo de vida da conexão (lida pelos handlers via `get_conn`):
    commit no sucesso (status < 400), rollback em erro. Evita a corrida do
    teardown de dependência `yield`, que comita depois da resposta.
    """
    async with engine.connect() as conn:
        # request.state é lastreado no `scope` (Starlette), então a conexão é
        # visível ao handler via get_conn mesmo cruzando o BaseHTTPMiddleware.
        request.state.conn = conn
        transacao = await conn.begin()
        try:
            response = await call_next(request)
        except Exception:
            await transacao.rollback()
            raise
        if response.status_code < 400:
            await transacao.commit()
        else:
            await transacao.rollback()
        return response


@app.get("/health")
async def health(request: Request):
    """Liveness + checagem de conexão com o banco."""
    await request.state.conn.execute(text("SELECT 1"))
    return {"status": "ok"}
