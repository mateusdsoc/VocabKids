"""Agregador da API v1. Cada domínio entra com uma linha à medida que nasce.

`/v1` no path (decisão #5 do Bloco 3); sobe de versão só em breaking change.
"""
from fastapi import APIRouter

from app.assinatura.routes import router as assinatura_router
from app.diagnostico.routes import router as diagnostico_router
from app.identidade.routes import router as identidade_router
from app.professor.routes import router as professor_router
from app.redacao.routes import router as redacao_router
from app.report.routes import router as report_router
from app.sessao.routes import router as sessao_router
from app.trilha.routes import router as trilha_router
from app.vocabulario.routes import router as vocabulario_router

api_router = APIRouter(prefix="/v1")
api_router.include_router(identidade_router)
api_router.include_router(assinatura_router)
api_router.include_router(vocabulario_router)
api_router.include_router(sessao_router)
api_router.include_router(diagnostico_router)
api_router.include_router(trilha_router)
api_router.include_router(redacao_router)  # real (Fase 4, docs/plano_b2c.md)
# Mockado — vira real na Fase 6/pós-B2C se a área do responsável precisar.
api_router.include_router(report_router)
# Congelado (B2B) — fora do caminho crítico do B2C, ver CLAUDE.md.
api_router.include_router(professor_router)
