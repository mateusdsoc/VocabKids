"""Report de questão — MOCK na fatia A.

A tela do aluno (botão "reportar") é real, mas no apresentável o backend só
confirma o recebimento: NÃO persiste `report_questao`, nem roda auto-ocultar /
anti-abuso. Esse pipeline de QA entra na fatia C (Bloco 2b), sem mexer nas rotas
— a decisão "schema único" já previu a tabela.
"""
from typing import Annotated, Literal

from fastapi import APIRouter, Depends
from pydantic import BaseModel

from app.identidade.auth import get_usuario_atual

router = APIRouter(tags=["report"], dependencies=[Depends(get_usuario_atual)])

# Motivos predefinidos (seção 3.6) — o aluno escolhe de uma caixa de opções.
Motivo = Literal["resposta_errada", "nao_entendi", "ofensivo", "outro"]


class ReportIn(BaseModel):
    motivo: Motivo


class ReportOut(BaseModel):
    recebido: bool
    questao_id: int


@router.post(
    "/questoes/{questao_id}/report",
    response_model=ReportOut,
    summary="Reportar uma questão (MOCK na fatia A; QA real é fatia C)",
)
async def reportar(questao_id: int, body: ReportIn):
    # MOCK: agradece e segue. Ver docstring do módulo.
    return {"recebido": True, "questao_id": questao_id}
