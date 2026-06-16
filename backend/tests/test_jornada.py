"""Jornada end-to-end da fatia A — um aluno de verdade, do acesso ao passaporte.

Diferente dos testes por módulo (que semeiam estado direto), este joga a sequência
inteira pela API, pegando bugs de integração e servindo de documentação viva do
fluxo que o app Flutter vai seguir.
"""
import pytest
from sqlalchemy import select

from app import schema
from app.db import engine
from app.seed import seed
from app.seed_trilha import seed_trilha
from app.seed_vocabulario import seed_vocabulario


async def _gabarito() -> dict[int, str]:
    """Mapa questao_id → resposta_correta (atalho de teste, não exposto pela API)."""
    async with engine.begin() as conn:
        rows = (
            await conn.execute(
                select(schema.questao.c.id, schema.questao.c.resposta_correta)
            )
        ).all()
    return {qid: correta for qid, correta in rows}


@pytest.mark.asyncio
async def test_jornada_completa_do_apresentavel(client):
    await seed()
    await seed_vocabulario()
    await seed_trilha()
    gabarito = await _gabarito()

    # 1. Acesso por código de turma.
    acesso = (
        await client.post(
            "/v1/acesso/turma", json={"codigo_turma": "DEMO7A", "nome": "Joana"}
        )
    ).json()
    h = {"Authorization": f"Bearer {acesso['token']}"}
    assert acesso["novo"] is True

    # 2. Diagnóstico (respondendo sempre certo → nível alto).
    diag = (await client.post("/v1/onboarding/diagnostico", headers=h, json={})).json()
    perguntas = 0
    while not diag["concluido"]:
        q = diag["questao"]
        assert "resposta_correta" not in q  # nunca vaza no diagnóstico
        diag = (
            await client.post(
                "/v1/onboarding/diagnostico",
                headers=h,
                json={
                    "estado": diag["estado"],
                    "questao_id": q["questao_id"],
                    "opcao": gabarito[q["questao_id"]],
                },
            )
        ).json()
        perguntas += 1
    assert perguntas <= 15
    nivel_diag = diag["nivel_dificuldade_atual"]
    assert nivel_diag >= 5

    # 3. /me reflete o nível diagnosticado.
    me = (await client.get("/v1/me", headers=h)).json()
    assert me["progresso"]["nivel_dificuldade_atual"] == nivel_diag
    assert me["papel"] == "aluno"

    # 4. Abre uma sessão.
    sessao = (await client.post("/v1/sessoes", headers=h)).json()
    sid = sessao["sessao_id"]
    cards = [s for s in sessao["slots"] if s["tipo"] == "card"]
    questoes = [s for s in sessao["slots"] if s["tipo"] == "questao"]
    assert cards and questoes
    assert "resposta_correta" not in str(sessao)  # fila não vaza resposta

    # 5. Responde tudo certo (caminho feliz: avança estados, ganha XP/combo).
    xp_acumulado = 0
    palavras_que_avancaram = set()
    for q in questoes:
        r = (
            await client.post(
                f"/v1/sessoes/{sid}/respostas",
                headers=h,
                json={"questao_id": q["questao_id"], "opcao": gabarito[q["questao_id"]]},
            )
        ).json()
        assert r["correto"] is True
        assert r["xp_ganho"] > 0
        xp_acumulado = r["xp_total"]
        palavras_que_avancaram.add(q["palavra_id"])
    assert xp_acumulado > 0

    # 6. Fecha a sessão → resumo + adaptação.
    resumo = (await client.post(f"/v1/sessoes/{sid}/fim", headers=h)).json()
    assert resumo["sessoes_total"] == 1
    assert resumo["xp_ganho"] == xp_acumulado
    # Encerrar de novo não é permitido.
    assert (await client.post(f"/v1/sessoes/{sid}/fim", headers=h)).status_code == 409

    # 7. Trilha reflete o XP; "você está aqui" presente.
    trilha = (await client.get("/v1/trilha", headers=h)).json()
    assert trilha["xp_total"] == xp_acumulado
    assert trilha["no_atual"] is not None
    assert len(trilha["paises"]) == 3

    # 8. Passaporte com os 28 itens (silhuetas).
    passaporte = (await client.get("/v1/passaporte", headers=h)).json()
    assert passaporte["total"] == 28

    # 9. Telas mockadas da fatia A respondem.
    redacoes = (await client.get("/v1/redacoes", headers=h)).json()
    assert redacoes["mock"] is True and len(redacoes["itens"]) >= 1
    # O painel saiu de /dashboard para o domínio professor (telas §8.2).
    painel = (await client.get("/v1/professor/turmas/1/painel", headers=h)).json()
    assert painel["mock"] is True
    rep = await client.post(
        f"/v1/questoes/{questoes[0]['questao_id']}/report",
        headers=h,
        json={"motivo": "nao_entendi"},
    )
    assert rep.status_code == 200 and rep.json()["recebido"] is True

    # 10. Segunda sessão: continuidade (não reintroduz as mesmas palavras novas).
    sessao2 = (await client.post("/v1/sessoes", headers=h)).json()
    cards2 = {s["palavra"]["id"] for s in sessao2["slots"] if s["tipo"] == "card"}
    cards1 = {c["palavra"]["id"] for c in cards}
    assert cards1.isdisjoint(cards2)


@pytest.mark.asyncio
async def test_report_valida_motivo(client, aluno):
    r = await client.post(
        "/v1/questoes/1/report", headers=aluno["headers"], json={"motivo": "inexistente"}
    )
    assert r.status_code == 422
    assert r.json()["error"]["code"] == "validation_error"
