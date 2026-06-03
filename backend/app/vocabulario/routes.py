"""Rotas do domínio vocabulário (banco global; leitura no apresentável).

Todas atrás da sessão do aluno (auth provisória da fatia A) via dependency de
router. O banco global não é escopado por escola (arquitetura), mas o tráfego do
app nasce de uma sessão autenticada.
"""
from typing import Annotated

from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncConnection

from app.api.deps import get_conn
from app.identidade.auth import get_usuario_atual
from app.vocabulario import service
from app.vocabulario.schemas import PalavraListaOut, PalavraOut

router = APIRouter(tags=["vocabulario"], dependencies=[Depends(get_usuario_atual)])


@router.get("/palavras", response_model=PalavraListaOut, summary="Lista paginada do banco de palavras")
async def listar_palavras(
    conn: Annotated[AsyncConnection, Depends(get_conn)],
    cursor: str | None = None,
    limit: Annotated[int, Query(ge=1, le=100)] = 20,
):
    return await service.listar(conn, cursor, limit)


@router.get("/palavras/{palavra_id}", response_model=PalavraOut, summary="Conteúdo do card de uma palavra")
async def obter_palavra(
    palavra_id: int, conn: Annotated[AsyncConnection, Depends(get_conn)]
):
    return await service.detalhe(conn, palavra_id)
