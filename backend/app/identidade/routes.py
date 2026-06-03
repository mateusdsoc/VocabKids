"""Rotas do domínio identidade (montadas sob `/v1` pelo agregador da API)."""
from typing import Annotated

from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncConnection

from app.api.deps import get_conn
from app.identidade import service
from app.identidade.auth import UsuarioAutenticado, get_usuario_atual
from app.identidade.schemas import AcessoTurmaIn, AcessoTurmaOut, MeOut

router = APIRouter(tags=["identidade"])


@router.post(
    "/acesso/turma",
    response_model=AcessoTurmaOut,
    summary="Entrar por código de turma (acesso provisório da fatia A)",
)
async def acesso_turma(
    body: AcessoTurmaIn, conn: Annotated[AsyncConnection, Depends(get_conn)]
):
    return await service.acessar_por_codigo_turma(conn, body.codigo_turma, body.nome)


@router.get(
    "/me",
    response_model=MeOut,
    summary="Perfil do usuário autenticado + progresso",
)
async def me(
    usuario: Annotated[UsuarioAutenticado, Depends(get_usuario_atual)],
    conn: Annotated[AsyncConnection, Depends(get_conn)],
):
    return await service.perfil(conn, usuario.id)
