"""Leitura do banco de vocabulário + integridade do seed do banco base."""
import pytest

from app.seed_vocabulario import PALAVRAS, seed_vocabulario


@pytest.mark.asyncio
async def test_palavras_exige_autenticacao(client):
    r = await client.get("/v1/palavras")
    assert r.status_code == 401
    assert r.json()["error"]["code"] == "nao_autenticado"


@pytest.mark.asyncio
async def test_listar_palavras(client, auth_headers):
    res = await seed_vocabulario()
    assert res["palavras_inseridas"] == len(PALAVRAS)

    # limit alto para trazer o banco base inteiro numa página (o default pagina em 20)
    r = await client.get("/v1/palavras?limit=100", headers=auth_headers)
    assert r.status_code == 200, r.text
    body = r.json()
    assert len(body["items"]) == len(PALAVRAS)
    assert body["next_cursor"] is None
    primeiro = body["items"][0]
    assert {"id", "lema", "nivel_dificuldade"} == set(primeiro)


@pytest.mark.asyncio
async def test_seed_e_idempotente(client, auth_headers):
    """Rodar o seed de novo (ex.: na segunda máquina após um git pull) não
    duplica nada: a 2ª chamada insere 0 e o banco base fica idêntico. É o que
    garante o mesmo vocabulário reproduzido em qualquer máquina."""
    primeira = await seed_vocabulario()
    assert primeira["palavras_inseridas"] == len(PALAVRAS)

    segunda = await seed_vocabulario()
    assert segunda["palavras_inseridas"] == 0
    assert segunda["questoes_inseridas"] == 0

    body = (await client.get("/v1/palavras?limit=100", headers=auth_headers)).json()
    assert len(body["items"]) == len(PALAVRAS)  # sem duplicatas


@pytest.mark.asyncio
async def test_paginacao_por_cursor(client, auth_headers):
    await seed_vocabulario()

    pagina1 = (await client.get("/v1/palavras?limit=3", headers=auth_headers)).json()
    assert len(pagina1["items"]) == 3
    assert pagina1["next_cursor"] is not None

    pagina2 = (
        await client.get(
            f"/v1/palavras?limit=3&cursor={pagina1['next_cursor']}", headers=auth_headers
        )
    ).json()
    ids1 = {i["id"] for i in pagina1["items"]}
    ids2 = {i["id"] for i in pagina2["items"]}
    assert ids1.isdisjoint(ids2)  # páginas não se sobrepõem


@pytest.mark.asyncio
async def test_cursor_invalido(client, auth_headers):
    await seed_vocabulario()
    r = await client.get("/v1/palavras?cursor=abc", headers=auth_headers)
    assert r.status_code == 400
    assert r.json()["error"]["code"] == "cursor_invalido"


@pytest.mark.asyncio
async def test_detalhe_palavra_traz_card_sem_respostas(client, auth_headers):
    await seed_vocabulario()
    lista = (await client.get("/v1/palavras", headers=auth_headers)).json()
    palavra_id = lista["items"][0]["id"]

    r = await client.get(f"/v1/palavras/{palavra_id}", headers=auth_headers)
    assert r.status_code == 200, r.text
    card = r.json()
    assert card["definicao"]
    assert card["exemplo_uso"]
    assert len(card["sinonimos"]) >= 2
    # O card jamais expõe questões/resposta correta.
    assert "questoes" not in card
    assert "resposta_correta" not in r.text


@pytest.mark.asyncio
async def test_detalhe_palavra_inexistente(client, auth_headers):
    r = await client.get("/v1/palavras/999999", headers=auth_headers)
    assert r.status_code == 404
    assert r.json()["error"]["code"] == "palavra_nao_encontrada"
