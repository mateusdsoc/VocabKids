"""Agregador da API v1. Cada domínio entra com uma linha à medida que nasce.

`/v1` no path (decisão #5 do Bloco 3); sobe de versão só em breaking change.
"""
from fastapi import APIRouter

from app.diagnostico.routes import router as diagnostico_router
from app.identidade.routes import router as identidade_router
from app.sessao.routes import router as sessao_router
from app.vocabulario.routes import router as vocabulario_router

api_router = APIRouter(prefix="/v1")
api_router.include_router(identidade_router)
api_router.include_router(vocabulario_router)
api_router.include_router(sessao_router)
api_router.include_router(diagnostico_router)
