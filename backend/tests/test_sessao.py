"""Composição da sessão (montar_sessao, Bloco 2a)."""
import pytest
from sqlalchemy import func, insert, select, update

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


async def _resposta_correta(questao_id) -> str:
    async with engine.begin() as conn:
        return (
            await conn.execute(
                select(schema.questao.c.resposta_correta).where(
                    schema.questao.c.id == questao_id
                )
            )
        ).scalar_one()


async def _definir_nivel(usuario_id, nivel):
    async with engine.begin() as conn:
        await conn.execute(
            update(schema.aluno_progresso)
            .where(schema.aluno_progresso.c.usuario_id == usuario_id)
            .values(nivel_dificuldade_atual=nivel)
        )


async def _semear_respostas_no_nivel(usuario_id, nivel, acertos, total):
    """Insere `total` respostas de questões de palavras nesse nível; `acertos`
    delas como acerto de 1ª tentativa — alimenta o sinal da adaptação."""
    async with engine.begin() as conn:
        ids = (
            await conn.execute(
                select(schema.questao.c.id)
                .select_from(
                    schema.questao.join(
                        schema.palavra,
                        schema.palavra.c.id == schema.questao.c.palavra_id,
                    )
                )
                .where(schema.palavra.c.nivel_dificuldade == nivel)
                .limit(total)
            )
        ).scalars().all()
        for i, qid in enumerate(ids):
            ok = i < acertos
            await conn.execute(
                insert(schema.aluno_questao).values(
                    usuario_id=usuario_id,
                    questao_id=qid,
                    tentativas=1,
                    acertou=ok,
                    acertou_primeira=ok,
                    respondida_em=func.now(),
                )
            )


def _primeira_questao(slots, nivel):
    return next(s for s in _questoes(slots) if s["nivel"] == nivel)


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


# ─────────────────────────────── responder ───────────────────────────────


@pytest.mark.asyncio
async def test_responder_requer_auth(client):
    r = await client.post("/v1/sessoes/1/respostas", json={"questao_id": 1, "opcao": "x"})
    assert r.status_code == 401


@pytest.mark.asyncio
async def test_responder_sessao_inexistente(client, aluno):
    await seed_vocabulario()
    r = await client.post(
        "/v1/sessoes/999/respostas",
        headers=aluno["headers"],
        json={"questao_id": 1, "opcao": "x"},
    )
    assert r.status_code == 404
    assert r.json()["error"]["code"] == "sessao_nao_encontrada"


@pytest.mark.asyncio
async def test_acerto_de_primeira_da_xp_e_avanca_estado(client, aluno):
    await seed_vocabulario()
    h = aluno["headers"]
    sessao = (await client.post("/v1/sessoes", headers=h)).json()
    q1 = _primeira_questao(sessao["slots"], nivel=1)
    correta = await _resposta_correta(q1["questao_id"])

    r = await client.post(
        f"/v1/sessoes/{sessao['sessao_id']}/respostas",
        headers=h,
        json={"questao_id": q1["questao_id"], "opcao": correta},
    )
    assert r.status_code == 200, r.text
    b = r.json()
    assert b["correto"] is True
    assert b["xp_ganho"] == 120          # 100 + bônus de combo (18 + 2×1)
    assert b["combo_atual"] == 1
    assert b["xp_total"] == 120
    assert b["estado_palavra"] == "nivel_2"  # descoberta → passou N1 → nivel_2
    assert b["dominou"] is False


@pytest.mark.asyncio
async def test_erro_zera_combo_nao_avanca_e_xp_zero(client, aluno):
    await seed_vocabulario()
    h = aluno["headers"]
    sessao = (await client.post("/v1/sessoes", headers=h)).json()
    q1 = _primeira_questao(sessao["slots"], nivel=1)
    correta = await _resposta_correta(q1["questao_id"])
    errada = next(o for o in q1["opcoes"] if o != correta)

    r = await client.post(
        f"/v1/sessoes/{sessao['sessao_id']}/respostas",
        headers=h,
        json={"questao_id": q1["questao_id"], "opcao": errada},
    )
    b = r.json()
    assert b["correto"] is False
    assert b["xp_ganho"] == 0
    assert b["combo_atual"] == 0
    assert b["estado_palavra"] == "descoberta"  # não avançou
    assert b["resposta_correta"] == correta     # feedback revela a correta


@pytest.mark.asyncio
async def test_acerto_na_segunda_tentativa_vale_70(client, aluno):
    await seed_vocabulario()
    h = aluno["headers"]
    sessao = (await client.post("/v1/sessoes", headers=h)).json()
    sid = sessao["sessao_id"]
    q1 = _primeira_questao(sessao["slots"], nivel=1)
    correta = await _resposta_correta(q1["questao_id"])
    errada = next(o for o in q1["opcoes"] if o != correta)

    await client.post(
        f"/v1/sessoes/{sid}/respostas",
        headers=h,
        json={"questao_id": q1["questao_id"], "opcao": errada},
    )
    r = await client.post(
        f"/v1/sessoes/{sid}/respostas",
        headers=h,
        json={"questao_id": q1["questao_id"], "opcao": correta},
    )
    b = r.json()
    assert b["correto"] is True
    assert b["tentativas"] == 2
    assert b["xp_ganho"] == 70   # 2ª tentativa, sem combo
    assert b["combo_atual"] == 0
    assert b["estado_palavra"] == "nivel_2"  # passar o nível independe de tentativas


@pytest.mark.asyncio
async def test_nao_repergunta_variacao_ja_acertada(client, aluno):
    await seed_vocabulario()
    h = aluno["headers"]
    sessao = (await client.post("/v1/sessoes", headers=h)).json()
    sid = sessao["sessao_id"]
    q1 = _primeira_questao(sessao["slots"], nivel=1)
    correta = await _resposta_correta(q1["questao_id"])

    primeira = await client.post(
        f"/v1/sessoes/{sid}/respostas",
        headers=h,
        json={"questao_id": q1["questao_id"], "opcao": correta},
    )
    assert primeira.status_code == 200
    repetida = await client.post(
        f"/v1/sessoes/{sid}/respostas",
        headers=h,
        json={"questao_id": q1["questao_id"], "opcao": correta},
    )
    assert repetida.status_code == 409
    assert repetida.json()["error"]["code"] == "questao_ja_respondida"


@pytest.mark.asyncio
async def test_passar_o_n4_domina_a_palavra(client, aluno):
    await seed_vocabulario()
    h = aluno["headers"]
    mapa = await _mapa_palavras(client, h)
    alvo = mapa["belo"]
    await _em_progresso(aluno["usuario_id"], alvo, estado="nivel_4", nivel4=0)

    sessao = (await client.post("/v1/sessoes", headers=h)).json()
    n4 = next(
        s for s in _questoes(sessao["slots"])
        if s["palavra_id"] == alvo and s["nivel"] == 4
    )
    correta = await _resposta_correta(n4["questao_id"])

    r = await client.post(
        f"/v1/sessoes/{sessao['sessao_id']}/respostas",
        headers=h,
        json={"questao_id": n4["questao_id"], "opcao": correta},
    )
    b = r.json()
    assert b["dominou"] is True
    assert b["estado_palavra"] == "dominada"
    assert b["xp_ganho"] >= 600  # 100 + combo + 500 de domínio


# ───────────────────────────────── fim ─────────────────────────────────


@pytest.mark.asyncio
async def test_fim_requer_auth(client):
    r = await client.post("/v1/sessoes/1/fim")
    assert r.status_code == 401


@pytest.mark.asyncio
async def test_fim_resume_e_encerra(client, aluno):
    await seed_vocabulario()
    h = aluno["headers"]
    sessao = (await client.post("/v1/sessoes", headers=h)).json()
    sid = sessao["sessao_id"]
    q1 = _primeira_questao(sessao["slots"], nivel=1)
    correta = await _resposta_correta(q1["questao_id"])
    await client.post(
        f"/v1/sessoes/{sid}/respostas",
        headers=h,
        json={"questao_id": q1["questao_id"], "opcao": correta},
    )

    r = await client.post(f"/v1/sessoes/{sid}/fim", headers=h)
    assert r.status_code == 200, r.text
    b = r.json()
    assert b["xp_ganho"] == 120          # XP atribuído à sessão
    assert b["sessoes_total"] == 1
    assert b["nivel_mudou"] is False     # sem janela de sinal ainda

    # encerrar de novo → 409
    de_novo = await client.post(f"/v1/sessoes/{sid}/fim", headers=h)
    assert de_novo.status_code == 409
    assert de_novo.json()["error"]["code"] == "sessao_encerrada"


@pytest.mark.asyncio
async def test_adaptacao_sobe_nivel_com_acuracia_alta(client, aluno):
    await seed_vocabulario()
    h = aluno["headers"]
    sid = (await client.post("/v1/sessoes", headers=h)).json()["sessao_id"]

    await _definir_nivel(aluno["usuario_id"], 2)
    await _semear_respostas_no_nivel(aluno["usuario_id"], nivel=2, acertos=10, total=10)

    b = (await client.post(f"/v1/sessoes/{sid}/fim", headers=h)).json()
    assert b["nivel_anterior"] == 2
    assert b["nivel_atual"] == 3
    assert b["nivel_mudou"] is True


@pytest.mark.asyncio
async def test_adaptacao_desce_nivel_com_acuracia_baixa(client, aluno):
    await seed_vocabulario()
    h = aluno["headers"]
    sid = (await client.post("/v1/sessoes", headers=h)).json()["sessao_id"]

    await _definir_nivel(aluno["usuario_id"], 2)
    await _semear_respostas_no_nivel(aluno["usuario_id"], nivel=2, acertos=0, total=10)

    b = (await client.post(f"/v1/sessoes/{sid}/fim", headers=h)).json()
    assert b["nivel_atual"] == 1
    assert b["nivel_mudou"] is True


@pytest.mark.asyncio
async def test_adaptacao_nao_move_com_janela_incompleta(client, aluno):
    await seed_vocabulario()
    h = aluno["headers"]
    sid = (await client.post("/v1/sessoes", headers=h)).json()["sessao_id"]

    await _definir_nivel(aluno["usuario_id"], 2)
    await _semear_respostas_no_nivel(aluno["usuario_id"], nivel=2, acertos=5, total=5)

    b = (await client.post(f"/v1/sessoes/{sid}/fim", headers=h)).json()
    assert b["nivel_mudou"] is False
    assert b["nivel_atual"] == 2  # histerese: janela < 10 não move
