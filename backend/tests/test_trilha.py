"""Trilha: mapa, passaporte e o loop de recompensa (cartão/carimbo/selo)."""
import pytest
from sqlalchemy import select, update

from app import schema
from app.db import engine
from app.seed_trilha import seed_trilha
from app.seed_vocabulario import seed_vocabulario


async def _correta(questao_id) -> str:
    async with engine.begin() as conn:
        return (
            await conn.execute(
                select(schema.questao.c.resposta_correta).where(
                    schema.questao.c.id == questao_id
                )
            )
        ).scalar_one()


async def _set_progresso(usuario_id, **valores):
    async with engine.begin() as conn:
        await conn.execute(
            update(schema.aluno_progresso)
            .where(schema.aluno_progresso.c.usuario_id == usuario_id)
            .values(**valores)
        )


async def _responder_questoes_n1(client, headers, quantidade=1, corretas=True):
    """Abre uma sessão e responde as primeiras `quantidade` questões N1."""
    sessao = (await client.post("/v1/sessoes", headers=headers)).json()
    n1 = [s for s in sessao["slots"] if s["tipo"] == "questao" and s["nivel"] == 1]
    respostas = []
    for q in n1[:quantidade]:
        cor = await _correta(q["questao_id"])
        op = cor if corretas else next(o for o in q["opcoes"] if o != cor)
        r = await client.post(
            f"/v1/sessoes/{sessao['sessao_id']}/respostas",
            headers=headers,
            json={"questao_id": q["questao_id"], "opcao": op},
        )
        respostas.append(r.json())
    return respostas


@pytest.mark.asyncio
async def test_trilha_e_passaporte_exigem_auth(client):
    assert (await client.get("/v1/trilha")).status_code == 401
    assert (await client.get("/v1/passaporte")).status_code == 401


@pytest.mark.asyncio
async def test_mapa_aluno_novo(client, aluno):
    await seed_trilha()
    m = (await client.get("/v1/trilha", headers=aluno["headers"])).json()
    assert m["xp_total"] == 0
    assert len(m["paises"]) == 3
    assert m["no_atual"]["no_ordem"] == 1
    assert m["no_atual"]["pais_nome"] == "Brasil"
    assert "Rio" in m["no_atual"]["destino_nome"]
    assert all(not d["concluido"] for p in m["paises"] for d in p["destinos"])


@pytest.mark.asyncio
async def test_passaporte_aluno_novo(client, aluno):
    await seed_trilha()
    p = (await client.get("/v1/passaporte", headers=aluno["headers"])).json()
    assert p["total"] == 28
    assert p["conquistados"] == 0
    assert all(not i["conquistado"] for i in p["itens"])
    assert all(not i["revelado"] for i in p["itens"])


@pytest.mark.asyncio
async def test_revelar_item_conquistado(client, aluno):
    """Fluxo do Modo Conquista: ganha → aparece pendente → revela → some da fila."""
    await seed_trilha()
    await seed_vocabulario()
    await _set_progresso(aluno["usuario_id"], xp_total=17900)
    await _responder_questoes_n1(client, aluno["headers"], 1)

    h = aluno["headers"]
    p = (await client.get("/v1/passaporte", headers=h)).json()
    pendente = next(i for i in p["itens"] if i["conquistado"])
    assert not pendente["revelado"]

    r = await client.post(f"/v1/passaporte/{pendente['id']}/revelado", headers=h)
    assert r.status_code == 200
    assert r.json() == {"revelado": True, "colecionavel_id": pendente["id"]}

    # Idempotente: repetir o POST (retry de rede) não erra nem duplica.
    r2 = await client.post(f"/v1/passaporte/{pendente['id']}/revelado", headers=h)
    assert r2.status_code == 200

    p2 = (await client.get("/v1/passaporte", headers=h)).json()
    item = next(i for i in p2["itens"] if i["id"] == pendente["id"])
    assert item["revelado"]


@pytest.mark.asyncio
async def test_revelar_item_nao_conquistado_e_404(client, aluno):
    await seed_trilha()
    p = (await client.get("/v1/passaporte", headers=aluno["headers"])).json()
    r = await client.post(
        f"/v1/passaporte/{p['itens'][0]['id']}/revelado", headers=aluno["headers"]
    )
    assert r.status_code == 404
    assert r.json()["error"]["code"] == "item_nao_conquistado"


@pytest.mark.asyncio
async def test_fechar_destino_concede_cartao(client, aluno):
    await seed_trilha()
    await seed_vocabulario()
    # XP logo abaixo do último nó do 1º destino (4º nó = 18000).
    await _set_progresso(aluno["usuario_id"], xp_total=17900)

    r = (await _responder_questoes_n1(client, aluno["headers"], 1))[0]
    cartoes = [c for c in r["recompensas"] if c["tipo"] == "cartao_postal"]
    assert len(cartoes) == 1
    assert cartoes[0]["referencia"] == "destino:1"  # Rio

    p = (await client.get("/v1/passaporte", headers=aluno["headers"])).json()
    assert p["conquistados"] == 1


@pytest.mark.asyncio
async def test_fechar_pais_concede_cartao_e_carimbo(client, aluno):
    await seed_trilha()
    await seed_vocabulario()
    # XP logo abaixo do último nó do Brasil (20º nó = 90000).
    await _set_progresso(aluno["usuario_id"], xp_total=89900)

    r = (await _responder_questoes_n1(client, aluno["headers"], 1))[0]
    tipos = {c["tipo"] for c in r["recompensas"]}
    assert "cartao_postal" in tipos
    assert "carimbo" in tipos
    carimbo = next(c for c in r["recompensas"] if c["tipo"] == "carimbo")
    assert carimbo["referencia"] == "pais:1"  # Brasil


@pytest.mark.asyncio
async def test_combo_10_concede_selo_e_e_idempotente(client, aluno):
    await seed_trilha()
    await seed_vocabulario()
    # O combo é por sessão (zera ao abrir): a sessão precisa estar aberta ANTES
    # de posicionar o combo a um acerto de chegar a 10.
    sessao = (await client.post("/v1/sessoes", headers=aluno["headers"])).json()
    await _set_progresso(aluno["usuario_id"], combo_atual=9)

    n1 = [s for s in sessao["slots"] if s["tipo"] == "questao" and s["nivel"] == 1]
    respostas = []
    for q in n1[:2]:
        cor = await _correta(q["questao_id"])
        r = await client.post(
            f"/v1/sessoes/{sessao['sessao_id']}/respostas",
            headers=aluno["headers"],
            json={"questao_id": q["questao_id"], "opcao": cor},
        )
        respostas.append(r.json())
    selos_1 = [c for c in respostas[0]["recompensas"] if c["tipo"] == "selo"]
    assert any(c["referencia"] == "feito:combo_10" for c in selos_1)
    assert respostas[0]["combo_atual"] == 10

    # 2ª resposta (combo 11): o selo não é concedido de novo.
    selos_2 = [c for c in respostas[1]["recompensas"] if c["referencia"] == "feito:combo_10"]
    assert selos_2 == []


@pytest.mark.asyncio
async def test_mapa_reflete_conclusao_de_destino(client, aluno):
    await seed_trilha()
    await seed_vocabulario()
    await _set_progresso(aluno["usuario_id"], xp_total=17900)
    await _responder_questoes_n1(client, aluno["headers"], 1)

    m = (await client.get("/v1/trilha", headers=aluno["headers"])).json()
    brasil = next(p for p in m["paises"] if p["nome"] == "Brasil")
    assert brasil["destinos"][0]["concluido"] is True
    assert brasil["destinos"][0]["atual"] is False
    # "você está aqui" andou para o 2º destino do Brasil.
    assert m["no_atual"]["destino_nome"].startswith("Foz")
