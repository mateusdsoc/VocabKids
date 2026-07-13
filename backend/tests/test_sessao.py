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


async def _semear_respostas_no_nivel(usuario_id, nivel, acertos, total, conta_sinal=True):
    """Insere `total` respostas de questões de palavras nesse nível; `acertos`
    delas como acerto de 1ª tentativa. `conta_sinal` marca se contam para a
    adaptação (introdução) ou não (revisão)."""
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
                    conta_sinal=conta_sinal,
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
    # Toda questão identifica a palavra trabalhada (o app destaca/rotula por ela).
    assert all(s["lema"] for s in _questoes(slots))
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
async def test_montar_encerra_sessao_aberta_anterior(client, aluno):
    """Achado 2: abrir uma nova sessão encerra a anterior aberta (no máx. uma
    sessão ativa por aluno). A sessão velha abandonada não aceita mais respostas;
    a nova funciona normalmente."""
    await seed_vocabulario()
    h = aluno["headers"]
    s1 = (await client.post("/v1/sessoes", headers=h)).json()
    s2 = (await client.post("/v1/sessoes", headers=h)).json()
    assert s2["sessao_id"] != s1["sessao_id"]

    # A sessão antiga foi encerrada ao montar a nova → 409 sessao_encerrada.
    q1 = _primeira_questao(s1["slots"], nivel=1)
    correta = await _resposta_correta(q1["questao_id"])
    r = await client.post(
        f"/v1/sessoes/{s1['sessao_id']}/respostas",
        headers=h,
        json={"questao_id": q1["questao_id"], "opcao": correta},
    )
    assert r.status_code == 409
    assert r.json()["error"]["code"] == "sessao_encerrada"

    # A nova sessão responde normalmente.
    q2 = _primeira_questao(s2["slots"], nivel=1)
    correta2 = await _resposta_correta(q2["questao_id"])
    ok = await client.post(
        f"/v1/sessoes/{s2['sessao_id']}/respostas",
        headers=h,
        json={"questao_id": q2["questao_id"], "opcao": correta2},
    )
    assert ok.status_code == 200


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
async def test_abrir_sessao_zera_o_combo(client, aluno):
    """Combo é por sessão (3.7): não carrega da sessão anterior."""
    await seed_vocabulario()
    h = aluno["headers"]

    # 1ª sessão: um acerto de 1ª tentativa deixa combo = 1.
    s1 = (await client.post("/v1/sessoes", headers=h)).json()
    q1 = _primeira_questao(s1["slots"], nivel=1)
    correta = await _resposta_correta(q1["questao_id"])
    b1 = (
        await client.post(
            f"/v1/sessoes/{s1['sessao_id']}/respostas",
            headers=h,
            json={"questao_id": q1["questao_id"], "opcao": correta},
        )
    ).json()
    assert b1["combo_atual"] == 1

    # 2ª sessão: o combo recomeça do zero (1º acerto → combo 1, não 2).
    s2 = (await client.post("/v1/sessoes", headers=h)).json()
    q2 = _primeira_questao(s2["slots"], nivel=1)
    correta2 = await _resposta_correta(q2["questao_id"])
    b2 = (
        await client.post(
            f"/v1/sessoes/{s2['sessao_id']}/respostas",
            headers=h,
            json={"questao_id": q2["questao_id"], "opcao": correta2},
        )
    ).json()
    assert b2["combo_atual"] == 1
    assert b2["xp_ganho"] == 120  # bônus de combo na posição 1, não acumulado


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
async def test_respostas_concorrentes_nao_duplicam_xp(client, aluno):
    """Achado 1: o row lock no `responder` serializa respostas concorrentes do
    mesmo aluno. Duas respostas simultâneas à mesma questão → exatamente uma
    pontua (200), a outra cai na guarda de idempotência (409). Sem o lock, ambas
    leem `aluno_questao` vazio e contam XP/combo em dobro."""
    import asyncio

    await seed_vocabulario()
    h = aluno["headers"]
    sessao = (await client.post("/v1/sessoes", headers=h)).json()
    sid = sessao["sessao_id"]
    q1 = _primeira_questao(sessao["slots"], nivel=1)
    correta = await _resposta_correta(q1["questao_id"])

    corpo = {"questao_id": q1["questao_id"], "opcao": correta}
    r1, r2 = await asyncio.gather(
        client.post(f"/v1/sessoes/{sid}/respostas", headers=h, json=corpo),
        client.post(f"/v1/sessoes/{sid}/respostas", headers=h, json=corpo),
    )

    assert sorted([r1.status_code, r2.status_code]) == [200, 409], (
        r1.status_code,
        r2.status_code,
    )
    ok = r1 if r1.status_code == 200 else r2
    falha = r2 if r1.status_code == 200 else r1
    assert ok.json()["xp_total"] == 120  # contou uma vez (120), não 240
    assert ok.json()["combo_atual"] == 1
    assert falha.json()["error"]["code"] == "questao_ja_respondida"

    # O XP atribuído à sessão também conta uma só vez (somar_xp_sessao é relativo).
    fim = (await client.post(f"/v1/sessoes/{sid}/fim", headers=h)).json()
    assert fim["xp_ganho"] == 120
    assert fim["xp_total"] == 120


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


@pytest.mark.asyncio
async def test_nao_responde_questao_fora_da_fila(client, aluno):
    """Servidor autoritativo: questão que a montagem não pôs na fila (e sem
    tentativa anterior) → 409, mesmo sendo de palavra atribuída ao aluno."""
    await seed_vocabulario()
    h = aluno["headers"]
    sessao = (await client.post("/v1/sessoes", headers=h)).json()
    na_fila = {s["questao_id"] for s in _questoes(sessao["slots"])}
    palavras = {s["palavra_id"] for s in _questoes(sessao["slots"])}

    # Uma questão dessas palavras que ficou fora da fila (ex.: outra variação,
    # ou o N4 que só entra quando o agendamento vence).
    async with engine.begin() as conn:
        fora = (
            await conn.execute(
                select(schema.questao.c.id)
                .where(
                    schema.questao.c.palavra_id.in_(palavras),
                    schema.questao.c.id.notin_(na_fila),
                )
                .limit(1)
            )
        ).scalar_one()
    correta = await _resposta_correta(fora)

    r = await client.post(
        f"/v1/sessoes/{sessao['sessao_id']}/respostas",
        headers=h,
        json={"questao_id": fora, "opcao": correta},
    )
    assert r.status_code == 409
    assert r.json()["error"]["code"] == "questao_fora_da_sessao"


@pytest.mark.asyncio
async def test_n4_com_agendamento_futuro_nao_domina(client, aluno):
    """Guarda do bônus de domínio: responder um N4 cujo agendamento ainda não
    venceu → 409 (sem farmar o +500), mesmo com a questão em mãos."""
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
    # Empurra o agendamento para o futuro depois da montagem — o estado que a
    # guarda do `responder` precisa rejeitar por conta própria.
    async with engine.begin() as conn:
        await conn.execute(
            update(schema.aluno_palavra)
            .where(
                schema.aluno_palavra.c.usuario_id == aluno["usuario_id"],
                schema.aluno_palavra.c.palavra_id == alvo,
            )
            .values(nivel4_agendado_para=99)
        )
    correta = await _resposta_correta(n4["questao_id"])

    r = await client.post(
        f"/v1/sessoes/{sessao['sessao_id']}/respostas",
        headers=h,
        json={"questao_id": n4["questao_id"], "opcao": correta},
    )
    assert r.status_code == 409
    assert r.json()["error"]["code"] == "nivel4_nao_vencido"


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


@pytest.mark.asyncio
async def test_adaptacao_conta_nivel_vizinho_quando_banco_esparso(client, aluno):
    """Achado 3: com o banco esparso a seleção puxa palavras de nível vizinho; o
    sinal conta o nível ±1 (tolerância) para não morrer de fome. Aluno no nível 3
    com 10 acertos de 1ª em questões de nível 2 (vizinho) sobe para 4. Sem a
    tolerância, o filtro de nível exato deixaria a janela vazia e nada mudaria."""
    await seed_vocabulario()
    h = aluno["headers"]
    sid = (await client.post("/v1/sessoes", headers=h)).json()["sessao_id"]

    await _definir_nivel(aluno["usuario_id"], 3)
    await _semear_respostas_no_nivel(aluno["usuario_id"], nivel=2, acertos=10, total=10)

    b = (await client.post(f"/v1/sessoes/{sid}/fim", headers=h)).json()
    assert b["nivel_anterior"] == 3
    assert b["nivel_mudou"] is True
    assert b["nivel_atual"] == 4  # o nível vizinho (2) contou no sinal


@pytest.mark.asyncio
async def test_adaptacao_ignora_revisao_no_sinal(client, aluno):
    """Sinal limpo: respostas de revisão (conta_sinal=False) não contam — mesmo
    com 10 acertos de revisão, o nível não sobe."""
    await seed_vocabulario()
    h = aluno["headers"]
    sid = (await client.post("/v1/sessoes", headers=h)).json()["sessao_id"]

    await _definir_nivel(aluno["usuario_id"], 2)
    await _semear_respostas_no_nivel(
        aluno["usuario_id"], nivel=2, acertos=10, total=10, conta_sinal=False
    )

    b = (await client.post(f"/v1/sessoes/{sid}/fim", headers=h)).json()
    assert b["nivel_mudou"] is False
    assert b["nivel_atual"] == 2  # revisão não infla o sinal


# ───────────── intercalação server-side (3.4, decisão #3 revisada) ─────────────


def _fila_questoes(fila):
    return [s for s in fila if s["tipo"] == "questao"]


@pytest.mark.asyncio
async def test_acerto_remove_o_slot_da_fila(client, aluno):
    await seed_vocabulario()
    h = aluno["headers"]
    sessao = (await client.post("/v1/sessoes", headers=h)).json()
    q1 = _primeira_questao(sessao["slots"], nivel=1)
    correta = await _resposta_correta(q1["questao_id"])

    b = (
        await client.post(
            f"/v1/sessoes/{sessao['sessao_id']}/respostas",
            headers=h,
            json={"questao_id": q1["questao_id"], "opcao": correta},
        )
    ).json()

    ids = [s["questao_id"] for s in _fila_questoes(b["fila"])]
    assert q1["questao_id"] not in ids
    assert len(b["fila"]) < len(sessao["slots"])  # slot (e card visto) saíram
    assert b["proximo"] == b["fila"][0]


@pytest.mark.asyncio
async def test_erro_intercala_outra_variacao_no_fim(client, aluno):
    await seed_vocabulario()
    h = aluno["headers"]
    sessao = (await client.post("/v1/sessoes", headers=h)).json()
    q1 = _primeira_questao(sessao["slots"], nivel=1)
    correta = await _resposta_correta(q1["questao_id"])
    errada = next(o for o in q1["opcoes"] if o != correta)

    b = (
        await client.post(
            f"/v1/sessoes/{sessao['sessao_id']}/respostas",
            headers=h,
            json={"questao_id": q1["questao_id"], "opcao": errada},
        )
    ).json()

    fila = b["fila"]
    retry = fila[-1]
    assert retry["tipo"] == "questao"
    assert retry["palavra_id"] == q1["palavra_id"]
    assert retry["nivel"] == q1["nivel"]
    assert retry["questao_id"] != q1["questao_id"]  # outra variação (seed tem ≥2)
    # o slot original saiu da posição (não está duplicado no meio)
    ids = [s["questao_id"] for s in _fila_questoes(fila)]
    assert ids.count(q1["questao_id"]) == 0


@pytest.mark.asyncio
async def test_proximo_devolve_o_primeiro_slot_pendente(client, aluno):
    await seed_vocabulario()
    h = aluno["headers"]
    sessao = (await client.post("/v1/sessoes", headers=h)).json()
    sid = sessao["sessao_id"]

    p = (await client.get(f"/v1/sessoes/{sid}/proximo", headers=h)).json()
    assert p["restantes"] == len(sessao["slots"])
    assert p["proximo"]["tipo"] == sessao["slots"][0]["tipo"]

    # após responder, o próximo acompanha a fila reordenada
    q1 = _primeira_questao(sessao["slots"], nivel=1)
    correta = await _resposta_correta(q1["questao_id"])
    b = (
        await client.post(
            f"/v1/sessoes/{sid}/respostas",
            headers=h,
            json={"questao_id": q1["questao_id"], "opcao": correta},
        )
    ).json()
    p2 = (await client.get(f"/v1/sessoes/{sid}/proximo", headers=h)).json()
    assert p2["restantes"] == len(b["fila"])
    assert p2["proximo"] == b["proximo"]
