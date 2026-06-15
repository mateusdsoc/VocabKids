"""Professor — telas mockadas (fatia A). Smoke: exige auth e devolve o shape.

Como os demais, exige Postgres (a dependency de auth resolve um usuário real).
"""
import pytest


@pytest.mark.asyncio
async def test_professor_exige_auth(client):
    assert (await client.get("/v1/professor/turmas")).status_code == 401
    assert (await client.get("/v1/professor/turmas/1/painel")).status_code == 401
    assert (await client.get("/v1/professor/escola")).status_code == 401


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
