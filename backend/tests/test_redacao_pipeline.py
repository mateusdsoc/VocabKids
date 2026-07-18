"""Pipeline de redação (Bloco 2b, fatia 2) — fila + máquina de estados.

A fila roda em memória (conftest) e o worker é executado inline
(`run_worker_async(wait=False)` processa tudo que está enfileirado e retorna).
Os miolos das etapas são stubs na fatia 2; aqui eles são simulados por
monkeypatch para exercitar TODAS as transições — quando as fatias 3–5
trocarem o miolo, estes testes de orquestração continuam valendo.
"""
from sqlalchemy import select

from app import schema
from app.db import engine
from app.fila import fila
from app.redacao import pipeline
from app.redacao import repository as repo
from app.redacao import tarefas

from tests.test_redacao import JPEG, PNG, _atribuir, _fotos

ANOTACOES = {"vocabulario": [{"trecho": "muito", "tipo": "superutilizada"}]}


async def _rodar_fila():
    """Processa tudo que está enfileirado e retorna (worker inline)."""
    await fila.run_worker_async(
        wait=False, install_signal_handlers=False, listen_notify=False
    )


async def _redacao(redacao_id: int):
    async with engine.begin() as conn:
        return await repo.buscar_redacao(conn, redacao_id)


async def _enviar(client, aluno, professor, arquivos=None) -> int:
    aid = await _atribuir(client, professor)
    r = await client.post(
        f"/v1/redacoes/{aid}/envio",
        headers=aluno["headers"],
        files=arquivos or _fotos(JPEG),
    )
    assert r.status_code == 201, r.text
    return r.json()["redacao_id"]


def _simular_miolos(monkeypatch, texto="Meu heroi é muito muito legal."):
    """Ingestão e análise 'reais' de mentira — só para a orquestração andar."""

    async def extrair_texto(formato, paginas):
        assert paginas, "a tarefa deve ler as páginas do storage"
        return texto

    async def analisar(t):
        assert t == texto
        return ANOTACOES

    monkeypatch.setattr(pipeline, "extrair_texto", extrair_texto)
    monkeypatch.setattr(pipeline, "analisar", analisar)


async def test_envio_enfileira_ingestao(client, aluno, professor, fila_em_memoria):
    rid = await _enviar(client, aluno, professor)
    jobs = list(fila_em_memoria.jobs.values())
    assert len(jobs) == 1
    assert jobs[0]["task_name"] == "redacao.ingestao"
    assert jobs[0]["args"] == {"redacao_id": rid}


async def test_stub_para_honesto_em_processando(client, aluno, professor):
    """Sem miolo (fatia 2 pura), o pipeline avança até `processando` e para —
    a tela segue mostrando "em análise", sem resultado inventado."""
    rid = await _enviar(client, aluno, professor)
    await _rodar_fila()
    red = await _redacao(rid)
    assert red.status == "processando"
    assert red.texto_extraido is None


async def test_pipeline_completo_com_miolos_simulados(
    client, aluno, professor, fila_em_memoria, monkeypatch
):
    _simular_miolos(monkeypatch)
    rid = await _enviar(client, aluno, professor, _fotos(JPEG, PNG))
    await _rodar_fila()

    red = await _redacao(rid)
    assert red.status == "analisada"
    assert red.texto_extraido == "Meu heroi é muito muito legal."
    async with engine.begin() as conn:
        analise = await repo.buscar_analise(conn, rid)
        analisada_em = (
            await conn.execute(
                select(schema.redacao.c.analisada_em).where(
                    schema.redacao.c.id == rid
                )
            )
        ).scalar_one()
    assert analise is not None and analise.anotacoes == ANOTACOES
    assert analisada_em is not None

    nomes = [j["task_name"] for j in fila_em_memoria.jobs.values()]
    assert nomes == [
        "redacao.ingestao", "redacao.analise", "redacao.extracao_atribuicao"
    ]


async def test_erro_permanente_de_ingestao(
    client, aluno, professor, fila_em_memoria, monkeypatch
):
    async def ilegivel(formato, paginas):
        raise pipeline.ErroIngestao("foto ilegível")

    monkeypatch.setattr(pipeline, "extrair_texto", ilegivel)
    rid = await _enviar(client, aluno, professor)
    await _rodar_fila()

    red = await _redacao(rid)
    assert red.status == "erro_ingestao"
    # A cadeia parou: análise não foi enfileirada.
    nomes = [j["task_name"] for j in fila_em_memoria.jobs.values()]
    assert nomes == ["redacao.ingestao"]


async def test_erro_permanente_de_analise(client, aluno, professor, monkeypatch):
    _simular_miolos(monkeypatch)

    async def falha(t):
        raise pipeline.ErroAnalise("resposta inválida do modelo")

    monkeypatch.setattr(pipeline, "analisar", falha)
    rid = await _enviar(client, aluno, professor)
    await _rodar_fila()

    red = await _redacao(rid)
    assert red.status == "erro_analise"
    assert red.texto_extraido is not None  # a ingestão ficou registrada


async def test_reenvio_apos_erro_reprocessa(
    client, aluno, professor, monkeypatch
):
    """erro_ingestao não é beco sem saída: o reenvio volta a `enviada`,
    re-enfileira e o pipeline processa o conteúdo novo."""

    async def ilegivel(formato, paginas):
        raise pipeline.ErroIngestao("foto ilegível")

    monkeypatch.setattr(pipeline, "extrair_texto", ilegivel)
    aid = await _atribuir(client, professor)
    h = aluno["headers"]
    r1 = await client.post(f"/v1/redacoes/{aid}/envio", headers=h, files=_fotos(JPEG))
    rid = r1.json()["redacao_id"]
    await _rodar_fila()
    assert (await _redacao(rid)).status == "erro_ingestao"

    # Reenvio com o stub normal (None): deve chegar a `processando`.
    monkeypatch.setattr(pipeline, "extrair_texto", _stub_none)
    r2 = await client.post(f"/v1/redacoes/{aid}/envio", headers=h, files=_fotos(PNG))
    assert r2.status_code == 201
    assert r2.json()["status"] == "enviada"
    await _rodar_fila()
    assert (await _redacao(rid)).status == "processando"


async def _stub_none(formato, paginas):
    return None


async def test_job_atrasado_nao_regride_estado(
    client, aluno, professor, monkeypatch
):
    """Idempotência por status: um job duplicado/atrasado sobre uma redação já
    analisada retorna sem efeito."""
    _simular_miolos(monkeypatch)
    rid = await _enviar(client, aluno, professor)
    await _rodar_fila()
    assert (await _redacao(rid)).status == "analisada"

    await tarefas.ingestao.defer_async(redacao_id=rid)
    await _rodar_fila()
    red = await _redacao(rid)
    assert red.status == "analisada"
    assert red.texto_extraido == "Meu heroi é muito muito legal."


async def test_corrida_com_commit_vira_retry(client, fila_em_memoria):
    """Redação ainda não visível (defer saiu antes do commit da API): a tarefa
    relança e a fila reagenda com backoff — não vira falha definitiva."""
    await tarefas.ingestao.defer_async(redacao_id=999_999)
    await _rodar_fila()
    (job,) = fila_em_memoria.jobs.values()
    assert job["status"] != "failed"
    assert job["attempts"] >= 1
    assert job["scheduled_at"] is not None  # reagendado para o futuro
