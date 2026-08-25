"""Assinatura: webhook do RevenueCat, status da conta e o gate do free tier
(docs/plano_b2c.md Fase 3)."""
import uuid

import pytest
from sqlalchemy import select, update

from app import schema
from app.db import engine
from app.seed_trilha import seed_trilha
from app.seed_vocabulario import seed_vocabulario

SEGREDO = "segredo-webhook-de-teste"  # espelha REVENUECAT_WEBHOOK_SECRET no conftest


def _evento(*, tipo, app_user_id, expira_em_ms=None, trial=False, event_id=None):
    return {
        "api_version": "1.0",
        "event": {
            "id": event_id or str(uuid.uuid4()),
            "type": tipo,
            "app_user_id": str(app_user_id),
            "product_id": "vocabkids_mensal",
            "store": "APP_STORE",
            "environment": "SANDBOX",
            "original_transaction_id": f"txn-{app_user_id}",
            "expiration_at_ms": expira_em_ms,
            "is_trial_period": trial,
        },
    }


async def _conta_id(client, responsavel_headers) -> int:
    conta = (await client.get("/v1/conta", headers=responsavel_headers)).json()
    return conta["conta_id"]


async def _set_xp(usuario_id, xp_total):
    async with engine.begin() as conn:
        await conn.execute(
            update(schema.aluno_progresso)
            .where(schema.aluno_progresso.c.usuario_id == usuario_id)
            .values(xp_total=xp_total)
        )


@pytest.mark.asyncio
async def test_webhook_exige_segredo_correto(client):
    body = _evento(tipo="INITIAL_PURCHASE", app_user_id=1)
    sem_header = await client.post("/v1/assinatura/webhook", json=body)
    assert sem_header.status_code == 401

    errado = await client.post(
        "/v1/assinatura/webhook",
        json=body,
        headers={"Authorization": "Bearer segredo-errado"},
    )
    assert errado.status_code == 401


@pytest.mark.asyncio
async def test_webhook_ativa_assinatura_da_conta(client, responsavel):
    conta_id = await _conta_id(client, responsavel["headers"])
    body = _evento(tipo="INITIAL_PURCHASE", app_user_id=conta_id, expira_em_ms=9_999_999_999_999)

    r = await client.post(
        "/v1/assinatura/webhook", json=body, headers={"Authorization": f"Bearer {SEGREDO}"}
    )
    assert r.status_code == 204

    status = (await client.get("/v1/assinatura", headers=responsavel["headers"])).json()
    assert status["assinante"] is True
    assert status["status"] == "ativa"


@pytest.mark.asyncio
async def test_webhook_idempotente_por_evento(client, responsavel):
    """R-AS-6: reentregar o mesmo evento (mesmo `id`) não duplica processamento."""
    conta_id = await _conta_id(client, responsavel["headers"])
    body = _evento(tipo="INITIAL_PURCHASE", app_user_id=conta_id, event_id="evento-fixo-123")

    for _ in range(2):
        r = await client.post(
            "/v1/assinatura/webhook", json=body, headers={"Authorization": f"Bearer {SEGREDO}"}
        )
        assert r.status_code == 204

    async with engine.begin() as conn:
        n = (
            await conn.execute(
                select(schema.evento_loja).where(
                    schema.evento_loja.c.assinatura_dedup == "evento-fixo-123"
                )
            )
        ).all()
    assert len(n) == 1


@pytest.mark.asyncio
async def test_status_sem_assinatura(client, responsavel):
    status = (await client.get("/v1/assinatura", headers=responsavel["headers"])).json()
    assert status == {
        "assinante": False,
        "status": None,
        "expira_em": None,
        "em_trial": False,
        "em_free_tier": False,
    }


@pytest.mark.asyncio
async def test_gate_bloqueia_sessao_alem_do_free_tier_sem_assinatura(client, aluno):
    await seed_trilha()
    await seed_vocabulario()
    await _set_xp(aluno["usuario_id"], 50_000)  # bem além do 1º destino (18000)

    r = await client.post("/v1/sessoes", headers=aluno["headers"])
    assert r.status_code == 402
    assert r.json()["error"]["code"] == "assinatura_necessaria"


@pytest.mark.asyncio
async def test_gate_libera_apos_assinatura_ativada_pelo_webhook(
    client, aluno, responsavel
):
    await seed_trilha()
    await seed_vocabulario()
    await _set_xp(aluno["usuario_id"], 50_000)

    # Confirma que estava bloqueado antes de assinar.
    bloqueado = await client.post("/v1/sessoes", headers=aluno["headers"])
    assert bloqueado.status_code == 402

    conta_id = await _conta_id(client, responsavel["headers"])
    body = _evento(tipo="INITIAL_PURCHASE", app_user_id=conta_id, expira_em_ms=9_999_999_999_999)
    await client.post(
        "/v1/assinatura/webhook", json=body, headers={"Authorization": f"Bearer {SEGREDO}"}
    )

    liberado = await client.post("/v1/sessoes", headers=aluno["headers"])
    assert liberado.status_code == 201


@pytest.mark.asyncio
async def test_gate_permite_sessao_dentro_do_free_tier_sem_assinatura(client, aluno):
    await seed_trilha()
    await seed_vocabulario()
    # Sem set de XP: aluno novo, dentro do 1º destino — não precisa assinar.
    r = await client.post("/v1/sessoes", headers=aluno["headers"])
    assert r.status_code == 201
