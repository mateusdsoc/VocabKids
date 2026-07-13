"""Professor — telas mockadas (fatia A). Smoke: exige auth+papel e devolve o shape.

Como os demais, exige Postgres (a dependency de auth resolve um usuário real).
"""
import pytest


@pytest.mark.asyncio
async def test_professor_exige_auth(client):
    assert (await client.get("/v1/professor/turmas")).status_code == 401
    assert (await client.get("/v1/professor/turmas/1/painel")).status_code == 401
    assert (await client.get("/v1/professor/escola")).status_code == 401
    assert (await client.get("/v1/professor/alunos/1")).status_code == 401
    assert (
        await client.post("/v1/professor/turmas/1/redacoes", json={"tema": "x"})
    ).status_code == 401
    assert (
        await client.put("/v1/professor/turmas/1/meta", json={"meta_semanal": 5})
    ).status_code == 401


@pytest.mark.asyncio
async def test_aluno_nao_acessa_rotas_do_professor(client, auth_headers):
    """Token de aluno é autenticado, mas sem papel — 403 em toda a superfície."""
    respostas = [
        await client.get("/v1/professor/turmas", headers=auth_headers),
        await client.get("/v1/professor/turmas/1/painel", headers=auth_headers),
        await client.get("/v1/professor/escola", headers=auth_headers),
        await client.get("/v1/professor/alunos/1", headers=auth_headers),
        await client.post(
            "/v1/professor/turmas/1/redacoes", headers=auth_headers, json={"tema": "x"}
        ),
        await client.put(
            "/v1/professor/turmas/1/meta", headers=auth_headers, json={"meta_semanal": 5}
        ),
    ]
    for r in respostas:
        assert r.status_code == 403
        assert r.json()["error"]["code"] == "sem_permissao"


@pytest.mark.asyncio
async def test_coordenador_le_mas_nao_configura(client, coordenador):
    """Coordenador é só leitura (§3.11): painéis sim; meta/redação não."""
    h = coordenador["headers"]
    assert (await client.get("/v1/professor/turmas", headers=h)).status_code == 200
    assert (await client.get("/v1/professor/escola", headers=h)).status_code == 200
    meta = await client.put(
        "/v1/professor/turmas/1/meta", headers=h, json={"meta_semanal": 5}
    )
    assert meta.status_code == 403
    redacao = await client.post(
        "/v1/professor/turmas/1/redacoes", headers=h, json={"tema": "Tema"}
    )
    assert redacao.status_code == 403


@pytest.mark.asyncio
async def test_listar_turmas(client, professor):
    r = await client.get("/v1/professor/turmas", headers=professor["headers"])
    assert r.status_code == 200
    b = r.json()
    assert b["mock"] is True
    assert len(b["turmas"]) >= 1
    assert {"id", "nome", "ano_escolar", "alunos_ativos", "meta_semanal"} <= b[
        "turmas"
    ][0].keys()


@pytest.mark.asyncio
async def test_painel_turma(client, professor):
    r = await client.get("/v1/professor/turmas/1/painel", headers=professor["headers"])
    assert r.status_code == 200
    b = r.json()
    assert b["turma_id"] == 1
    assert b["alunos"]
    assert {
        "id",
        "nome",
        "palavras_semana",
        "meta_semana",
        "palavras_dominadas",
    } <= b["alunos"][0].keys()


@pytest.mark.asyncio
async def test_painel_turma_inexistente(client, professor):
    r = await client.get("/v1/professor/turmas/999/painel", headers=professor["headers"])
    assert r.status_code == 404


@pytest.mark.asyncio
async def test_painel_escola(client, professor):
    r = await client.get("/v1/professor/escola", headers=professor["headers"])
    assert r.status_code == 200
    b = r.json()
    assert b["turmas"]
    assert {
        "id",
        "nome",
        "ano_escolar",
        "alunos_ativos",
        "alunos_total",
        "palavras_dominadas_semana",
        "meta_semanal",
    } <= b["turmas"][0].keys()


@pytest.mark.asyncio
async def test_detalhe_aluno(client, professor):
    r = await client.get("/v1/professor/alunos/1", headers=professor["headers"])
    assert r.status_code == 200
    b = r.json()
    # Campos-base vêm do painel (fonte única) — devem coincidir com a turma 1.
    assert b["id"] == 1
    assert b["turma_id"] == 1
    assert b["turma_nome"] == "7º Ano A"
    assert b["palavras_semana"] == 6 and b["meta_semana"] == 5
    assert b["palavras_dominadas"] == 142
    assert b["palavras_em_progresso"] >= 0
    assert {"texto", "estado", "origem"} <= b["palavras"][0].keys()
    assert {"id", "tema", "status", "enviada_em"} <= b["redacoes"][0].keys()


@pytest.mark.asyncio
async def test_detalhe_aluno_inexistente(client, professor):
    r = await client.get("/v1/professor/alunos/999", headers=professor["headers"])
    assert r.status_code == 404


@pytest.mark.asyncio
async def test_atribuir_redacao(client, professor):
    r = await client.post(
        "/v1/professor/turmas/1/redacoes",
        headers=professor["headers"],
        json={"tema": "  Um herói brasileiro  ", "prazo": "2026-06-30"},
    )
    assert r.status_code == 201
    b = r.json()
    assert b["mock"] is True
    assert isinstance(b["id"], int) and b["id"] > 0
    assert b["turma_id"] == 1
    assert b["tema"] == "Um herói brasileiro"  # strip server-side
    assert b["prazo"] == "2026-06-30"


@pytest.mark.asyncio
async def test_atribuir_redacao_sem_prazo(client, professor):
    r = await client.post(
        "/v1/professor/turmas/1/redacoes",
        headers=professor["headers"],
        json={"tema": "Minhas férias dos sonhos"},
    )
    assert r.status_code == 201
    assert r.json()["prazo"] is None


@pytest.mark.asyncio
async def test_atribuir_redacao_turma_inexistente(client, professor):
    r = await client.post(
        "/v1/professor/turmas/999/redacoes",
        headers=professor["headers"],
        json={"tema": "Tema qualquer"},
    )
    assert r.status_code == 404


@pytest.mark.asyncio
async def test_atribuir_redacao_tema_vazio_e_prazo_invalido(client, professor):
    vazio = await client.post(
        "/v1/professor/turmas/1/redacoes", headers=professor["headers"], json={"tema": "   "}
    )
    assert vazio.status_code == 422
    prazo = await client.post(
        "/v1/professor/turmas/1/redacoes",
        headers=professor["headers"],
        json={"tema": "Ok", "prazo": "30/06/2026"},
    )
    assert prazo.status_code == 422


@pytest.mark.asyncio
async def test_atualizar_meta(client, professor):
    r = await client.put(
        "/v1/professor/turmas/1/meta",
        headers=professor["headers"],
        json={"meta_semanal": 8},
    )
    assert r.status_code == 200
    b = r.json()
    assert b["mock"] is True
    assert b["turma_id"] == 1
    assert b["meta_semanal"] == 8


@pytest.mark.asyncio
async def test_atualizar_meta_turma_inexistente(client, professor):
    r = await client.put(
        "/v1/professor/turmas/999/meta",
        headers=professor["headers"],
        json={"meta_semanal": 5},
    )
    assert r.status_code == 404


@pytest.mark.asyncio
async def test_atualizar_meta_fora_da_faixa(client, professor):
    zero = await client.put(
        "/v1/professor/turmas/1/meta", headers=professor["headers"], json={"meta_semanal": 0}
    )
    assert zero.status_code == 422
    alto = await client.put(
        "/v1/professor/turmas/1/meta", headers=professor["headers"], json={"meta_semanal": 99}
    )
    assert alto.status_code == 422
