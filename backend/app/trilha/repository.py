"""Repositório da trilha — catálogo global + colecionáveis do aluno (Core).

`xp_limiar` é cumulativo, então "concluído"/"nó atual" saem de comparações diretas
com `xp_total`, sem somatórios no caminho quente das respostas.
"""
from sqlalchemy import func, select
from sqlalchemy.dialects.postgresql import insert as pg_insert
from sqlalchemy.engine import Row
from sqlalchemy.ext.asyncio import AsyncConnection

from app import schema


async def agregado_mapa(conn: AsyncConnection, xp_total: int) -> list[Row]:
    """Uma linha por destino, com país, totais de nós e quantos já concluídos."""
    p, d, tn = schema.pais, schema.destino, schema.trilha_no
    concluidos = func.count(tn.c.id).filter(tn.c.xp_limiar <= xp_total)
    stmt = (
        select(
            p.c.id.label("pais_id"),
            p.c.nome.label("pais_nome"),
            p.c.ordem.label("pais_ordem"),
            d.c.id.label("destino_id"),
            d.c.nome.label("destino_nome"),
            d.c.ordem.label("destino_ordem"),
            func.count(tn.c.id).label("nos_total"),
            concluidos.label("nos_concluidos"),
        )
        .select_from(p.join(d, d.c.pais_id == p.c.id).join(tn, tn.c.destino_id == d.c.id))
        .group_by(p.c.id, p.c.nome, p.c.ordem, d.c.id, d.c.nome, d.c.ordem)
        .order_by(p.c.ordem, d.c.ordem)
    )
    return list((await conn.execute(stmt)).all())


async def no_atual_detalhe(conn: AsyncConnection, xp_total: int) -> Row | None:
    """O nó que está sendo preenchido (1º com xp_limiar > xp_total) + contexto."""
    d, tn, p = schema.destino, schema.trilha_no, schema.pais
    stmt = (
        select(
            tn.c.id.label("no_id"),
            tn.c.ordem.label("no_ordem"),
            tn.c.xp_limiar,
            d.c.id.label("destino_id"),
            d.c.nome.label("destino_nome"),
            p.c.nome.label("pais_nome"),
        )
        .select_from(tn.join(d, d.c.id == tn.c.destino_id).join(p, p.c.id == d.c.pais_id))
        .where(tn.c.xp_limiar > xp_total)
        .order_by(tn.c.xp_limiar)
        .limit(1)
    )
    return (await conn.execute(stmt)).first()


async def xp_inicio_do_no(conn: AsyncConnection, xp_limiar: int) -> int:
    """Limiar do nó anterior (início da barra do nó atual); 0 se for o 1º."""
    tn = schema.trilha_no
    anterior = (
        await conn.execute(
            select(func.max(tn.c.xp_limiar)).where(tn.c.xp_limiar < xp_limiar)
        )
    ).scalar_one_or_none()
    return anterior or 0


async def id_no_atual(conn: AsyncConnection, xp_total: int) -> int | None:
    tn = schema.trilha_no
    proximo = (
        await conn.execute(
            select(tn.c.id).where(tn.c.xp_limiar > xp_total).order_by(tn.c.xp_limiar).limit(1)
        )
    ).scalar_one_or_none()
    if proximo is not None:
        return proximo
    # trilha inteira concluída → fica no último nó
    return (await conn.execute(select(func.max(tn.c.id)))).scalar_one_or_none()


async def definir_no_atual(conn: AsyncConnection, usuario_id: int, no_id: int | None) -> None:
    ap = schema.aluno_progresso
    await conn.execute(
        ap.update().where(ap.c.usuario_id == usuario_id).values(no_atual_id=no_id)
    )


async def nos_concluidos_entre(
    conn: AsyncConnection, xp_anterior: int, xp_total: int
) -> list[Row]:
    """Nós cujo limiar foi cruzado nesta resposta (xp_anterior, xp_total]."""
    tn, d = schema.trilha_no, schema.destino
    stmt = (
        select(
            tn.c.id,
            tn.c.ordem.label("no_ordem"),
            d.c.id.label("destino_id"),
            d.c.ordem.label("destino_ordem"),
            d.c.pais_id,
        )
        .select_from(tn.join(d, d.c.id == tn.c.destino_id))
        .where(tn.c.xp_limiar > xp_anterior, tn.c.xp_limiar <= xp_total)
        .order_by(tn.c.xp_limiar)
    )
    return list((await conn.execute(stmt)).all())


async def max_destino_ordem_por_pais(conn: AsyncConnection) -> dict[int, int]:
    d = schema.destino
    rows = (
        await conn.execute(
            select(d.c.pais_id, func.max(d.c.ordem)).group_by(d.c.pais_id)
        )
    ).all()
    return {pais_id: maximo for pais_id, maximo in rows}


async def colecionavel_por_referencia(
    conn: AsyncConnection, referencia: str
) -> Row | None:
    c = schema.colecionavel
    return (
        await conn.execute(
            select(c.c.id, c.c.tipo, c.c.asset_ref, c.c.referencia).where(
                c.c.referencia == referencia
            )
        )
    ).first()


async def conceder(conn: AsyncConnection, usuario_id: int, colecionavel_id: int) -> bool:
    """Concede um colecionável; idempotente. True se foi novo (ganho agora)."""
    ac = schema.aluno_colecionavel
    stmt = (
        pg_insert(ac)
        .values(usuario_id=usuario_id, colecionavel_id=colecionavel_id)
        .on_conflict_do_nothing(index_elements=[ac.c.usuario_id, ac.c.colecionavel_id])
        .returning(ac.c.id)
    )
    return (await conn.execute(stmt)).first() is not None


async def listar_passaporte(conn: AsyncConnection, usuario_id: int) -> list[Row]:
    """Os 28 colecionáveis + quando o aluno ganhou cada um (null = não ganho)."""
    c, ac = schema.colecionavel, schema.aluno_colecionavel
    juncao = c.outerjoin(
        ac, (ac.c.colecionavel_id == c.c.id) & (ac.c.usuario_id == usuario_id)
    )
    stmt = (
        select(
            c.c.id,
            c.c.tipo,
            c.c.referencia,
            c.c.asset_ref,
            ac.c.ganho_em,
        )
        .select_from(juncao)
        .order_by(c.c.tipo, c.c.id)
    )
    return list((await conn.execute(stmt)).all())
