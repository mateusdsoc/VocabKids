"""Área do Responsável — PIN e resumo semanal (Fase 5, docs/plano_b2c.md §08)."""
from datetime import datetime, timedelta, timezone

import pytest
from sqlalchemy import insert, select, update

from app import schema
from app.db import engine


async def _criar_familia(client, *, ano_nascimento=2015, email="mae@teste.com"):
    cadastro = (
        await client.post(
            "/v1/conta",
            json={
                "nome": "Responsável",
                "email": email,
                "senha": "senha-forte-123",
                "aceite_termos": True,
                "consentimento_lgpd": True,
            },
        )
    ).json()
    h_responsavel = {"Authorization": f"Bearer {cadastro['token']}"}
    perfil = (
        await client.post(
            "/v1/conta/perfis",
            json={"apelido": "Criança", "ano_nascimento": ano_nascimento},
            headers=h_responsavel,
        )
    ).json()
    acesso = (
        await client.post(f"/v1/perfis/{perfil['usuario_id']}/entrar", headers=h_responsavel)
    ).json()
    h_aluno = {"Authorization": f"Bearer {acesso['token']}"}
    return h_responsavel, h_aluno, perfil["usuario_id"]


@pytest.mark.asyncio
async def test_pin_comeca_indefinido_e_pode_ser_definido_e_verificado(client):
    h_responsavel, _, _ = await _criar_familia(client)

    status = (await client.get("/v1/conta/pin", headers=h_responsavel)).json()
    assert status["definido"] is False

    assert (
        await client.post("/v1/conta/pin", headers=h_responsavel, json={"pin": "1234"})
    ).status_code == 204

    status = (await client.get("/v1/conta/pin", headers=h_responsavel)).json()
    assert status["definido"] is True

    ok = await client.post("/v1/conta/pin/verificar", headers=h_responsavel, json={"pin": "1234"})
    assert ok.status_code == 204

    errado = await client.post("/v1/conta/pin/verificar", headers=h_responsavel, json={"pin": "0000"})
    assert errado.status_code == 401
    assert errado.json()["error"]["code"] == "pin_invalido"


@pytest.mark.asyncio
async def test_verificar_pin_sem_pin_definido_falha(client):
    h_responsavel, _, _ = await _criar_familia(client)
    resp = await client.post("/v1/conta/pin/verificar", headers=h_responsavel, json={"pin": "1234"})
    assert resp.status_code == 401


@pytest.mark.asyncio
async def test_pin_rejeita_formato_invalido(client):
    h_responsavel, _, _ = await _criar_familia(client)
    resp = await client.post("/v1/conta/pin", headers=h_responsavel, json={"pin": "12"})
    assert resp.status_code == 422


@pytest.mark.asyncio
async def test_pin_exige_papel_responsavel(client):
    _, h_aluno, _ = await _criar_familia(client)
    resp = await client.post("/v1/conta/pin", headers=h_aluno, json={"pin": "1234"})
    assert resp.status_code == 403


@pytest.mark.asyncio
async def test_resumo_semanal_agrega_meta_minutos_sessoes_palavras_e_redacao(client):
    h_responsavel, h_aluno, usuario_id = await _criar_familia(client)

    agora = datetime.now(timezone.utc)
    async with engine.begin() as conn:
        # 2 sessões concluídas nesta semana: 5 e 10 minutos.
        await conn.execute(
            insert(schema.sessao).values(
                usuario_id=usuario_id,
                iniciada_em=agora - timedelta(minutes=5),
                finalizada_em=agora,
                xp_ganho=100,
            )
        )
        await conn.execute(
            insert(schema.sessao).values(
                usuario_id=usuario_id,
                iniciada_em=agora - timedelta(minutes=10),
                finalizada_em=agora,
                xp_ganho=100,
            )
        )
        # 1 palavra dominada nesta semana.
        palavra_id = (
            await conn.execute(select(schema.palavra.c.id).limit(1))
        ).scalar_one_or_none()
        if palavra_id is None:
            palavra_id = (
                await conn.execute(
                    insert(schema.palavra)
                    .values(
                        lema="destemido",
                        definicao="quem não sente medo",
                        exemplo_uso="O explorador era destemido.",
                        nivel_dificuldade=3,
                        origem="banco_base",
                    )
                    .returning(schema.palavra.c.id)
                )
            ).scalar_one()
        await conn.execute(
            insert(schema.aluno_palavra).values(
                usuario_id=usuario_id,
                palavra_id=palavra_id,
                estado="dominada",
                origem="banco_base",
                dominada_em=agora,
            )
        )

    resumo = (
        await client.get(f"/v1/responsavel/perfis/{usuario_id}/resumo", headers=h_responsavel)
    ).json()
    assert resumo["sessoes_na_semana"] == 2
    assert resumo["minutos_na_semana"] == 15
    assert resumo["palavras_dominadas"]["atual"] == 1
    assert any(p["palavra"] == "destemido" for p in resumo["aprendeu_essa_semana"])
    assert resumo["evolucao_redacao"] == []  # nenhuma redação analisada ainda


@pytest.mark.asyncio
async def test_resumo_semanal_traz_evolucao_de_redacao_analisada(client):
    from app.main import app
    from app.redacao.analisador import AnotacaoAnalise, ResultadoAnalise, get_analisador
    from app.seed_temas import seed_temas

    await seed_temas()
    h_responsavel, h_aluno, usuario_id = await _criar_familia(client, ano_nascimento=2015)

    class _Fake:
        async def analisar(self, *, texto, faixa_etaria, tema):
            return ResultadoAnalise(
                risco_sinalizado=False,
                risco_motivo=None,
                pontos_fortes=["ótimo uso de exemplos"],
                anotacoes=[AnotacaoAnalise(dimensao="vocabulario", titulo="t", comentario="c")],
                niveis_dimensao={"vocabulario": "avançando", "estrutura": "consolidando"},
            )

    app.dependency_overrides[get_analisador] = lambda: _Fake()
    try:
        atribuicao_id = (await client.get("/v1/redacoes", headers=h_aluno)).json()["itens"][0]["id"]
        texto = "uma redação bem completa sobre o tema proposto " * 15  # >= 120 palavras (faixa 11-12)
        envio = (
            await client.post(
                f"/v1/redacoes/{atribuicao_id}/enviar",
                headers=h_aluno,
                json={"formato": "digital", "texto_extraido": texto},
            )
        ).json()
        assert envio["status"] == "analisada"
    finally:
        app.dependency_overrides.pop(get_analisador, None)

    resumo = (
        await client.get(f"/v1/responsavel/perfis/{usuario_id}/resumo", headers=h_responsavel)
    ).json()
    assert len(resumo["evolucao_redacao"]) == 1
    assert resumo["evolucao_redacao"][0]["niveis"] == {
        "vocabulario": "avançando",
        "estrutura": "consolidando",
    }


@pytest.mark.asyncio
async def test_resumo_semanal_exige_perfil_da_propria_conta(client):
    h_responsavel_1, _, _ = await _criar_familia(client, email="familia1@teste.com")
    _, _, usuario_id_2 = await _criar_familia(client, email="familia2@teste.com")

    resp = await client.get(
        f"/v1/responsavel/perfis/{usuario_id_2}/resumo", headers=h_responsavel_1
    )
    assert resp.status_code == 404


@pytest.mark.asyncio
async def test_resumo_semanal_exige_papel_responsavel(client):
    _, h_aluno, usuario_id = await _criar_familia(client)
    resp = await client.get(f"/v1/responsavel/perfis/{usuario_id}/resumo", headers=h_aluno)
    assert resp.status_code == 403
