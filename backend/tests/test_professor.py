"""Professor — telas mockadas (fatia A). Smoke: exige auth e devolve o shape.

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


@pytest.mark.asyncio
async def test_listar_turmas(client, auth_headers):
    r = await client.get("/v1/professor/turmas", headers=auth_headers)
    assert r.status_code == 200
    b = r.json()
    assert b["mock"] is True
    assert len(b["turmas"]) >= 1
    assert {"id", "nome", "ano_escolar", "alunos_ativos", "meta_semanal"} <= b[
        "turmas"
    ][0].keys()


@pytest.mark.asyncio
async def test_painel_turma(client, auth_headers):
    r = await client.get("/v1/professor/turmas/1/painel", headers=auth_headers)
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
async def test_painel_turma_inexistente(client, auth_headers):
    r = await client.get("/v1/professor/turmas/999/painel", headers=auth_headers)
    assert r.status_code == 404


@pytest.mark.asyncio
async def test_painel_escola(client, auth_headers):
    r = await client.get("/v1/professor/escola", headers=auth_headers)
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
async def test_detalhe_aluno(client, auth_headers):
    r = await client.get("/v1/professor/alunos/1", headers=auth_headers)
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
async def test_detalhe_aluno_inexistente(client, auth_headers):
    r = await client.get("/v1/professor/alunos/999", headers=auth_headers)
    assert r.status_code == 404


@pytest.mark.asyncio
async def test_atribuir_redacao(client, auth_headers):
    r = await client.post(
        "/v1/professor/turmas/1/redacoes",
        headers=auth_headers,
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
async def test_atribuir_redacao_sem_prazo(client, auth_headers):
    r = await client.post(
        "/v1/professor/turmas/1/redacoes",
        headers=auth_headers,
        json={"tema": "Minhas férias dos sonhos"},
    )
    assert r.status_code == 201
    assert r.json()["prazo"] is None


@pytest.mark.asyncio
async def test_atribuir_redacao_turma_inexistente(client, auth_headers):
    r = await client.post(
        "/v1/professor/turmas/999/redacoes",
        headers=auth_headers,
        json={"tema": "Tema qualquer"},
    )
    assert r.status_code == 404


@pytest.mark.asyncio
async def test_atribuir_redacao_tema_vazio_e_prazo_invalido(client, auth_headers):
    vazio = await client.post(
        "/v1/professor/turmas/1/redacoes", headers=auth_headers, json={"tema": "   "}
    )
    assert vazio.status_code == 422
    prazo = await client.post(
        "/v1/professor/turmas/1/redacoes",
        headers=auth_headers,
        json={"tema": "Ok", "prazo": "30/06/2026"},
    )
    assert prazo.status_code == 422
