"""Rota do diagnóstico inicial (onboarding). Atrás da sessão do aluno."""
from typing import Annotated

from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncConnection

from app.api.deps import get_conn
from app.diagnostico import service
from app.diagnostico.schemas import DiagnosticoIn, DiagnosticoOut
from app.identidade.auth import UsuarioAutenticado, get_usuario_atual

router = APIRouter(tags=["diagnostico"])


@router.post(
    "/onboarding/diagnostico",
    response_model=DiagnosticoOut,
    summary="Roda/avança o diagnóstico inicial → nivel_dificuldade_atual",
)
async def diagnostico(
    body: DiagnosticoIn,
    usuario: Annotated[UsuarioAutenticado, Depends(get_usuario_atual)],
    conn: Annotated[AsyncConnection, Depends(get_conn)],
):
    return await service.passo(conn, usuario.id, body)
