"""Seed de apresentação — perfis "vitrine" numa conta B2C dedicada.

Problema que resolve: numa demo de 5–10 min com o backend real, um perfil novo
não cruza XP suficiente para mostrar cartão postal, carimbo, selo ou o Modo
Conquista. Este seed fabrica perfis com progresso avançado usando a **própria
lógica de produção** (`trilha.service.processar_recompensas`): definimos o XP
alvo e as recompensas saem das mesmas regras do jogo — nada de estado inventado
que possa divergir quando as regras mudarem.

B2C (docs/plano_b2c.md Fase 1): os perfis vivem numa conta de responsável
"vitrine" (`EMAIL_CONTA_DEMO`/`SENHA_CONTA_DEMO`), não mais numa turma —
gameplay não tem escopo de escola no B2C.

Idempotente e **restaurador**: re-rodar devolve cada persona ao estado alvo
(apaga progresso/coleção/sessões dos perfis vitrine e refaz). Rode antes de
cada apresentação para "rearmar a vitrine" — inclusive o reveal pendente do
Modo Conquista, que dispara ao vivo quando o Passaporte é aberto.

Pré-requisitos (mesma ordem do CLAUDE.md):

    python -m app.seed_vocabulario  # banco base de palavras
    python -m app.seed_trilha       # trilha + colecionáveis
    python -m app.seed_demo         # este

Roteiro sugerido (5–10 min):
 1. Logar com a conta vitrine, criar um perfil NOVO → onboarding + diagnóstico
    + uma sessão ao vivo (o loop real: XP, combo, erro suavizado).
 2. Voltar à seleção de perfis e entrar como "Ana Viajante" → Home com meta
    parcial da semana, Trilha com o Brasil concluído e a França em andamento,
    Passaporte com cartões/carimbo/selos — e o Modo Conquista dispara na hora
    (há um cartão ganho e ainda não revelado).
 3. "Beto Explorador" mostra o meio da jornada (2 destinos do Brasil).
"""
import asyncio
from dataclasses import dataclass
from datetime import datetime, timedelta, timezone

from sqlalchemy import func, insert, select
from sqlalchemy.dialects.postgresql import insert as pg_insert

from app import schema
from app.db import engine
from app.progressao.semana import inicio_da_semana
from app.trilha import repository as trilha_repo
from app.trilha.service import MARCOS_DOMINADAS, NOS_POR_DESTINO, processar_recompensas

# Conta B2C "vitrine" — dona das personas de demo (docs/plano_b2c.md Fase 1).
# Não depende de turma: gameplay não tem escopo de escola em B2C.
EMAIL_CONTA_DEMO = "vitrine@vocabkids.demo"
SENHA_CONTA_DEMO = "vitrine-demo-2026"
NOME_RESPONSAVEL_DEMO = "Responsável Vitrine"


@dataclass(frozen=True)
class Persona:
    nome: str
    nos_concluidos: int      # nós da trilha já fechados (4 por destino)
    xp_no_no_atual: int      # XP parcial dentro do nó atual (anel visível no mapa)
    dominadas: int           # total de palavras dominadas (≥25 ganha o selo "mala")
    dominadas_na_semana: int # das dominadas, quantas nesta semana (meta da Home)
    em_progresso: int        # palavras em nivel_2/nivel_3 (alimentam a revisão)
    combo_recorde: int       # ≥10 ganha o selo "bússola"
    nivel: int               # nivel_dificuldade_atual (1–10)
    sessoes_total: int


# MVP (docs/plano_b2c.md "Escopo do MVP"): catálogo de 4 destinos / 16 nós —
# Brasil inteiro (Rio, Foz, Amazônia) + Paris (França), sem Japão.
#
# Ana: Brasil inteiro (12 nós) + 2 dos 4 nós de Paris → 3 cartões BR + carimbo
# BR + selo combo_10. O carimbo do Brasil fica NÃO revelado — é o Modo
# Conquista ao vivo. (Não dá pra fechar a França inteira e ainda ter um "nó
# atual" em progresso — só há 1 destino nela no MVP.)
# Beto: Rio + Foz (8 nós) → 2 cartões, sem carimbo/selos — o meio da jornada.
PERSONAS = (
    Persona("Ana Viajante", 14, 2000, 20, 3, 4, 12, 6, 31),
    Persona("Beto Explorador", 8, 1800, 12, 2, 4, 6, 3, 13),
)


def _falha(msg: str) -> SystemExit:
    return SystemExit(f"seed_demo: {msg}")


async def _garantir_conta_demo(conn) -> int:
    """Conta do responsável "vitrine", dona dos perfis de demo (idempotente).
    Tem senha real (`SENHA_CONTA_DEMO`) para logar pelo app na apresentação —
    escolhe o perfil na tela de seleção depois do login."""
    from app.identidade.schemas import CONSENTIMENTO_VERSAO_ATUAL
    from app.identidade.service import _hash_senha

    c, u = schema.conta, schema.usuario
    conta_id = (
        await conn.execute(
            select(c.c.id)
            .select_from(c.join(u, u.c.id == c.c.responsavel_usuario_id))
            .where(u.c.email == EMAIL_CONTA_DEMO)
        )
    ).scalar_one_or_none()
    if conta_id is not None:
        return conta_id

    usuario_id = (
        await conn.execute(
            insert(u)
            .values(
                nome=NOME_RESPONSAVEL_DEMO,
                email=EMAIL_CONTA_DEMO,
                senha_hash=_hash_senha(SENHA_CONTA_DEMO),
            )
            .returning(u.c.id)
        )
    ).scalar_one()
    await conn.execute(
        insert(schema.associacao).values(usuario_id=usuario_id, papel="responsavel")
    )
    conta_id = (
        await conn.execute(
            insert(c)
            .values(
                responsavel_usuario_id=usuario_id,
                consentimento_lgpd_em=func.now(),
                consentimento_versao=CONSENTIMENTO_VERSAO_ATUAL,
            )
            .returning(c.c.id)
        )
    ).scalar_one()
    # Vitrine assina — as personas mostram progresso além do free tier
    # (docs/plano_b2c.md Fase 3, R-AS-2), o que só faz sentido para assinante.
    await conn.execute(
        insert(schema.assinatura).values(
            conta_id=conta_id,
            loja="apple",
            produto_id="vocabkids_mensal_demo",
            transacao_original_id=f"vitrine-demo-{conta_id}",
            status="ativa",
            ambiente="sandbox",
        )
    )
    return conta_id


async def _garantir_aluno(conn, conta_id: int, persona: Persona) -> int:
    from app.progressao.faixa import faixa_de

    pc = schema.perfil_crianca
    usuario_id = (
        await conn.execute(
            select(pc.c.usuario_id).where(
                pc.c.conta_id == conta_id, pc.c.apelido == persona.nome
            )
        )
    ).scalar_one_or_none()
    if usuario_id is not None:
        return usuario_id

    usuario_id = (
        await conn.execute(
            insert(schema.usuario).values(nome=persona.nome).returning(schema.usuario.c.id)
        )
    ).scalar_one()
    await conn.execute(
        insert(schema.associacao).values(usuario_id=usuario_id, papel="aluno")
    )
    await conn.execute(insert(schema.aluno_progresso).values(usuario_id=usuario_id))
    ano_nascimento = 2015  # vitrine: idade não é o ponto, só precisa satisfazer o schema
    await conn.execute(
        insert(pc).values(
            usuario_id=usuario_id,
            conta_id=conta_id,
            apelido=persona.nome,
            ano_nascimento=ano_nascimento,
            faixa_etaria=faixa_de(ano_nascimento, datetime.now(timezone.utc).year),
        )
    )
    return usuario_id


async def _resetar(conn, usuario_id: int) -> None:
    """Zera tudo que uma apresentação (ou seed anterior) deixou para trás."""
    for t in (
        schema.aluno_palavra,
        schema.aluno_questao,
        schema.aluno_colecionavel,
        schema.sessao,
        schema.evento,
    ):
        await conn.execute(t.delete().where(t.c.usuario_id == usuario_id))


async def _xp_alvo(conn, persona: Persona) -> int:
    tn = schema.trilha_no
    limiares = (
        (await conn.execute(select(tn.c.xp_limiar).order_by(tn.c.xp_limiar))).scalars().all()
    )
    if len(limiares) <= persona.nos_concluidos:
        raise _falha("trilha não semeada — rode: uv run python -m app.seed_trilha")
    base = limiares[persona.nos_concluidos - 1] if persona.nos_concluidos else 0
    xp = base + persona.xp_no_no_atual
    if xp >= limiares[persona.nos_concluidos]:
        raise _falha(f"xp_no_no_atual de {persona.nome} fecharia o nó seguinte")
    return xp


async def _referencias_em_ordem_de_ganho(conn, persona: Persona) -> list[str]:
    """As referências dos colecionáveis na ordem em que o jogo as teria dado."""
    d, p = schema.destino, schema.pais
    destinos = (
        await conn.execute(
            select(d.c.id, d.c.pais_id)
            .select_from(d.join(p, p.c.id == d.c.pais_id))
            .order_by(p.c.ordem, d.c.ordem)
        )
    ).all()
    total_por_pais: dict[int, int] = {}
    for row in destinos:
        total_por_pais[row.pais_id] = total_por_pais.get(row.pais_id, 0) + 1

    refs: list[str] = []
    fechados_por_pais: dict[int, int] = {}
    for row in destinos[: persona.nos_concluidos // NOS_POR_DESTINO]:
        refs.append(f"destino:{row.id}")
        fechados_por_pais[row.pais_id] = fechados_por_pais.get(row.pais_id, 0) + 1
        if fechados_por_pais[row.pais_id] == total_por_pais[row.pais_id]:
            refs.append(f"pais:{row.pais_id}")

    # Selos entram no meio da linha do tempo (ganhos "durante a jornada"),
    # nunca por último — o item mais recente deve ser o cartão pendente.
    if persona.combo_recorde >= 10:
        refs.insert(min(2, len(refs)), "feito:combo_10")
    for i, marco in enumerate(m for m in MARCOS_DOMINADAS if persona.dominadas >= m):
        refs.insert(min(5 + i, len(refs)), f"feito:dominadas_{marco}")
    return refs


async def _datar_colecao(conn, usuario_id: int, refs_em_ordem: list[str], agora) -> str | None:
    """Espalha ganho_em no passado e deixa só o item mais recente sem reveal."""
    ac, c = schema.aluno_colecionavel, schema.colecionavel
    ganhos = (
        await conn.execute(
            select(ac.c.id, c.c.referencia)
            .select_from(ac.join(c, c.c.id == ac.c.colecionavel_id))
            .where(ac.c.usuario_id == usuario_id)
        )
    ).all()
    por_referencia = {g.referencia: g.id for g in ganhos}
    ordenadas = [r for r in refs_em_ordem if r in por_referencia]

    pendente = ordenadas[-1] if ordenadas else None
    for i, ref in enumerate(ordenadas):
        ganho_em = agora - timedelta(days=(len(ordenadas) - 1 - i) * 2, hours=3)
        revelado_em = None if ref == pendente else ganho_em + timedelta(minutes=10)
        await conn.execute(
            ac.update()
            .where(ac.c.id == por_referencia[ref])
            .values(ganho_em=ganho_em, revelado_em=revelado_em)
        )
    return pendente


async def _semear_palavras(conn, usuario_id: int, persona: Persona, agora) -> None:
    """Dominadas (algumas nesta semana → meta da Home) + revisão para a sessão."""
    p = schema.palavra
    necessarias = persona.dominadas + persona.em_progresso
    palavras = (
        await conn.execute(
            select(p.c.id)
            .where(p.c.origem == "banco_base")
            .order_by(p.c.nivel_dificuldade, p.c.id)
            .limit(necessarias)
        )
    ).scalars().all()
    if len(palavras) < necessarias:
        raise _falha(
            f"banco base tem {len(palavras)} palavras e {persona.nome} precisa de "
            f"{necessarias} — rode: uv run python -m app.seed_vocabulario"
        )

    inicio_semana = inicio_da_semana()
    antigas = persona.dominadas - persona.dominadas_na_semana
    linhas = []
    for k in range(persona.dominadas):
        if k < antigas:
            dominada_em = agora - timedelta(days=9 + (antigas - 1 - k) * 3)
        else:
            # Dentro da semana corrente, espaçadas entre segunda 00:00 e agora.
            fracao = (k - antigas + 1) / (persona.dominadas_na_semana + 1)
            dominada_em = inicio_semana + (agora - inicio_semana) * fracao
        linhas.append(
            {
                "usuario_id": usuario_id,
                "palavra_id": palavras[k],
                "estado": "dominada",
                "origem": "banco_base",
                "atribuida_em": dominada_em - timedelta(days=5),
                "dominada_em": dominada_em,
            }
        )
    for j in range(persona.em_progresso):
        linhas.append(
            {
                "usuario_id": usuario_id,
                "palavra_id": palavras[persona.dominadas + j],
                "estado": "nivel_2" if j % 2 == 0 else "nivel_3",
                "origem": "banco_base",
                "atribuida_em": agora - timedelta(days=4 - j),
                "dominada_em": None,
            }
        )
    await conn.execute(schema.aluno_palavra.insert(), linhas)


async def seed_demo() -> dict:
    agora = datetime.now(timezone.utc)
    resultado: dict[str, dict] = {}
    async with engine.begin() as conn:
        conta_id = await _garantir_conta_demo(conn)
        for persona in PERSONAS:
            usuario_id = await _garantir_aluno(conn, conta_id, persona)
            await _resetar(conn, usuario_id)

            xp_total = await _xp_alvo(conn, persona)
            ap = schema.aluno_progresso
            valores = {
                "xp_total": xp_total,
                "no_atual_id": None,
                "palavras_dominadas": persona.dominadas,
                "combo_atual": 0,
                "nivel_dificuldade_atual": persona.nivel,
                "sessoes_total": persona.sessoes_total,
                "nivel_mudou_em_sessao": None,
            }
            await conn.execute(
                pg_insert(ap)
                .values(usuario_id=usuario_id, **valores)
                .on_conflict_do_update(index_elements=[ap.c.usuario_id], set_=valores)
            )

            # As recompensas saem da lógica real (0 → xp_total cruza todos os
            # nós de uma vez); o seed só re-data e arma o reveal pendente.
            await processar_recompensas(
                conn, usuario_id, 0, xp_total, persona.combo_recorde, persona.dominadas
            )
            await trilha_repo.definir_no_atual(
                conn, usuario_id, await trilha_repo.id_no_atual(conn, xp_total)
            )
            refs = await _referencias_em_ordem_de_ganho(conn, persona)
            pendente = await _datar_colecao(conn, usuario_id, refs, agora)
            await _semear_palavras(conn, usuario_id, persona, agora)

            ac = schema.aluno_colecionavel
            colecionaveis = (
                await conn.execute(
                    select(func.count()).where(ac.c.usuario_id == usuario_id)
                )
            ).scalar_one()
            resultado[persona.nome] = {
                "usuario_id": usuario_id,
                "xp_total": xp_total,
                "colecionaveis": colecionaveis,
                "reveal_pendente": pendente,
                "dominadas_na_semana": persona.dominadas_na_semana,
            }
    return resultado


if __name__ == "__main__":
    resumo = asyncio.run(seed_demo())
    print("seed demo ok — conta vitrine:", EMAIL_CONTA_DEMO, "/", SENHA_CONTA_DEMO)
    for nome, dados in resumo.items():
        print(
            f"  {nome}: xp={dados['xp_total']}, "
            f"{dados['colecionaveis']} colecionáveis "
            f"(reveal pendente: {dados['reveal_pendente']}), "
            f"{dados['dominadas_na_semana']} dominadas nesta semana"
        )
    print(f"Para apresentar: logue com {EMAIL_CONTA_DEMO} / {SENHA_CONTA_DEMO},")
    print("crie um perfil novo (onboarding + sessão ao vivo) e depois escolha")
    print("'Ana Viajante' na seleção de perfis (trilha avançada + Modo Conquista).")
    print("Re-rode este seed antes de cada apresentação para rearmar a vitrine.")
