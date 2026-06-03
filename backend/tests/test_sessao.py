"""Composição da sessão (montar_sessao, Bloco 2a)."""
import pytest
from sqlalchemy import insert

from app import schema
from app.db import engine
from app.seed_vocabulario import seed_vocabulario


async def _mapa_palavras(client, headers) -> dict[str, int]:
    r = await client.get("/v1/palavras?limit=100", headers=headers)
    return {item["lema"]: item["id"] for item in r.json()["items"]}


async def _em_progresso(usuario_id, palavra_id, estado, nivel4=None):
    """Coloca uma palavra num estado de progresso (simula sessões anteriores)."""
    async with engine.begin() as conn:
        await conn.execute(
            insert(schema.aluno_palavra).values(
                usuario_id=usuario_id,
                palavra_id=palavra_id,
                estado=estado,
                origem="banco_base",
                nivel4_agendado_para=nivel4,
            )
        )


def _cards(slots):
    return [s for s in slots if s["tipo"] == "card"]


def _questoes(slots):
    return [s for s in slots if s["tipo"] == "questao"]


@pytest.mark.asyncio
async def test_sessao_requer_auth(client):
    r = await client.post("/v1/sessoes")
    assert r.status_code == 401
    assert r.json()["error"]["code"] == "nao_autenticado"


@pytest.mark.asyncio
async def test_aluno_novo_recebe_fila_com_cards_e_questoes(client, aluno):
    await seed_vocabulario()

    r = await client.post("/v1/sessoes", headers=aluno["headers"])
    assert r.status_code == 201, r.text
    body = r.json()
    assert isinstance(body["sessao_id"], int)

    slots = body["slots"]
    assert slots[0]["tipo"] == "card"          # cards agrupados no início
    assert len(_cards(slots)) >= 2             # ao menos 2 palavras novas
    assert len(_questoes(slots)) >= 6          # ~N1/N2/N3 das novas
    # Nunca vaza a resposta correta (cliente fino).
    assert "resposta_correta" not in r.text


@pytest.mark.asyncio
async def test_cards_sao_seguidos_das_proprias_questoes(client, aluno):
    await seed_vocabulario()
    slots = (await client.post("/v1/sessoes", headers=aluno["headers"])).json()["slots"]

    # Cada card vem colado a pelo menos uma questão da mesma palavra (nenhum card
    # interrompe o meio sem contexto).
    for i, s in enumerate(slots):
        if s["tipo"] == "card":
            seguinte = slots[i + 1]
            assert seguinte["tipo"] == "questao"
            assert seguinte["palavra_id"] == s["palavra"]["id"]


@pytest.mark.asyncio
async def test_nao_reintroduz_as_mesmas_palavras(client, aluno):
    await seed_vocabulario()
    h = aluno["headers"]

    s1 = (await client.post("/v1/sessoes", headers=h)).json()["slots"]
    s2 = (await client.post("/v1/sessoes", headers=h)).json()["slots"]

    ids1 = {c["palavra"]["id"] for c in _cards(s1)}
    ids2 = {c["palavra"]["id"] for c in _cards(s2)}
    assert ids1 and ids2
    assert ids1.isdisjoint(ids2)  # a 2ª sessão traz palavras diferentes


@pytest.mark.asyncio
async def test_revisao_escolhe_n2_da_palavra_em_progresso(client, aluno):
    await seed_vocabulario()
    mapa = await _mapa_palavras(client, aluno["headers"])
    alvo = mapa["relevante"]
    await _em_progresso(aluno["usuario_id"], alvo, estado="nivel_2")

    slots = (await client.post("/v1/sessoes", headers=aluno["headers"])).json()["slots"]
    revisao = [s for s in _questoes(slots) if s["is_revisao"] and s["palavra_id"] == alvo]
    assert revisao, "a palavra em progresso deveria aparecer na revisão"
    assert revisao[0]["nivel"] == 2  # N2 tem prioridade; N1 nunca vira revisão


@pytest.mark.asyncio
async def test_n4_vencido_entra_na_revisao(client, aluno):
    await seed_vocabulario()
    mapa = await _mapa_palavras(client, aluno["headers"])
    alvo = mapa["belo"]
    # estado nivel_4 com agendamento já vencido (sessoes_total começa em 0).
    await _em_progresso(aluno["usuario_id"], alvo, estado="nivel_4", nivel4=0)

    slots = (await client.post("/v1/sessoes", headers=aluno["headers"])).json()["slots"]
    niveis = {s["nivel"] for s in _questoes(slots) if s["is_revisao"] and s["palavra_id"] == alvo}
    assert 4 in niveis  # o N4 vencido foi incluído
