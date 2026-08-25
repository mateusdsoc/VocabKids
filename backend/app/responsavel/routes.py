"""Rotas do domínio responsável (Fase 5, `docs/plano_b2c.md` §08).

Tudo aqui exige papel `responsavel` — a criança nunca alcança estas rotas
(nem por engano: o token dela é escopo `aluno`, `require_papel` rejeita).
"""
from typing import Annotated

from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncConnection

from app.api.deps import get_conn
from app.errors import ApiError
from app.identidade import repository as identidade_repo
from app.identidade.auth import UsuarioAutenticado, require_papel
from app.responsavel import service
from app.responsavel.schemas import PinIn, PinStatusOut, ResumoSemanalOut

router = APIRouter(tags=["responsavel"])


async def _conta_id(conn: AsyncConnection, usuario: UsuarioAutenticado) -> int:
    conta = await identidade_repo.buscar_conta_por_responsavel(conn, usuario.id)
    if conta is None:
        raise ApiError(404, "conta_nao_encontrada", "Conta não encontrada.")
    return conta.id


@router.get("/conta/pin", response_model=PinStatusOut, summary="Se o PIN da Área do Responsável já foi definido")
async def status_pin(
    usuario: Annotated[UsuarioAutenticado, Depends(require_papel("responsavel"))],
    conn: Annotated[AsyncConnection, Depends(get_conn)],
):
    return await service.pin_status(conn, await _conta_id(conn, usuario))


@router.post("/conta/pin", status_code=204, summary="Define ou troca o PIN de 4 dígitos (R-RS-1)")
async def definir_pin(
    corpo: PinIn,
    usuario: Annotated[UsuarioAutenticado, Depends(require_papel("responsavel"))],
    conn: Annotated[AsyncConnection, Depends(get_conn)],
):
    await service.definir_pin(conn, await _conta_id(conn, usuario), corpo.pin)


@router.post(
    "/conta/pin/verificar",
    status_code=204,
    summary="Confere o PIN antes do app liberar a Área do Responsável (R-RS-1)",
)
async def verificar_pin(
    corpo: PinIn,
    usuario: Annotated[UsuarioAutenticado, Depends(require_papel("responsavel"))],
    conn: Annotated[AsyncConnection, Depends(get_conn)],
):
    await service.verificar_pin(conn, await _conta_id(conn, usuario), corpo.pin)


@router.get(
    "/responsavel/perfis/{perfil_usuario_id}/resumo",
    response_model=ResumoSemanalOut,
    summary="Resumo semanal do perfil pro responsável (§08 item 1-3)",
)
async def resumo_semanal(
    perfil_usuario_id: int,
    usuario: Annotated[UsuarioAutenticado, Depends(require_papel("responsavel"))],
    conn: Annotated[AsyncConnection, Depends(get_conn)],
):
    return await service.resumo_semanal(
        conn, conta_id=await _conta_id(conn, usuario), perfil_usuario_id=perfil_usuario_id
    )
