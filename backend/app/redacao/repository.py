"""Repositório do domínio redação — acesso ao Postgres (SQLAlchemy Core).

`redacao.arquivo_ref` guarda um **JSON de chaves de armazenamento** (uma por
página, na ordem de leitura) — decisão da fatia 1: um envio manuscrito tem 1–2
folhas fotografadas, e o pipeline (Bloco 2b) fará OCR página a página. Um PDF
digital é a lista de um item só.
"""
from datetime import datetime

from sqlalchemy import and_, insert, select, update
from sqlalchemy.dialects.postgresql import insert as pg_insert
from sqlalchemy.engine import Row
from sqlalchemy.ext.asyncio import AsyncConnection

from app import schema


async def turma_do_aluno(conn: AsyncConnection, usuario_id: int) -> int | None:
    a, at = schema.associacao, schema.associacao_turma
    stmt = (
        select(at.c.turma_id)
        .select_from(a.join(at, at.c.associacao_id == a.c.id))
        .where(a.c.usuario_id == usuario_id, a.c.papel == "aluno")
        .limit(1)
    )
    return (await conn.execute(stmt)).scalar_one_or_none()


async def atribuicoes_do_aluno(
    conn: AsyncConnection, usuario_id: int, turma_id: int
) -> list[Row]:
    """Atribuições da turma + o envio deste aluno (se houver), mais recentes primeiro."""
    ra, r = schema.redacao_atribuicao, schema.redacao
    stmt = (
        select(
            ra.c.id.label("atribuicao_id"),
            ra.c.tema,
            ra.c.prazo,
            r.c.id.label("redacao_id"),
            r.c.status,
            r.c.enviada_em,
            r.c.arquivo_ref,
        )
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


async def buscar_atribuicao(conn: AsyncConnection, atribuicao_id: int) -> Row | None:
    ra = schema.redacao_atribuicao
    stmt = select(ra.c.id, ra.c.turma_id, ra.c.tema, ra.c.prazo).where(
        ra.c.id == atribuicao_id
    )
    return (await conn.execute(stmt)).first()


async def buscar_envio(
    conn: AsyncConnection, atribuicao_id: int, usuario_id: int
) -> Row | None:
    r = schema.redacao
    stmt = select(r.c.id, r.c.status, r.c.arquivo_ref).where(
        r.c.atribuicao_id == atribuicao_id, r.c.usuario_id == usuario_id
    )
    return (await conn.execute(stmt)).first()


async def criar_envio(
    conn: AsyncConnection,
    atribuicao_id: int,
    usuario_id: int,
    formato: str,
    arquivo_ref: str,
    enviada_em: datetime,
) -> int:
    r = schema.redacao
    stmt = (
        insert(r)
        .values(
            atribuicao_id=atribuicao_id,
            usuario_id=usuario_id,
            formato=formato,
            arquivo_ref=arquivo_ref,
            status="enviada",
            enviada_em=enviada_em,
        )
        .returning(r.c.id)
    )
    return (await conn.execute(stmt)).scalar_one()


async def substituir_envio(
    conn: AsyncConnection,
    redacao_id: int,
    formato: str,
    arquivo_ref: str,
    enviada_em: datetime,
) -> None:
    """Reenvio antes da análise: troca os arquivos e volta ao início do ciclo."""
    r = schema.redacao
    stmt = (
        update(r)
        .where(r.c.id == redacao_id)
        .values(
            formato=formato,
            arquivo_ref=arquivo_ref,
            status="enviada",
            enviada_em=enviada_em,
            texto_extraido=None,
            analisada_em=None,
        )
    )
    await conn.execute(stmt)


# ─────────────────── pipeline (tarefas da fila — Bloco 2b) ───────────────────


async def buscar_redacao(conn: AsyncConnection, redacao_id: int) -> Row | None:
    r = schema.redacao
    stmt = select(
        r.c.id, r.c.status, r.c.formato, r.c.arquivo_ref, r.c.texto_extraido
    ).where(r.c.id == redacao_id)
    return (await conn.execute(stmt)).first()


async def atualizar_status(
    conn: AsyncConnection, redacao_id: int, status: str
) -> None:
    r = schema.redacao
    await conn.execute(
        update(r).where(r.c.id == redacao_id).values(status=status)
    )


async def gravar_texto(conn: AsyncConnection, redacao_id: int, texto: str) -> None:
    r = schema.redacao
    await conn.execute(
        update(r).where(r.c.id == redacao_id).values(texto_extraido=texto)
    )


async def gravar_analise(
    conn: AsyncConnection, redacao_id: int, anotacoes: dict
) -> None:
    """Upsert: um reenvio reprocessado sobrescreve a análise anterior."""
    ra = schema.redacao_analise
    stmt = (
        pg_insert(ra)
        .values(redacao_id=redacao_id, anotacoes=anotacoes)
        .on_conflict_do_update(
            index_elements=[ra.c.redacao_id], set_={"anotacoes": anotacoes}
        )
    )
    await conn.execute(stmt)


async def buscar_analise(conn: AsyncConnection, redacao_id: int) -> Row | None:
    ra = schema.redacao_analise
    stmt = select(ra.c.redacao_id, ra.c.anotacoes).where(
        ra.c.redacao_id == redacao_id
    )
    return (await conn.execute(stmt)).first()


async def finalizar_analisada(
    conn: AsyncConnection, redacao_id: int, quando: datetime
) -> None:
    r = schema.redacao
    await conn.execute(
        update(r)
        .where(r.c.id == redacao_id)
        .values(status="analisada", analisada_em=quando)
    )
