"""Repositório do domínio professor — acesso ao Postgres (SQLAlchemy Core).

Fatia C: as queries reais que substituem os mocks. Padrão de desempenho: os
agregados saem **agrupados por turma** (uma query por métrica para N turmas),
nunca por-linha — o painel da escola não faz N+1.
"""
from datetime import date, datetime

from sqlalchemy import and_, desc, func, select
from sqlalchemy.dialects.postgresql import insert as pg_insert
from sqlalchemy.engine import Row
from sqlalchemy.ext.asyncio import AsyncConnection

from app import schema


def _membros_aluno():
    """Join de pertencimento: (usuario aluno) ∈ turma, via associação."""
    a, at = schema.associacao, schema.associacao_turma
    return a.join(at, at.c.associacao_id == a.c.id), a, at


async def associacao_na_escola(conn: AsyncConnection, usuario_id: int) -> Row | None:
    """Associação (papel + escola) do usuário — âncora de escopo (§3.11)."""
    a, e = schema.associacao, schema.escola
    stmt = (
        select(
            a.c.id.label("associacao_id"),
            a.c.papel,
            e.c.id.label("escola_id"),
            e.c.nome.label("escola_nome"),
        )
        .select_from(a.join(e, e.c.id == a.c.escola_id))
        .where(a.c.usuario_id == usuario_id)
        .limit(1)
    )
    return (await conn.execute(stmt)).first()


async def turma_ids_do_professor(conn: AsyncConnection, usuario_id: int) -> list[int]:
    join, a, at = _membros_aluno()
    stmt = (
        select(at.c.turma_id)
        .select_from(join)
        .where(a.c.usuario_id == usuario_id, a.c.papel == "professor")
    )
    return list((await conn.execute(stmt)).scalars())


async def turma_ids_da_escola(conn: AsyncConnection, escola_id: int) -> list[int]:
    t = schema.turma
    stmt = select(t.c.id).where(t.c.escola_id == escola_id).order_by(t.c.id)
    return list((await conn.execute(stmt)).scalars())


async def turmas_por_ids(conn: AsyncConnection, turma_ids: list[int]) -> list[Row]:
    """Turmas + meta configurada (nula = default por ano, resolvido no serviço)."""
    t, tc = schema.turma, schema.turma_config
    stmt = (
        select(
            t.c.id,
            t.c.nome,
            t.c.ano_escolar,
            t.c.escola_id,
            tc.c.meta_semanal.label("meta_config"),
        )
        .select_from(t.outerjoin(tc, tc.c.turma_id == t.c.id))
        .where(t.c.id.in_(turma_ids))
        .order_by(t.c.id)
    )
    return list((await conn.execute(stmt)).all())


async def alunos_total_por_turma(
    conn: AsyncConnection, turma_ids: list[int]
) -> dict[int, int]:
    join, a, at = _membros_aluno()
    stmt = (
        select(at.c.turma_id, func.count().label("n"))
        .select_from(join)
        .where(a.c.papel == "aluno", at.c.turma_id.in_(turma_ids))
        .group_by(at.c.turma_id)
    )
    return {r.turma_id: r.n for r in await conn.execute(stmt)}


async def ativos_na_semana_por_turma(
    conn: AsyncConnection, turma_ids: list[int], inicio: datetime
) -> dict[int, int]:
    """Alunos "ativos" = com sessão iniciada na semana corrente."""
    join, a, at = _membros_aluno()
    s = schema.sessao
    stmt = (
        select(at.c.turma_id, func.count(func.distinct(s.c.usuario_id)).label("n"))
        .select_from(
            join.join(
                s,
                and_(s.c.usuario_id == a.c.usuario_id, s.c.iniciada_em >= inicio),
            )
        )
        .where(a.c.papel == "aluno", at.c.turma_id.in_(turma_ids))
        .group_by(at.c.turma_id)
    )
    return {r.turma_id: r.n for r in await conn.execute(stmt)}


async def dominadas_na_semana_por_turma(
    conn: AsyncConnection, turma_ids: list[int], inicio: datetime
) -> dict[int, int]:
    join, a, at = _membros_aluno()
    ap = schema.aluno_palavra
    stmt = (
        select(at.c.turma_id, func.count().label("n"))
        .select_from(
            join.join(
                ap,
                and_(ap.c.usuario_id == a.c.usuario_id, ap.c.dominada_em >= inicio),
            )
        )
        .where(a.c.papel == "aluno", at.c.turma_id.in_(turma_ids))
        .group_by(at.c.turma_id)
    )
    return {r.turma_id: r.n for r in await conn.execute(stmt)}


async def alunos_do_painel(
    conn: AsyncConnection, turma_id: int, inicio: datetime
) -> list[Row]:
    """Linhas de aluno do painel: dominadas na semana + acumulado, numa query."""
    join, a, at = _membros_aluno()
    u, ap, prog = schema.usuario, schema.aluno_palavra, schema.aluno_progresso
    stmt = (
        select(
            u.c.id,
            u.c.nome,
            func.coalesce(prog.c.palavras_dominadas, 0).label("dominadas_total"),
            func.count(ap.c.id).filter(ap.c.dominada_em >= inicio).label(
                "dominadas_semana"
            ),
        )
        .select_from(
            join.join(u, u.c.id == a.c.usuario_id)
            .outerjoin(prog, prog.c.usuario_id == u.c.id)
            .outerjoin(
                ap,
                and_(ap.c.usuario_id == u.c.id, ap.c.dominada_em.isnot(None)),
            )
        )
        .where(a.c.papel == "aluno", at.c.turma_id == turma_id)
        .group_by(u.c.id, u.c.nome, prog.c.palavras_dominadas)
        .order_by(u.c.nome)
    )
    return list((await conn.execute(stmt)).all())


async def sinal_das_turmas(
    conn: AsyncConnection, turma_ids: list[int], limite: int = 3
) -> list[str]:
    """Palavras fracas recorrentes (§3.5), mais fortes primeiro. A tabela é
    materializada pelo job periódico do pipeline de redação (fatia C de
    redação) — sem redações analisadas ela é vazia, e a lista sai vazia."""
    st, p = schema.sinal_turma, schema.palavra
    stmt = (
        select(p.c.lema, func.max(st.c.pct).label("pct"))
        .select_from(st.join(p, p.c.id == st.c.palavra_id))
        .where(st.c.turma_id.in_(turma_ids))
        .group_by(p.c.lema)
        .order_by(desc("pct"))
        .limit(limite)
    )
    return list((await conn.execute(stmt)).scalars())


# ───────────────────────────── detalhe do aluno ─────────────────────────────


async def aluno_com_turma(conn: AsyncConnection, aluno_id: int) -> Row | None:
    join, a, at = _membros_aluno()
    u, t = schema.usuario, schema.turma
    stmt = (
        select(
            u.c.id,
            u.c.nome,
            a.c.escola_id,
            t.c.id.label("turma_id"),
            t.c.nome.label("turma_nome"),
            t.c.ano_escolar,
        )
        .select_from(
            join.join(u, u.c.id == a.c.usuario_id).join(t, t.c.id == at.c.turma_id)
        )
        .where(u.c.id == aluno_id, a.c.papel == "aluno")
        .limit(1)
    )
    return (await conn.execute(stmt)).first()


async def contadores_do_aluno(conn: AsyncConnection, usuario_id: int) -> Row:
    ap, prog = schema.aluno_palavra, schema.aluno_progresso
    em_progresso = (
        select(func.count())
        .where(ap.c.usuario_id == usuario_id, ap.c.estado.like("nivel_%"))
        .scalar_subquery()
    )
    dominadas = (
        select(func.coalesce(func.max(prog.c.palavras_dominadas), 0))
        .where(prog.c.usuario_id == usuario_id)
        .scalar_subquery()
    )
    stmt = select(
        dominadas.label("dominadas"), em_progresso.label("em_progresso")
    )
    return (await conn.execute(stmt)).one()


async def dominadas_na_semana(
    conn: AsyncConnection, usuario_id: int, inicio: datetime
) -> int:
    ap = schema.aluno_palavra
    stmt = select(func.count()).where(
        ap.c.usuario_id == usuario_id, ap.c.dominada_em >= inicio
    )
    return (await conn.execute(stmt)).scalar_one()


async def palavras_notaveis(
    conn: AsyncConnection, usuario_id: int, limite: int = 6
) -> list[Row]:
    """Subconjunto recente/ativo do vocabulário do aluno (telas §8.2)."""
    ap, p = schema.aluno_palavra, schema.palavra
    stmt = (
        select(p.c.lema.label("texto"), ap.c.estado, ap.c.origem)
        .select_from(ap.join(p, p.c.id == ap.c.palavra_id))
        .where(ap.c.usuario_id == usuario_id)
        .order_by(func.coalesce(ap.c.dominada_em, ap.c.atribuida_em).desc())
        .limit(limite)
    )
    return list((await conn.execute(stmt)).all())


# ─────────────────────────── redação (atribuições) ───────────────────────────


async def criar_atribuicao(
    conn: AsyncConnection,
    turma_id: int,
    professor_associacao_id: int,
    tema: str,
    prazo: date | None,
) -> int:
    ra = schema.redacao_atribuicao
    stmt = (
        pg_insert(ra)
        .values(
            turma_id=turma_id,
            professor_associacao_id=professor_associacao_id,
            tema=tema,
            prazo=prazo,
        )
        .returning(ra.c.id)
    )
    return (await conn.execute(stmt)).scalar_one()


async def redacoes_do_aluno(
    conn: AsyncConnection, usuario_id: int, turma_id: int
) -> list[Row]:
    """Atribuições da turma sob a ótica do aluno (envio dele, se houver)."""
    ra, r = schema.redacao_atribuicao, schema.redacao
    stmt = (
        select(ra.c.id, ra.c.tema, r.c.status, r.c.enviada_em)
        .select_from(
            ra.outerjoin(
                r,
                and_(r.c.atribuicao_id == ra.c.id, r.c.usuario_id == usuario_id),
            )
        )
        .where(ra.c.turma_id == turma_id)
        .order_by(ra.c.id.desc())
    )
    return list((await conn.execute(stmt)).all())


# ─────────────────────────────── configuração ───────────────────────────────


async def upsert_meta(conn: AsyncConnection, turma_id: int, meta: int) -> None:
    tc = schema.turma_config
    stmt = (
        pg_insert(tc)
        .values(turma_id=turma_id, meta_semanal=meta)
        .on_conflict_do_update(
            index_elements=[tc.c.turma_id], set_={"meta_semanal": meta}
        )
    )
    await conn.execute(stmt)
