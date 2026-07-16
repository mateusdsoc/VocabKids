"""Seed de apresentação (`app.seed_demo`): o estado vitrine sai da lógica real
de recompensas e re-rodar restaura tudo (inclusive o reveal pendente)."""
import pytest

from app.seed import CODIGO_TURMA, seed
from app.seed_demo import seed_demo
from app.seed_trilha import seed_trilha
from app.seed_vocabulario import seed_vocabulario


async def _semear_tudo():
    await seed()
    await seed_vocabulario()
    await seed_trilha()
    return await seed_demo()


async def _entrar(client, nome):
    r = await client.post(
        "/v1/acesso/turma", json={"codigo_turma": CODIGO_TURMA, "nome": nome}
    )
    corpo = r.json()
    return {"Authorization": f"Bearer {corpo['token']}"}, corpo


@pytest.mark.asyncio
async def test_ana_estado_vitrine(client):
    """Brasil fechado + 2 destinos da França, meta parcial e 1 reveal pendente."""
    await _semear_tudo()
    headers, corpo = await _entrar(client, "Ana Viajante")
    assert corpo["novo"] is False  # o seed criou; entrar não duplica

    me = (await client.get("/v1/me", headers=headers)).json()
    assert me["progresso"]["xp_total"] == 128_600  # 28 nós × 4500 + 2600 parciais
    assert me["progresso"]["palavras_dominadas"] == 26
    assert me["meta_semanal"] == {"atual": 3, "alvo": 5}  # default do 7º ano

    mapa = (await client.get("/v1/trilha", headers=headers)).json()
    brasil = next(p for p in mapa["paises"] if p["nome"] == "Brasil")
    assert brasil["concluido"]
    franca = next(p for p in mapa["paises"] if p["nome"] == "França")
    assert sum(d["concluido"] for d in franca["destinos"]) == 2
    assert "Provença" in mapa["no_atual"]["destino_nome"]

    passaporte = (await client.get("/v1/passaporte", headers=headers)).json()
    # 5 cartões BR + carimbo BR + 2 cartões FR + selos combo_10 e dominadas_25
    assert passaporte["conquistados"] == 10
    pendentes = [
        i for i in passaporte["itens"] if i["conquistado"] and not i["revelado"]
    ]
    assert len(pendentes) == 1  # o Modo Conquista dispara 1× ao abrir o Passaporte
    assert pendentes[0]["tipo"] == "cartao_postal"


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
    headers, _ = await _entrar(client, "Ana Viajante")

    # A apresentação "gasta" o reveal pendente…
    passaporte = (await client.get("/v1/passaporte", headers=headers)).json()
    pendente = next(
        i for i in passaporte["itens"] if i["conquistado"] and not i["revelado"]
    )
    r = await client.post(
        f"/v1/passaporte/{pendente['id']}/revelado", headers=headers
    )
    assert r.status_code == 200

    # …e re-rodar o seed rearma tudo, sem duplicar aluno nem coleção.
    await seed_demo()
    _, corpo = await _entrar(client, "Ana Viajante")
    assert corpo["novo"] is False
    depois = (await client.get("/v1/passaporte", headers=headers)).json()
    assert depois["conquistados"] == 10
    assert (
        sum(1 for i in depois["itens"] if i["conquistado"] and not i["revelado"]) == 1
    )
