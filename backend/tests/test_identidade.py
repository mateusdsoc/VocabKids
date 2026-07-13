"""Fatia vertical do identidade: acesso por código de turma + /me + erros."""
import time

import jwt
import pytest

from app.config import settings
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
    # Token é um JWT assinado, com dono, papel e expiração.
    claims = jwt.decode(b1["token"], settings.jwt_secret, algorithms=["HS256"])
    assert claims["sub"] == str(b1["usuario_id"])
    assert claims["papel"] == "aluno"
    assert claims["exp"] > time.time()

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
    # Formato antigo (prov_) e lixo qualquer: ambos caem na validação do JWT.
    for token in ("prov_999999", "nao-e-um-jwt"):
        r = await client.get("/v1/me", headers={"Authorization": f"Bearer {token}"})
        assert r.status_code == 401
        assert r.json()["error"]["code"] == "nao_autenticado"


@pytest.mark.asyncio
async def test_me_token_adulterado(client):
    s = await seed()
    acesso = (
        await client.post(
            "/v1/acesso/turma", json={"codigo_turma": s["codigo_turma"], "nome": "Ana"}
        )
    ).json()
    # Reassina o token com outro segredo (forja de `sub`) — a assinatura denuncia.
    claims = jwt.decode(
        acesso["token"], settings.jwt_secret, algorithms=["HS256"]
    )
    claims["sub"] = str(int(claims["sub"]) + 1)
    forjado = jwt.encode(
        claims, "segredo-errado-com-tamanho-suficiente-p/hs256", algorithm="HS256"
    )
    r = await client.get("/v1/me", headers={"Authorization": f"Bearer {forjado}"})
    assert r.status_code == 401
    assert r.json()["error"]["code"] == "nao_autenticado"


@pytest.mark.asyncio
async def test_me_token_expirado(client):
    s = await seed()
    acesso = (
        await client.post(
            "/v1/acesso/turma", json={"codigo_turma": s["codigo_turma"], "nome": "Ana"}
        )
    ).json()
    agora = int(time.time())
    expirado = jwt.encode(
        {
            "sub": str(acesso["usuario_id"]),
            "papel": "aluno",
            "iat": agora - 7200,
            "exp": agora - 3600,
        },
        settings.jwt_secret,
        algorithm="HS256",
    )
    r = await client.get("/v1/me", headers={"Authorization": f"Bearer {expirado}"})
    assert r.status_code == 401
    assert r.json()["error"]["code"] == "sessao_expirada"


@pytest.mark.asyncio
async def test_me_token_sem_assinatura_rejeitado(client):
    """`alg: none` nunca passa — o algoritmo é fixado no servidor."""
    s = await seed()
    acesso = (
        await client.post(
            "/v1/acesso/turma", json={"codigo_turma": s["codigo_turma"], "nome": "Ana"}
        )
    ).json()
    sem_assinatura = jwt.encode(
        {"sub": str(acesso["usuario_id"]), "exp": int(time.time()) + 3600},
        None,
        algorithm="none",
    )
    r = await client.get(
        "/v1/me", headers={"Authorization": f"Bearer {sem_assinatura}"}
    )
    assert r.status_code == 401


@pytest.mark.asyncio
async def test_validacao_usa_formato_padrao(client):
    r = await client.post("/v1/acesso/turma", json={"nome": "Ana"})  # falta codigo_turma
    assert r.status_code == 422
    body = r.json()
    assert body["error"]["code"] == "validation_error"
    assert "errors" in body["error"]["details"]
