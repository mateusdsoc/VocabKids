"""Orquestração da assinatura — webhook do RevenueCat e status para a conta.

RevenueCat fica entre nós e a Apple/Google: resolve StoreKit, valida o recibo,
lida com o calendário de billing retry e nos manda um webhook normalizado
(mesmo formato para as duas lojas). O backend nunca fala com a App Store
Server API diretamente — ver `docs/plano_b2c.md` §12 (por que RevenueCat em
vez de reimplementar validação de JWS na mão).
"""
from datetime import datetime, timezone

from sqlalchemy.ext.asyncio import AsyncConnection

from app.assinatura import repository as repo
from app.errors import ApiError

# Tipos de evento do RevenueCat que concedem acesso (assinatura ativa).
_EVENTOS_ATIVA = {
    "INITIAL_PURCHASE",
    "RENEWAL",
    "UNCANCELLATION",
    "PRODUCT_CHANGE",
    "NON_RENEWING_PURCHASE",
    "TRANSFER",
    "SUBSCRIPTION_EXTENDED",
}
# CANCELLATION desliga a renovação automática, mas o acesso continua até
# `expira_em` — só a EXPIRATION de fato (evento futuro) marca como expirada.
# Eventos internos do RevenueCat sem efeito no nosso status.
_EVENTOS_SEM_MUDANCA_DE_STATUS = {"CANCELLATION", "TEST", "SUBSCRIBER_ALIAS"}


def status_de(tipo_evento: str) -> str | None:
    """Mapeia o `event.type` do RevenueCat para o nosso status — regra pura.
    `None` = evento não muda o status atual (só atualiza os demais campos)."""
    if tipo_evento in _EVENTOS_ATIVA:
        return "ativa"
    if tipo_evento == "BILLING_ISSUE":
        return "em_periodo_de_graca"
    if tipo_evento == "EXPIRATION":
        return "expirada"
    if tipo_evento == "REFUND":  # R-AS-7
        return "reembolsada"
    return None  # inclui _EVENTOS_SEM_MUDANCA_DE_STATUS e tipos desconhecidos


def _conta_id_do_app_user_id(app_user_id: str | None) -> int | None:
    """No app, `Purchases.configure` usa `str(conta_id)` como `app_user_id`
    (convenção documentada em `docs/plano_b2c.md` — sem tabela de mapeamento
    à parte). Um app_user_id que não é esse número é ignorado (melhor-esforço:
    ex. anônimo do RevenueCat antes do login)."""
    if app_user_id and app_user_id.isdigit():
        return int(app_user_id)
    return None


async def aplicar_evento(conn: AsyncConnection, payload: dict) -> None:
    evento = payload.get("event") or {}
    event_id = evento.get("id")
    if not event_id:
        raise ApiError(422, "evento_invalido", "Webhook sem id de evento.")

    novo = await repo.inserir_evento_loja(
        conn,
        loja="apple" if evento.get("store") == "APP_STORE" else "google",
        tipo=str(evento.get("type", "")),
        payload=payload,
        dedup=event_id,
    )
    if not novo:
        return  # R-AS-6: reentrega do mesmo evento é no-op

    conta_id = _conta_id_do_app_user_id(evento.get("app_user_id"))
    if conta_id is not None:
        expira_ms = evento.get("expiration_at_ms")
        expira_em = (
            datetime.fromtimestamp(expira_ms / 1000, tz=timezone.utc)
            if expira_ms is not None
            else None
        )
        await repo.upsert_assinatura(
            conn,
            conta_id=conta_id,
            loja="apple" if evento.get("store") == "APP_STORE" else "google",
            produto_id=str(evento.get("product_id", "")),
            transacao_original_id=str(
                evento.get("original_transaction_id") or event_id
            ),
            status=status_de(str(evento.get("type", ""))),
            expira_em=expira_em,
            em_trial=bool(evento.get("is_trial_period", False)),
            ambiente="production" if evento.get("environment") == "PRODUCTION" else "sandbox",
        )

    await repo.marcar_evento_processado(conn, event_id)


async def status_da_conta(conn: AsyncConnection, conta_id: int) -> dict:
    assinatura = await repo.assinatura_mais_recente_da_conta(conn, conta_id)
    assinante = assinatura is not None and assinatura.status in repo.STATUS_COM_ACESSO
    return {
        "assinante": assinante,
        "status": assinatura.status if assinatura else None,
        "expira_em": assinatura.expira_em if assinatura else None,
        "em_trial": bool(assinatura.em_trial) if assinatura else False,
        "em_free_tier": False,  # status da CONTA não sabe de perfil — quem pede sabe o dele
    }
