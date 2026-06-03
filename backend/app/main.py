"""App FastAPI — ponto de entrada.

No apresentável (fatia A) o backend é síncrono (sem OCR/LLM em runtime). As rotas de
domínio (identidade, sessão, trilha…) entram aqui à medida que forem implementadas.
"""
from fastapi import FastAPI
from sqlalchemy import text

from app.db import engine

app = FastAPI(title="VocabBR Kids API", version="0.1.0")


@app.get("/health")
async def health():
    """Liveness + checagem de conexão com o banco."""
    async with engine.connect() as conn:
        await conn.execute(text("SELECT 1"))
    return {"status": "ok"}
