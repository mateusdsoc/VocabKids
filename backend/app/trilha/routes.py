"""Rotas da trilha e do passaporte (leitura). Atrás da sessão do aluno."""
from typing import Annotated

from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncConnection

from app.api.deps import get_conn
from app.identidade.auth import UsuarioAutenticado, get_usuario_atual
from app.sessao import repository as sessao_repo
from app.trilha import service
from app.trilha.schemas import PassaporteOut, TrilhaOut

router = APIRouter(tags=["trilha"])


@router.get("/trilha", response_model=TrilhaOut, summary="Mapa: nó atual, destinos, 'você está aqui'")
async def trilha(
    usuario: Annotated[UsuarioAutenticado, Depends(get_usuario_atual)],
    conn: Annotated[AsyncConnection, Depends(get_conn)],
):
    progresso = await sessao_repo.ler_pontuacao(conn, usuario.id)
    xp_total = progresso.xp_total if progresso else 0
    return await service.mapa(conn, xp_total)


@router.get("/passaporte", response_model=PassaporteOut, summary="Coleção (até 28); silhueta para o que falta")
async def passaporte(
    usuario: Annotated[UsuarioAutenticado, Depends(get_usuario_atual)],
    conn: Annotated[AsyncConnection, Depends(get_conn)],
):
    return await service.passaporte(conn, usuario.id)
