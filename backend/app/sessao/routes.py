"""Rotas do domínio sessão (Bloco 2a). Atrás da sessão do aluno (auth)."""
from typing import Annotated

from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncConnection

from app.api.deps import get_conn
from app.identidade.auth import UsuarioAutenticado, get_usuario_atual
from app.sessao import service
from app.sessao.schemas import SessaoOut

router = APIRouter(tags=["sessao"])


@router.post(
    "/sessoes",
    response_model=SessaoOut,
    status_code=201,
    summary="Monta e abre uma sessão (fila de slots, entrega em lote)",
)
async def abrir_sessao(
    usuario: Annotated[UsuarioAutenticado, Depends(get_usuario_atual)],
    conn: Annotated[AsyncConnection, Depends(get_conn)],
):
    return await service.montar_sessao(conn, usuario.id)
