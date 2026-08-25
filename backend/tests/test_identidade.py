"""Fatia vertical do identidade B2C: conta do responsável, perfis de criança,
`/me` e erros (docs/plano_b2c.md Fase 1)."""
import time

import jwt
import pytest

from app.config import settings

CADASTRO = {
    "nome": "Responsável Teste",
    "email": "responsavel@teste.com",
    "senha": "senha-forte-123",
    "aceite_termos": True,
    "consentimento_lgpd": True,
}


@pytest.mark.asyncio
async def test_health(client):
    r = await client.get("/health")
    assert r.status_code == 200
    assert r.json() == {"status": "ok"}


@pytest.mark.asyncio
async def test_cadastro_responsavel(client):
    r = await client.post("/v1/conta", json=CADASTRO)
    assert r.status_code == 200, r.text
    token = r.json()["token"]
    claims = jwt.decode(token, settings.jwt_secret, algorithms=["HS256"])
    assert claims["papel"] == "responsavel"
    assert claims["exp"] > time.time()


@pytest.mark.asyncio
async def test_cadastro_exige_consentimento_lgpd(client):
    r = await client.post("/v1/conta", json={**CADASTRO, "consentimento_lgpd": False})
    assert r.status_code == 422
    assert r.json()["error"]["code"] == "consentimento_obrigatorio"


@pytest.mark.asyncio
async def test_cadastro_email_duplicado(client):
    r1 = await client.post("/v1/conta", json=CADASTRO)
    assert r1.status_code == 200
    r2 = await client.post("/v1/conta", json=CADASTRO)
    assert r2.status_code == 409
    assert r2.json()["error"]["code"] == "email_em_uso"


@pytest.mark.asyncio
async def test_login(client):
    await client.post("/v1/conta", json=CADASTRO)
    r = await client.post(
        "/v1/sessao", json={"email": CADASTRO["email"], "senha": CADASTRO["senha"]}
    )
    assert r.status_code == 200, r.text
    assert "token" in r.json()


@pytest.mark.asyncio
async def test_login_senha_errada(client):
    await client.post("/v1/conta", json=CADASTRO)
    r = await client.post(
        "/v1/sessao", json={"email": CADASTRO["email"], "senha": "errada"}
    )
    assert r.status_code == 401
    assert r.json()["error"]["code"] == "credenciais_invalidas"


@pytest.mark.asyncio
async def test_criar_e_listar_perfis(client, responsavel):
    r = await client.post(
        "/v1/conta/perfis",
        json={"apelido": "Ana", "ano_nascimento": 2016},
        headers=responsavel["headers"],
    )
    assert r.status_code == 200, r.text
    perfil = r.json()
    assert perfil["apelido"] == "Ana"
    assert perfil["faixa_etaria"] in ("7-8", "9-10", "11-12")

    r = await client.get("/v1/conta/perfis", headers=responsavel["headers"])
    assert r.status_code == 200
    assert len(r.json()) == 1


@pytest.mark.asyncio
async def test_limite_de_perfis_por_conta(client, responsavel):
    for ano in (2013, 2015, 2017):
        r = await client.post(
            "/v1/conta/perfis",
            json={"apelido": f"Criança {ano}", "ano_nascimento": ano},
            headers=responsavel["headers"],
        )
        assert r.status_code == 200

    r = await client.post(
        "/v1/conta/perfis",
        json={"apelido": "Quarta criança", "ano_nascimento": 2018},
        headers=responsavel["headers"],
    )
    assert r.status_code == 422
    assert r.json()["error"]["code"] == "limite_de_perfis"


@pytest.mark.asyncio
async def test_entrar_como_crianca_de_outra_conta_e_404(client, responsavel):
    outro = (
        await client.post(
            "/v1/conta",
            json={**CADASTRO, "email": "outro@teste.com"},
        )
    ).json()
    outro_headers = {"Authorization": f"Bearer {outro['token']}"}
    perfil_do_outro = (
        await client.post(
            "/v1/conta/perfis",
            json={"apelido": "Beto", "ano_nascimento": 2015},
            headers=outro_headers,
        )
    ).json()

    r = await client.post(
        f"/v1/perfis/{perfil_do_outro['usuario_id']}/entrar",
        headers=responsavel["headers"],
    )
    assert r.status_code == 404
    assert r.json()["error"]["code"] == "perfil_nao_encontrado"


@pytest.mark.asyncio
async def test_responsavel_nao_acessa_rotas_de_gameplay(client, responsavel):
    r = await client.get("/v1/trilha", headers=responsavel["headers"])
    assert r.status_code == 403
    assert r.json()["error"]["code"] == "sem_permissao"


@pytest.mark.asyncio
async def test_crianca_nao_acessa_rotas_do_responsavel(client, aluno):
    r = await client.get("/v1/conta/perfis", headers=aluno["headers"])
    assert r.status_code == 403
    assert r.json()["error"]["code"] == "sem_permissao"


@pytest.mark.asyncio
async def test_me_fluxo_completo(client, aluno):
    r = await client.get("/v1/me", headers=aluno["headers"])
    assert r.status_code == 200, r.text
    me = r.json()
    assert me["usuario_id"] == aluno["usuario_id"]
    assert me["papel"] == "aluno"
    assert me["perfil"]["apelido"] == "Ana"
    assert me["progresso"]["xp_total"] == 0
    assert me["progresso"]["nivel_dificuldade_atual"] == 1
    # Meta da semana: perfil novo, nada dominado; alvo = default da faixa.
    assert me["meta_semanal"]["atual"] == 0
    assert me["meta_semanal"]["alvo"] > 0


@pytest.mark.asyncio
async def test_me_sem_token(client):
    r = await client.get("/v1/me")
    assert r.status_code == 401
    assert r.json()["error"]["code"] == "nao_autenticado"


@pytest.mark.asyncio
async def test_me_token_invalido(client):
    for token in ("prov_999999", "nao-e-um-jwt"):
        r = await client.get("/v1/me", headers={"Authorization": f"Bearer {token}"})
        assert r.status_code == 401
        assert r.json()["error"]["code"] == "nao_autenticado"


@pytest.mark.asyncio
async def test_me_token_adulterado(client, aluno):
    # Reassina o token com outro segredo (forja de `sub`) — a assinatura denuncia.
    claims = jwt.decode(
        aluno["headers"]["Authorization"].removeprefix("Bearer "),
        settings.jwt_secret,
        algorithms=["HS256"],
    )
    claims["sub"] = str(int(claims["sub"]) + 1)
    forjado = jwt.encode(
        claims, "segredo-errado-com-tamanho-suficiente-p/hs256", algorithm="HS256"
    )
    r = await client.get("/v1/me", headers={"Authorization": f"Bearer {forjado}"})
    assert r.status_code == 401
    assert r.json()["error"]["code"] == "nao_autenticado"


@pytest.mark.asyncio
async def test_me_token_expirado(client, aluno):
    agora = int(time.time())
    expirado = jwt.encode(
        {
            "sub": str(aluno["usuario_id"]),
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
async def test_me_token_sem_assinatura_rejeitado(client, aluno):
    """`alg: none` nunca passa — o algoritmo é fixado no servidor."""
    sem_assinatura = jwt.encode(
        {"sub": str(aluno["usuario_id"]), "exp": int(time.time()) + 3600},
        None,
        algorithm="none",
    )
    r = await client.get(
        "/v1/me", headers={"Authorization": f"Bearer {sem_assinatura}"}
    )
    assert r.status_code == 401


@pytest.mark.asyncio
async def test_validacao_usa_formato_padrao(client):
    r = await client.post("/v1/conta", json={"nome": "Ana"})  # falta email/senha/etc.
    assert r.status_code == 422
    body = r.json()
    assert body["error"]["code"] == "validation_error"
    assert "errors" in body["error"]["details"]


@pytest.mark.asyncio
async def test_excluir_conta_apaga_responsavel_e_filhos(client, responsavel, aluno):
    r = await client.request(
        "DELETE",
        "/v1/conta",
        json={"senha": CADASTRO["senha"]},
        headers=responsavel["headers"],
    )
    assert r.status_code == 204

    # A criança some junto — token dela deixa de resolver usuário.
    r = await client.get("/v1/me", headers=aluno["headers"])
    assert r.status_code == 401


@pytest.mark.asyncio
async def test_excluir_conta_exige_senha_correta(client, responsavel):
    r = await client.request(
        "DELETE",
        "/v1/conta",
        json={"senha": "senha-errada"},
        headers=responsavel["headers"],
    )
    assert r.status_code == 401
