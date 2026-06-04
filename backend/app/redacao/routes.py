"""Redação e dashboard — telas MOCKADAS/estáticas na fatia A.

No apresentável estas telas existem para a demo, mas devolvem dados fixos: o
pipeline real de redação (OCR→análise→extração→atribuição) e o dashboard com
dados de verdade são da fatia C (Bloco 2b). Mesmas rotas, sem reescrita depois.
"""
from typing import Annotated

from fastapi import APIRouter, Depends
from pydantic import BaseModel

from app.identidade.auth import get_usuario_atual

router = APIRouter(tags=["redacao"], dependencies=[Depends(get_usuario_atual)])


class RedacaoMock(BaseModel):
    id: int
    tema: str
    prazo: str | None
    status: str


class RedacoesOut(BaseModel):
    mock: bool
    itens: list[RedacaoMock]


class DashboardOut(BaseModel):
    mock: bool
    turma: str
    palavras_dominadas_turma: int
    meta_semanal: int
    alunos_ativos: int
    top3_palavras_dificeis: list[str]


# Dados fixos só para a demo (fatia A).
_REDACOES = [
    {"id": 1, "tema": "Minhas férias dos sonhos", "prazo": "2026-06-20", "status": "pendente"},
    {"id": 2, "tema": "Um herói brasileiro", "prazo": "2026-06-10", "status": "analisada"},
    {"id": 3, "tema": "Se eu pudesse mudar o mundo", "prazo": None, "status": "rascunho"},
]

_DASHBOARD = {
    "mock": True,
    "turma": "7º Ano A",
    "palavras_dominadas_turma": 184,
    "meta_semanal": 5,
    "alunos_ativos": 23,
    "top3_palavras_dificeis": ["efêmero", "perspicaz", "meticuloso"],
}


@router.get(
    "/redacoes",
    response_model=RedacoesOut,
    summary="Lista de redações (MOCK estático na fatia A)",
)
async def listar_redacoes():
    return {"mock": True, "itens": _REDACOES}


@router.get(
    "/dashboard",
    response_model=DashboardOut,
    summary="Dashboard da turma (MOCK estático na fatia A)",
)
async def dashboard():
    return _DASHBOARD
