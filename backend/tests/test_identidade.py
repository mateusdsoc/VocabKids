"""Fatia vertical do identidade: acesso por código de turma + /me + erros."""
import pytest

from app.seed import seed


@pytest.mark.asyncio
async def test_health(client):
    r = await client.get("/health")
    assert r.status_code == 200
    assert r.json() == {"status": "ok"}


@pytest.mark.asyncio
async def test_acesso_cria_e_reusa_aluno(client):
    s = await seed()

    r1 = await client.post(
        "/v1/acesso/turma", json={"codigo_turma": s["codigo_turma"], "nome": "Ana"}
    )
    assert r1.status_code == 200, r1.text
    b1 = r1.json()
    assert b1["novo"] is True
    assert b1["turma"]["ano_escolar"] == 7
    assert b1["token"].startswith("prov_")

    # Mesmo nome (case-insensitive) reusa o mesmo aluno — não duplica.
    r2 = await client.post(
        "/v1/acesso/turma", json={"codigo_turma": s["codigo_turma"], "nome": "ana"}
    )
    b2 = r2.json()
    assert b2["novo"] is False
    assert b2["usuario_id"] == b1["usuario_id"]


@pytest.mark.asyncio
async def test_acesso_codigo_invalido(client):
    r = await client.post(
        "/v1/acesso/turma", json={"codigo_turma": "NAOEXISTE", "nome": "Ana"}
    )
    assert r.status_code == 404
    assert r.json()["error"]["code"] == "turma_nao_encontrada"


@pytest.mark.asyncio
async def test_me_fluxo_completo(client):
    s = await seed()
    acesso = (
        await client.post(
            "/v1/acesso/turma", json={"codigo_turma": s["codigo_turma"], "nome": "Ana"}
        )
    ).json()

    r = await client.get(
        "/v1/me", headers={"Authorization": f"Bearer {acesso['token']}"}
    )
    assert r.status_code == 200, r.text
    me = r.json()
    assert me["usuario_id"] == acesso["usuario_id"]
    assert me["papel"] == "aluno"
    assert me["turma"]["id"] == acesso["turma"]["id"]
    assert me["escola"]["nome"] == "Escola Demonstração"
    assert me["progresso"]["xp_total"] == 0
    assert me["progresso"]["nivel_dificuldade_atual"] == 1


@pytest.mark.asyncio
async def test_me_sem_token(client):
    r = await client.get("/v1/me")
    assert r.status_code == 401
    assert r.json()["error"]["code"] == "nao_autenticado"


@pytest.mark.asyncio
async def test_me_token_invalido(client):
    r = await client.get("/v1/me", headers={"Authorization": "Bearer prov_999999"})
    assert r.status_code == 401
    assert r.json()["error"]["code"] == "nao_autenticado"


@pytest.mark.asyncio
async def test_validacao_usa_formato_padrao(client):
    r = await client.post("/v1/acesso/turma", json={"nome": "Ana"})  # falta codigo_turma
    assert r.status_code == 422
    body = r.json()
    assert body["error"]["code"] == "validation_error"
    assert "errors" in body["error"]["details"]
