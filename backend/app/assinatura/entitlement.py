"""Gate de acesso ao gameplay pago — regra pura + dependency FastAPI.

R-AS-1 (docs/plano_b2c.md): fonte da verdade do entitlement é o BACKEND,
nunca o app — o cliente nunca decide sozinho se pode abrir uma sessão nova.
R-AS-2: onboarding e diagnóstico são sempre grátis (não passam por aqui); só
`POST /v1/sessoes` (abrir sessão) é gateado — o 1º destino (4 nós) é free tier.
"""
from typing import Annotated

from fastapi import Depends
from sqlalchemy.ext.asyncio import AsyncConnection

from app.api.deps import get_conn
from app.assinatura import repository as repo
from app.errors import ApiError
from app.identidade.auth import UsuarioAutenticado, get_usuario_atual


def tem_acesso(
    *, tem_assinatura_ativa: bool, xp_total: int, limiar_gratis: int | None
) -> bool:
    """Regra pura: assinante da conta OU ainda dentro do free tier (1º destino).
    `limiar_gratis=None` (trilha não semeada) não trava ninguém — o gate de
    assinatura não é o lugar para acusar um ambiente mal configurado."""
    if tem_assinatura_ativa or limiar_gratis is None:
        return True
    return xp_total < limiar_gratis


async def _usuario_tem_acesso(conn: AsyncConnection, usuario_id: int) -> bool:
    conta_id = await repo.conta_do_perfil(conn, usuario_id)
    if conta_id is None:
        return True  # sem perfil_crianca (aluno B2B congelado) — sem paywall

    tem_assinatura_ativa = await repo.assinatura_ativa_da_conta(conn, conta_id) is not None
    xp_total = await repo.xp_total_do_aluno(conn, usuario_id)
    limiar_gratis = await repo.limiar_gratis_xp(conn)
    return tem_acesso(
        tem_assinatura_ativa=tem_assinatura_ativa,
        xp_total=xp_total,
        limiar_gratis=limiar_gratis,
    )


async def exigir_acesso(
    usuario: Annotated[UsuarioAutenticado, Depends(get_usuario_atual)],
    conn: Annotated[AsyncConnection, Depends(get_conn)],
) -> UsuarioAutenticado:
    """Dependency para rotas que só um assinante (ou o free tier) pode usar."""
    if not await _usuario_tem_acesso(conn, usuario.id):
        raise ApiError(
            402,
            "assinatura_necessaria",
            "Assine o VocabKids para continuar a viagem além do 1º destino.",
        )
    return usuario
