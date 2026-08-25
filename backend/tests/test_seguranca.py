"""Trio de segurança: rate limiting (regra pura + middleware) e CORS."""
import pytest

from app.config import settings
from app.main import limitador
from app.seguranca.rate_limit import LimitadorJanelaFixa

# ---------------------------------------------------------------- regra pura


def test_limitador_conta_por_chave_dentro_da_janela():
    lim = LimitadorJanelaFixa()
    assert lim.permitir("a", 2, agora=0)
    assert lim.permitir("a", 2, agora=1)
    assert not lim.permitir("a", 2, agora=2)  # estourou
    assert lim.permitir("b", 2, agora=2)  # chave independente


def test_limitador_zera_quando_a_janela_vira():
    lim = LimitadorJanelaFixa()
    assert lim.permitir("a", 1, agora=0)
    assert not lim.permitir("a", 1, agora=59)
    assert lim.permitir("a", 1, agora=60)  # nova janela
    # A poda limpa o dicionário inteiro na virada — sem acúmulo de chaves velhas.
    assert len(lim._contagens) == 1


def test_limitador_zerar():
    lim = LimitadorJanelaFixa()
    assert lim.permitir("a", 1, agora=0)
    lim.zerar()
    assert lim.permitir("a", 1, agora=0)


# ---------------------------------------------------------------- middleware


@pytest.fixture
def rate_limit_ligado(monkeypatch):
    monkeypatch.setattr(settings, "rate_limit_habilitado", True)
    limitador.zerar()
    yield
    limitador.zerar()


@pytest.mark.asyncio
async def test_login_estoura_limite_por_ip(client, rate_limit_ligado, monkeypatch):
    monkeypatch.setattr(settings, "rl_login_por_minuto", 3)
    corpo = {"email": "naoexiste@teste.com", "senha": "qualquer"}
    for _ in range(3):
        r = await client.post("/v1/sessao", json=corpo)
        assert r.status_code == 401  # passa pelo limitador, falha no domínio
    r = await client.post("/v1/sessao", json=corpo)
    assert r.status_code == 429
    assert r.json()["error"]["code"] == "limite_excedido"
    assert r.headers["retry-after"] == "60"


@pytest.mark.asyncio
async def test_autenticado_conta_por_token_nao_por_ip(
    client, rate_limit_ligado, monkeypatch, aluno
):
    """Dois tokens no mesmo IP têm orçamentos separados (NAT compartilhado)."""
    # Prepara o segundo token (conta totalmente nova) ANTES de apertar o
    # limite — senão a própria criação de conta/perfil já gastaria o
    # orçamento apertado do teste, e o teste checaria a coisa errada.
    outro_responsavel = (
        await client.post(
            "/v1/conta",
            json={
                "nome": "Outro Responsável",
                "email": "outro-ip@teste.com",
                "senha": "senha-forte-123",
                "aceite_termos": True,
                "consentimento_lgpd": True,
            },
        )
    ).json()
    outro_headers = {"Authorization": f"Bearer {outro_responsavel['token']}"}
    perfil2 = (
        await client.post(
            "/v1/conta/perfis",
            json={"apelido": "Bia", "ano_nascimento": 2015},
            headers=outro_headers,
        )
    ).json()
    b = (
        await client.post(
            f"/v1/perfis/{perfil2['usuario_id']}/entrar", headers=outro_headers
        )
    ).json()
    h2 = {"Authorization": f"Bearer {b['token']}"}

    monkeypatch.setattr(settings, "rl_autenticado_por_minuto", 2)
    h1 = aluno["headers"]
    for _ in range(2):
        assert (await client.get("/v1/me", headers=h1)).status_code == 200
    assert (await client.get("/v1/me", headers=h1)).status_code == 429

    # h2 nunca fez uma chamada autenticada antes — orçamento próprio, intacto.
    assert (await client.get("/v1/me", headers=h2)).status_code == 200


# ---------------------------------------------------------------------- CORS


@pytest.mark.asyncio
async def test_cors_origem_permitida(client):
    r = await client.get("/health", headers={"Origin": "http://cors-permitido.test"})
    assert r.headers.get("access-control-allow-origin") == "http://cors-permitido.test"


@pytest.mark.asyncio
async def test_cors_origem_desconhecida_nao_liberada(client):
    r = await client.get("/health", headers={"Origin": "http://intruso.test"})
    assert "access-control-allow-origin" not in r.headers


@pytest.mark.asyncio
async def test_cors_preflight_nao_abre_transacao(client):
    """O preflight é respondido pelo CORS (camada mais externa) — sem banco."""
    r = await client.options(
        "/v1/me",
        headers={
            "Origin": "http://cors-permitido.test",
            "Access-Control-Request-Method": "GET",
            "Access-Control-Request-Headers": "Authorization",
        },
    )
    assert r.status_code == 200
    assert r.headers.get("access-control-allow-origin") == "http://cors-permitido.test"
    assert "authorization" in r.headers.get("access-control-allow-headers", "").lower()
