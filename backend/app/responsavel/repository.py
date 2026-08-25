"""Repositório do domínio responsável (Fase 5, `docs/plano_b2c.md` §08).

Mesma pergunta do painel do professor (`app/professor/repository.py`), outra
pessoa — escopo por `conta_id`/`usuario_id` em vez de `turma_id`. Sem cruzar
com o domínio congelado; consultas próprias, mesmo padrão de SQLAlchemy Core.
"""
from datetime import datetime

from sqlalchemy import func, select
from sqlalchemy.engine import Row
from sqlalchemy.ext.asyncio import AsyncConnection

from app import schema


async def definir_pin_hash(conn: AsyncConnection, conta_id: int, pin_hash: str) -> None:
    c = schema.conta
    await conn.execute(c.update().where(c.c.id == conta_id).values(pin_hash=pin_hash))


async def buscar_pin_hash(conn: AsyncConnection, conta_id: int) -> str | None:
    c = schema.conta
    stmt = select(c.c.pin_hash).where(c.c.id == conta_id)
    return (await conn.execute(stmt)).scalar_one_or_none()


async def sessoes_e_minutos_da_semana(
    conn: AsyncConnection, usuario_id: int, inicio: datetime
) -> tuple[int, int]:
    """Sessões concluídas na semana + minutos totais (soma de
    `finalizada_em - iniciada_em`, arredondado pra baixo)."""
    s = schema.sessao
    duracao = func.extract("epoch", s.c.finalizada_em - s.c.iniciada_em)
    stmt = select(func.count(), func.coalesce(func.sum(duracao), 0)).where(
        s.c.usuario_id == usuario_id,
        s.c.finalizada_em.is_not(None),
        s.c.finalizada_em >= inicio,
    )
    total, segundos = (await conn.execute(stmt)).one()
    return int(total), int(segundos // 60)


async def palavras_aprendidas_na_semana(
    conn: AsyncConnection, usuario_id: int, inicio: datetime, limite: int = 5
) -> list[Row]:
    """As últimas `limite` palavras dominadas na semana — R-RS §08 item 3, o
    "de maior valor percebido": 5 palavras + definição pro pai conversar com
    o filho."""
    ap, p = schema.aluno_palavra, schema.palavra
    stmt = (
        select(p.c.lema, p.c.definicao)
        .select_from(ap.join(p, p.c.id == ap.c.palavra_id))
        .where(ap.c.usuario_id == usuario_id, ap.c.dominada_em.is_not(None), ap.c.dominada_em >= inicio)
        .order_by(ap.c.dominada_em.desc())
        .limit(limite)
    )
    return list((await conn.execute(stmt)).all())
