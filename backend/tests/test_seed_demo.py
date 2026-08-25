"""Seed de apresentação (`app.seed_demo`): o estado vitrine sai da lógica real
de recompensas e re-rodar restaura tudo (inclusive o reveal pendente).

B2C (docs/plano_b2c.md Fase 1): os perfis vivem na conta "vitrine"
(`EMAIL_CONTA_DEMO`/`SENHA_CONTA_DEMO`), não mais numa turma — entrar como uma
persona é login da conta + seleção de perfil, não mais `/acesso/turma`.
"""
import pytest

from app.seed_demo import EMAIL_CONTA_DEMO, SENHA_CONTA_DEMO, seed_demo
from app.seed_trilha import seed_trilha
from app.seed_vocabulario import seed_vocabulario


async def _semear_tudo():
    await seed_vocabulario()
    await seed_trilha()
    return await seed_demo()


async def _entrar(client, nome):
    login = (
        await client.post(
            "/v1/sessao", json={"email": EMAIL_CONTA_DEMO, "senha": SENHA_CONTA_DEMO}
        )
    ).json()
    headers_responsavel = {"Authorization": f"Bearer {login['token']}"}
    perfis = (
        await client.get("/v1/conta/perfis", headers=headers_responsavel)
    ).json()
    perfil = next(p for p in perfis if p["apelido"] == nome)
    corpo = (
        await client.post(
            f"/v1/perfis/{perfil['usuario_id']}/entrar", headers=headers_responsavel
        )
    ).json()
    return {"Authorization": f"Bearer {corpo['token']}"}, perfil


@pytest.mark.asyncio
async def test_ana_estado_vitrine(client):
    """MVP (docs/plano_b2c.md): Brasil fechado (3 destinos), 2 dos 4 nós de
    Paris, meta parcial e 1 reveal pendente."""
    await _semear_tudo()
    headers, perfil = await _entrar(client, "Ana Viajante")

    me = (await client.get("/v1/me", headers=headers)).json()
    assert me["progresso"]["xp_total"] == 65_000  # 14 nós × 4500 + 2000 parciais
    assert me["progresso"]["palavras_dominadas"] == 20
    assert me["meta_semanal"] == {"atual": 3, "alvo": 5}  # default da faixa 11-12

    mapa = (await client.get("/v1/trilha", headers=headers)).json()
    brasil = next(p for p in mapa["paises"] if p["nome"] == "Brasil")
    assert brasil["concluido"]
    franca = next(p for p in mapa["paises"] if p["nome"] == "França")
    assert sum(d["concluido"] for d in franca["destinos"]) == 0  # Paris ainda não fechou
    assert "Paris" in mapa["no_atual"]["destino_nome"]

    passaporte = (await client.get("/v1/passaporte", headers=headers)).json()
    # 3 cartões BR (Rio/Foz/Amazônia) + carimbo BR + selo combo_10
    assert passaporte["conquistados"] == 5
    pendentes = [
        i for i in passaporte["itens"] if i["conquistado"] and not i["revelado"]
    ]
    assert len(pendentes) == 1  # o Modo Conquista dispara 1× ao abrir o Passaporte
    assert pendentes[0]["tipo"] == "carimbo"  # o carimbo do Brasil fica pra revelar


@pytest.mark.asyncio
async def test_beto_meio_da_jornada(client):
    await _semear_tudo()
    headers, _ = await _entrar(client, "Beto Explorador")

    mapa = (await client.get("/v1/trilha", headers=headers)).json()
    brasil = next(p for p in mapa["paises"] if p["nome"] == "Brasil")
    assert not brasil["concluido"]
    assert sum(d["concluido"] for d in brasil["destinos"]) == 2

    passaporte = (await client.get("/v1/passaporte", headers=headers)).json()
    ganhos = [i for i in passaporte["itens"] if i["conquistado"]]
    assert {i["tipo"] for i in ganhos} == {"cartao_postal"}  # sem carimbo/selos
    assert passaporte["conquistados"] == 2


@pytest.mark.asyncio
async def test_vitrine_joga_sessao_ao_vivo(client):
    """A persona não é só fachada: abre sessão real (novas + revisão)."""
    await _semear_tudo()
    headers, _ = await _entrar(client, "Ana Viajante")
    sessao = (await client.post("/v1/sessoes", headers=headers)).json()
    assert sessao["slots"]


@pytest.mark.asyncio
async def test_rerodar_restaura_a_vitrine(client):
    await _semear_tudo()
    headers, perfil_antes = await _entrar(client, "Ana Viajante")

    # A apresentação "gasta" o reveal pendente…
    passaporte = (await client.get("/v1/passaporte", headers=headers)).json()
    pendente = next(
        i for i in passaporte["itens"] if i["conquistado"] and not i["revelado"]
    )
    r = await client.post(
        f"/v1/passaporte/{pendente['id']}/revelado", headers=headers
    )
    assert r.status_code == 200

    # …e re-rodar o seed rearma tudo, sem duplicar perfil nem coleção.
    await seed_demo()
    _, perfil_depois = await _entrar(client, "Ana Viajante")
    assert perfil_depois["usuario_id"] == perfil_antes["usuario_id"]  # não duplicou
    headers, _ = await _entrar(client, "Ana Viajante")
    depois = (await client.get("/v1/passaporte", headers=headers)).json()
    assert depois["conquistados"] == 5
    assert (
        sum(1 for i in depois["itens"] if i["conquistado"] and not i["revelado"]) == 1
    )
