"""Professor — fatia C: dados reais, escopo por associação e persistência.

Cenário: a escola do seed (turma 7º A) com dois alunos de progresso real
(palavras dominadas nesta semana e antes, sessão na semana) e uma **segunda
escola** com professor próprio, para provar o escopo (§3.11).
"""
from datetime import datetime, timedelta, timezone

import pytest
import pytest_asyncio
from sqlalchemy import insert, select, update

from app import schema
from app.db import engine
from app.identidade.auth import criar_token


async def _entrar(client, nome: str) -> dict:
    r = await client.post(
        "/v1/acesso/turma", json={"codigo_turma": "DEMO7A", "nome": nome}
    )
    assert r.status_code == 200, r.text
    return r.json()


@pytest_asyncio.fixture
async def cenario(client, professor):
    """Escola do seed populada + 2ª escola para testes de escopo."""
    ana = await _entrar(client, "Ana")
    bruno = await _entrar(client, "Bruno")
    agora = datetime.now(timezone.utc)

    async with engine.begin() as conn:
        palavra_ids = {}
        for lema in ("efemero", "perspicaz", "conciso", "sagaz"):
            palavra_ids[lema] = (
                await conn.execute(
                    insert(schema.palavra)
                    .values(
                        lema=lema,
                        definicao="definição",
                        exemplo_uso="exemplo",
                        nivel_dificuldade=3,
                        origem="banco_base",
                    )
                    .returning(schema.palavra.c.id)
                )
            ).scalar_one()

        # Ana: 2 dominadas NESTA semana, 1 dominada há 5 semanas, 1 em nível 2.
        ap = schema.aluno_palavra
        await conn.execute(
            insert(ap),
            [
                {
                    "usuario_id": ana["usuario_id"],
                    "palavra_id": palavra_ids["efemero"],
                    "estado": "dominada",
                    "origem": "banco_base",
                    "dominada_em": agora,
                },
                {
                    "usuario_id": ana["usuario_id"],
                    "palavra_id": palavra_ids["perspicaz"],
                    "estado": "dominada",
                    "origem": "banco_base",
                    "dominada_em": agora,
                },
                {
                    "usuario_id": ana["usuario_id"],
                    "palavra_id": palavra_ids["conciso"],
                    "estado": "dominada",
                    "origem": "banco_base",
                    "dominada_em": agora - timedelta(days=35),
                },
                {
                    "usuario_id": ana["usuario_id"],
                    "palavra_id": palavra_ids["sagaz"],
                    "estado": "nivel_2",
                    "origem": "banco_base",
                    "dominada_em": None,
                },
            ],
        )
        # O acumulado histórico sai do counter de aluno_progresso (fonte única).
        await conn.execute(
            update(schema.aluno_progresso)
            .where(schema.aluno_progresso.c.usuario_id == ana["usuario_id"])
            .values(palavras_dominadas=3)
        )
        # Ana teve sessão nesta semana (ativa); Bruno não.
        await conn.execute(
            insert(schema.sessao).values(usuario_id=ana["usuario_id"])
        )

        # 2ª escola + turma + professor (fora do escopo da escola do seed).
        escola2 = (
            await conn.execute(
                insert(schema.escola)
                .values(nome="Escola Dois")
                .returning(schema.escola.c.id)
            )
        ).scalar_one()
        turma2 = (
            await conn.execute(
                insert(schema.turma)
                .values(
                    escola_id=escola2,
                    nome="8º Ano B",
                    ano_escolar=8,
                    codigo_turma="OUTRA8B",
                )
                .returning(schema.turma.c.id)
            )
        ).scalar_one()
        prof2 = (
            await conn.execute(
                insert(schema.usuario)
                .values(nome="Professor Dois")
                .returning(schema.usuario.c.id)
            )
        ).scalar_one()
        assoc2 = (
            await conn.execute(
                insert(schema.associacao)
                .values(usuario_id=prof2, escola_id=escola2, papel="professor")
                .returning(schema.associacao.c.id)
            )
        ).scalar_one()
        await conn.execute(
            insert(schema.associacao_turma).values(
                associacao_id=assoc2, turma_id=turma2
            )
        )

    return {
        "professor": professor,
        "ana": ana,
        "bruno": bruno,
        "turma2": turma2,
        "professor2_headers": {
            "Authorization": f"Bearer {criar_token(prof2, 'professor')}"
        },
    }


# ─────────────────────────────── autorização ───────────────────────────────


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
async def test_coordenador_le_mas_nao_configura(client, cenario, coordenador):
    """Coordenador é só leitura (§3.11): painéis sim; meta/redação não."""
    h = coordenador["headers"]
    assert (await client.get("/v1/professor/turmas", headers=h)).status_code == 200
    assert (await client.get("/v1/professor/escola", headers=h)).status_code == 200
    painel = await client.get("/v1/professor/turmas/1/painel", headers=h)
    assert painel.status_code == 200
    meta = await client.put(
        "/v1/professor/turmas/1/meta", headers=h, json={"meta_semanal": 5}
    )
    assert meta.status_code == 403
    redacao = await client.post(
        "/v1/professor/turmas/1/redacoes", headers=h, json={"tema": "Tema"}
    )
    assert redacao.status_code == 403


# ────────────────────────────────── escopo ──────────────────────────────────


@pytest.mark.asyncio
async def test_escopo_professor_so_ve_as_proprias_turmas(client, cenario):
    # Professora do seed: só a turma 1.
    r = await client.get(
        "/v1/professor/turmas", headers=cenario["professor"]["headers"]
    )
    ids = [t["id"] for t in r.json()["turmas"]]
    assert ids == [1]

    # Professor da escola 2: a turma 1 existe, mas está fora do alcance.
    h2 = cenario["professor2_headers"]
    assert [t["id"] for t in (await client.get("/v1/professor/turmas", headers=h2)).json()["turmas"]] == [cenario["turma2"]]
    fora = await client.get("/v1/professor/turmas/1/painel", headers=h2)
    assert fora.status_code == 403
    assert fora.json()["error"]["code"] == "sem_permissao"

    # Aluno da escola 1 fora do alcance do professor da escola 2.
    aluno_fora = await client.get(
        f"/v1/professor/alunos/{cenario['ana']['usuario_id']}", headers=h2
    )
    assert aluno_fora.status_code == 403

    # Configurar fora do escopo também é barrado.
    assert (
        await client.put(
            "/v1/professor/turmas/1/meta", headers=h2, json={"meta_semanal": 9}
        )
    ).status_code == 403
    assert (
        await client.post(
            "/v1/professor/turmas/1/redacoes", headers=h2, json={"tema": "X"}
        )
    ).status_code == 403


@pytest.mark.asyncio
async def test_turma_inexistente_da_404(client, cenario):
    h = cenario["professor"]["headers"]
    assert (await client.get("/v1/professor/turmas/999/painel", headers=h)).status_code == 404
    assert (
        await client.put("/v1/professor/turmas/999/meta", headers=h, json={"meta_semanal": 5})
    ).status_code == 404
    assert (
        await client.post("/v1/professor/turmas/999/redacoes", headers=h, json={"tema": "T"})
    ).status_code == 404
    assert (await client.get("/v1/professor/alunos/999", headers=h)).status_code == 404


# ─────────────────────────────── dados reais ───────────────────────────────


@pytest.mark.asyncio
async def test_painel_com_dados_reais(client, cenario):
    r = await client.get(
        "/v1/professor/turmas/1/painel", headers=cenario["professor"]["headers"]
    )
    assert r.status_code == 200, r.text
    b = r.json()
    assert b["mock"] is False
    assert b["turma_nome"] == "7º Ano A"
    assert b["alunos_total"] == 2
    assert b["alunos_ativos"] == 1  # só a Ana teve sessão na semana
    assert b["palavras_dominadas_semana"] == 2  # as 2 da Ana nesta semana
    assert b["meta_semanal"] == 5  # default do 7º ano (sem config)
    assert b["sinal_turma"] == []  # sem redações analisadas ainda

    por_nome = {a["nome"]: a for a in b["alunos"]}
    assert por_nome["Ana"]["palavras_semana"] == 2
    assert por_nome["Ana"]["palavras_dominadas"] == 3  # acumulado (counter)
    assert por_nome["Ana"]["meta_semana"] == 5
    assert por_nome["Bruno"]["palavras_semana"] == 0
    assert por_nome["Bruno"]["palavras_dominadas"] == 0


@pytest.mark.asyncio
async def test_painel_escola_agrega_turmas(client, cenario, coordenador):
    r = await client.get("/v1/professor/escola", headers=coordenador["headers"])
    assert r.status_code == 200
    b = r.json()
    assert b["mock"] is False
    assert b["escola_nome"] == "Escola Demonstração"
    assert b["turmas_total"] == 1  # a escola 2 não entra
    assert b["alunos_total"] == 2
    assert b["alunos_ativos"] == 1
    assert b["palavras_dominadas_semana"] == 2
    assert b["turmas"][0]["id"] == 1


@pytest.mark.asyncio
async def test_detalhe_do_aluno_real(client, cenario):
    h = cenario["professor"]["headers"]
    ana_id = cenario["ana"]["usuario_id"]
    r = await client.get(f"/v1/professor/alunos/{ana_id}", headers=h)
    assert r.status_code == 200, r.text
    b = r.json()
    assert b["mock"] is False
    assert b["nome"] == "Ana"
    assert b["turma_nome"] == "7º Ano A"
    assert b["palavras_semana"] == 2
    assert b["palavras_dominadas"] == 3
    assert b["palavras_em_progresso"] == 1  # sagaz em nivel_2
    estados = {p["texto"]: p["estado"] for p in b["palavras"]}
    assert estados["efemero"] == "dominada"
    assert estados["sagaz"] == "nivel_2"
    assert b["redacoes"] == []  # nada atribuído ainda


@pytest.mark.asyncio
async def test_atribuir_redacao_persiste_e_aparece_no_aluno(client, cenario):
    h = cenario["professor"]["headers"]
    r = await client.post(
        "/v1/professor/turmas/1/redacoes",
        headers=h,
        json={"tema": "  Um herói brasileiro  ", "prazo": "2026-08-30"},
    )
    assert r.status_code == 201, r.text
    b = r.json()
    assert b["mock"] is False
    assert b["tema"] == "Um herói brasileiro"  # strip server-side
    assert b["prazo"] == "2026-08-30"

    # Persistiu de verdade (com o professor autor) e o aluno a vê pendente.
    async with engine.connect() as conn:
        row = (
            await conn.execute(
                select(
                    schema.redacao_atribuicao.c.tema,
                    schema.redacao_atribuicao.c.professor_associacao_id,
                ).where(schema.redacao_atribuicao.c.id == b["id"])
            )
        ).one()
    assert row.tema == "Um herói brasileiro"
    assert row.professor_associacao_id is not None

    detalhe = (
        await client.get(
            f"/v1/professor/alunos/{cenario['ana']['usuario_id']}", headers=h
        )
    ).json()
    assert detalhe["redacoes"] == [
        {
            "id": b["id"],
            "tema": "Um herói brasileiro",
            "status": "pendente",
            "enviada_em": None,
        }
    ]


@pytest.mark.asyncio
async def test_meta_persiste_e_reflete_no_painel_e_no_aluno(client, cenario):
    h = cenario["professor"]["headers"]
    r = await client.put(
        "/v1/professor/turmas/1/meta", headers=h, json={"meta_semanal": 8}
    )
    assert r.status_code == 200
    assert r.json() == {"mock": False, "turma_id": 1, "meta_semanal": 8}

    painel = (await client.get("/v1/professor/turmas/1/painel", headers=h)).json()
    assert painel["meta_semanal"] == 8
    assert all(a["meta_semana"] == 8 for a in painel["alunos"])

    # A Home do aluno lê o mesmo alvo (e o mesmo corte de semana).
    me = (
        await client.get(
            "/v1/me",
            headers={"Authorization": f"Bearer {cenario['ana']['token']}"},
        )
    ).json()
    assert me["meta_semanal"] == {"atual": 2, "alvo": 8}

    # Upsert: reconfigurar sobrescreve, não duplica.
    await client.put("/v1/professor/turmas/1/meta", headers=h, json={"meta_semanal": 9})
    async with engine.connect() as conn:
        metas = (
            await conn.execute(
                select(schema.turma_config.c.meta_semanal).where(
                    schema.turma_config.c.turma_id == 1
                )
            )
        ).scalars().all()
    assert metas == [9]


# ─────────────────────────────── validações ───────────────────────────────


@pytest.mark.asyncio
async def test_atribuir_redacao_tema_vazio_e_prazo_invalido(client, cenario):
    h = cenario["professor"]["headers"]
    vazio = await client.post(
        "/v1/professor/turmas/1/redacoes", headers=h, json={"tema": "   "}
    )
    assert vazio.status_code == 422
    prazo = await client.post(
        "/v1/professor/turmas/1/redacoes",
        headers=h,
        json={"tema": "Ok", "prazo": "30/06/2026"},
    )
    assert prazo.status_code == 422


@pytest.mark.asyncio
async def test_atualizar_meta_fora_da_faixa(client, cenario):
    h = cenario["professor"]["headers"]
    zero = await client.put(
        "/v1/professor/turmas/1/meta", headers=h, json={"meta_semanal": 0}
    )
    assert zero.status_code == 422
    alto = await client.put(
        "/v1/professor/turmas/1/meta", headers=h, json={"meta_semanal": 99}
    )
    assert alto.status_code == 422
