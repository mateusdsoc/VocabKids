"""Rotas do domínio assinatura (B2C, docs/plano_b2c.md Fase 3)."""
from typing import Annotated

from fastapi import APIRouter, Depends, Header
from sqlalchemy.ext.asyncio import AsyncConnection

from app.api.deps import get_conn
from app.assinatura import service
from app.assinatura.schemas import AssinaturaStatusOut
from app.config import settings
from app.errors import ApiError
from app.identidade import repository as identidade_repo
from app.identidade.auth import UsuarioAutenticado, require_papel

router = APIRouter(tags=["assinatura"])


def _validar_segredo_webhook(authorization: str | None) -> None:
    """Autentica o webhook por segredo compartilhado (header Authorization,
    configurado também no painel do RevenueCat) — não é auth de usuário, é
    service-to-service. Sem segredo configurado, rejeita sempre (nunca aceita
    "por engano" com o default vazio)."""
    esperado = settings.revenuecat_webhook_secret
    recebido = (authorization or "").removeprefix("Bearer ").strip()
    if not esperado or recebido != esperado:
        raise ApiError(401, "webhook_nao_autorizado", "Segredo do webhook inválido.")


@router.post(
    "/assinatura/webhook",
    status_code=204,
    summary="Webhook do RevenueCat (compras, renovação, cancelamento, reembolso)",
)
async def webhook(
    payload: dict,
    conn: Annotated[AsyncConnection, Depends(get_conn)],
    authorization: Annotated[str | None, Header()] = None,
):
    _validar_segredo_webhook(authorization)
    await service.aplicar_evento(conn, payload)


@router.get(
    "/assinatura",
    response_model=AssinaturaStatusOut,
    summary="Status da assinatura da conta do responsável",
)
async def status(
    usuario: Annotated[UsuarioAutenticado, Depends(require_papel("responsavel"))],
    conn: Annotated[AsyncConnection, Depends(get_conn)],
):
    conta = await identidade_repo.buscar_conta_por_responsavel(conn, usuario.id)
    if conta is None:
        raise ApiError(404, "conta_nao_encontrada", "Conta não encontrada.")
    return await service.status_da_conta(conn, conta.id)
