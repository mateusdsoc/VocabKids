"""Redação (lado do aluno) — lista e envio reais da fatia 1.

O storage local aponta para um diretório temporário por teste (fixture
`storage_dir`), então os asserts de arquivo gravado/removido olham o disco de
verdade sem sujar o repositório.
"""
import json
from pathlib import Path

import pytest
from sqlalchemy import insert, select, update

from app import schema
from app.config import settings
from app.db import engine

# Conteúdos mínimos com assinatura válida (o serviço valida por magic bytes).
JPEG = b"\xff\xd8\xff\xe0" + b"a" * 32
PNG = b"\x89PNG\r\n\x1a\n" + b"b" * 32
PDF = b"%PDF-1.4\n" + b"c" * 32


@pytest.fixture(autouse=True)
def storage_dir(tmp_path, monkeypatch):
    monkeypatch.setattr(settings, "redacoes_dir", str(tmp_path))
    return tmp_path


async def _atribuir(client, professor, tema="Minhas férias", prazo=None):
    """Professor do seed atribui uma redação à turma demo; devolve o id."""
    from app.seed import seed

    s = await seed()
    corpo = {"tema": tema, "prazo": prazo}
    r = await client.post(
        f"/v1/professor/turmas/{s['turma_id']}/redacoes",
        headers=professor["headers"],
        json=corpo,
    )
    assert r.status_code in (200, 201), r.text
    return r.json()["id"]


def _fotos(*conteudos: bytes):
    return [("arquivos", (f"p{i}.jpg", c)) for i, c in enumerate(conteudos, 1)]


async def test_lista_vazia_sem_atribuicoes(client, auth_headers):
    r = await client.get("/v1/redacoes", headers=auth_headers)
    assert r.status_code == 200
    assert r.json() == {"itens": []}


async def test_atribuicao_aparece_aberta(client, aluno, professor):
    aid = await _atribuir(client, professor, prazo="2026-08-01")
    r = await client.get("/v1/redacoes", headers=aluno["headers"])
    itens = r.json()["itens"]
    assert len(itens) == 1
    assert itens[0]["atribuicao_id"] == aid
    assert itens[0]["tema"] == "Minhas férias"
    assert itens[0]["prazo"] == "2026-08-01"
    assert itens[0]["redacao"] is None


async def test_envio_manuscrito_grava_arquivos_e_reflete_na_lista(
    client, aluno, professor, storage_dir
):
    aid = await _atribuir(client, professor)
    r = await client.post(
        f"/v1/redacoes/{aid}/envio",
        headers=aluno["headers"],
        files=_fotos(JPEG, PNG),
    )
    assert r.status_code == 201, r.text
    corpo = r.json()
    assert corpo["status"] == "enviada"
    assert corpo["paginas"] == 2

    # As chaves do arquivo_ref existem no disco, na ordem das páginas.
    async with engine.begin() as conn:
        ref = (
            await conn.execute(
                select(schema.redacao.c.arquivo_ref).where(
                    schema.redacao.c.id == corpo["redacao_id"]
                )
            )
        ).scalar_one()
    chaves = json.loads(ref)
    assert len(chaves) == 2 and chaves[0].endswith("_p1.jpg")
    for chave in chaves:
        assert (Path(storage_dir) / chave).is_file()

    lista = (await client.get("/v1/redacoes", headers=aluno["headers"])).json()
    envio = lista["itens"][0]["redacao"]
    assert envio["status"] == "enviada" and envio["paginas"] == 2


async def test_reenvio_substitui_e_remove_arquivos_antigos(
    client, aluno, professor, storage_dir
):
    aid = await _atribuir(client, professor)
    h = aluno["headers"]
    r1 = await client.post(f"/v1/redacoes/{aid}/envio", headers=h, files=_fotos(JPEG, JPEG))
    antigos = list(Path(storage_dir).rglob("*.jpg"))
    assert len(antigos) == 2

    r2 = await client.post(f"/v1/redacoes/{aid}/envio", headers=h, files=_fotos(PNG))
    assert r2.status_code == 201
    # Mesma linha (substituição), não uma segunda redação.
    assert r2.json()["redacao_id"] == r1.json()["redacao_id"]
    assert r2.json()["paginas"] == 1
    assert all(not p.exists() for p in antigos)


async def test_envio_pdf_e_formato_digital(client, aluno, professor):
    aid = await _atribuir(client, professor)
    r = await client.post(
        f"/v1/redacoes/{aid}/envio",
        headers=aluno["headers"],
        files=[("arquivos", ("redacao.pdf", PDF))],
    )
    assert r.status_code == 201
    async with engine.begin() as conn:
        formato = (
            await conn.execute(
                select(schema.redacao.c.formato).where(
                    schema.redacao.c.id == r.json()["redacao_id"]
                )
            )
        ).scalar_one()
    assert formato == "digital"


async def test_envio_rejeita_tipos_e_misturas(client, aluno, professor):
    aid = await _atribuir(client, professor)
    h = aluno["headers"]

    r = await client.post(
        f"/v1/redacoes/{aid}/envio", headers=h,
        files=[("arquivos", ("nota.txt", b"texto plano"))],
    )
    assert r.status_code == 422
    assert r.json()["error"]["code"] == "arquivo_invalido"

    r = await client.post(
        f"/v1/redacoes/{aid}/envio", headers=h,
        files=_fotos(JPEG) + [("arquivos", ("r.pdf", PDF))],
    )
    assert r.status_code == 422
    assert r.json()["error"]["code"] == "arquivo_invalido"

    grande = b"\xff\xd8\xff" + b"x" * (10 * 1024 * 1024)
    r = await client.post(
        f"/v1/redacoes/{aid}/envio", headers=h, files=_fotos(grande)
    )
    assert r.status_code == 413
    assert r.json()["error"]["code"] == "arquivo_grande"

    r = await client.post(
        f"/v1/redacoes/{aid}/envio", headers=h, files=_fotos(*([JPEG] * 7))
    )
    assert r.status_code == 422
    assert r.json()["error"]["code"] == "paginas_demais"


async def test_envio_fora_da_turma_e_404(client, aluno, professor):
    """Atribuição de outra turma responde como inexistente (não vaza escopo)."""
    from app.seed import seed

    s = await seed()
    async with engine.begin() as conn:
        outra_turma = (
            await conn.execute(
                insert(schema.turma)
                .values(
                    escola_id=s["escola_id"],
                    nome="Turma B",
                    ano_escolar=7,
                    codigo_turma="OUTRA7B",
                )
                .returning(schema.turma.c.id)
            )
        ).scalar_one()
        alheia = (
            await conn.execute(
                insert(schema.redacao_atribuicao)
                .values(turma_id=outra_turma, tema="Tema alheio")
                .returning(schema.redacao_atribuicao.c.id)
            )
        ).scalar_one()

    r = await client.post(
        f"/v1/redacoes/{alheia}/envio", headers=aluno["headers"], files=_fotos(JPEG)
    )
    assert r.status_code == 404
    assert r.json()["error"]["code"] == "atribuicao_nao_encontrada"

    # E a lista do aluno não inclui a atribuição da outra turma.
    lista = (await client.get("/v1/redacoes", headers=aluno["headers"])).json()
    assert all(i["atribuicao_id"] != alheia for i in lista["itens"])


async def test_reenvio_apos_analise_e_409(client, aluno, professor):
    aid = await _atribuir(client, professor)
    h = aluno["headers"]
    r = await client.post(f"/v1/redacoes/{aid}/envio", headers=h, files=_fotos(JPEG))
    async with engine.begin() as conn:
        await conn.execute(
            update(schema.redacao)
            .where(schema.redacao.c.id == r.json()["redacao_id"])
            .values(status="analisada")
        )
    r2 = await client.post(f"/v1/redacoes/{aid}/envio", headers=h, files=_fotos(PNG))
    assert r2.status_code == 409
    assert r2.json()["error"]["code"] == "redacao_ja_analisada"


async def test_rotas_sao_do_aluno(client, professor):
    """Professor acompanha pelas rotas de `professor`; aqui leva 403."""
    h = professor["headers"]
    assert (await client.get("/v1/redacoes", headers=h)).status_code == 403
    r = await client.post("/v1/redacoes/1/envio", headers=h, files=_fotos(JPEG))
    assert r.status_code == 403
