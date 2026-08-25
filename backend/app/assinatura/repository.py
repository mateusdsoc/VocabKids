"""Repositório do domínio assinatura — acesso ao Postgres (SQLAlchemy Core)."""
from datetime import datetime

from sqlalchemy import func, select, update
from sqlalchemy.dialects.postgresql import insert as pg_insert
from sqlalchemy.engine import Row
from sqlalchemy.ext.asyncio import AsyncConnection

from app import schema

# Status que dão acesso ao gameplay (R-AS-4: período de graça mantém acesso
# enquanto a Apple tenta cobrar de novo).
STATUS_COM_ACESSO = ("ativa", "em_periodo_de_graca")


async def conta_do_perfil(conn: AsyncConnection, usuario_id: int) -> int | None:
    """`conta_id` da criança logada; `None` para aluno sem `perfil_crianca`
    (B2B congelado, ligado por turma) — quem chama trata como "sem paywall"."""
    pc = schema.perfil_crianca
    stmt = select(pc.c.conta_id).where(pc.c.usuario_id == usuario_id)
    return (await conn.execute(stmt)).scalar_one_or_none()


async def assinatura_ativa_da_conta(conn: AsyncConnection, conta_id: int) -> Row | None:
    """A assinatura mais recente da conta, se estiver com acesso liberado."""
    a = schema.assinatura
    stmt = (
        select(a.c.id, a.c.status, a.c.expira_em, a.c.em_trial)
        .where(a.c.conta_id == conta_id, a.c.status.in_(STATUS_COM_ACESSO))
        .order_by(a.c.atualizada_em.desc())
        .limit(1)
    )
    return (await conn.execute(stmt)).first()


async def assinatura_mais_recente_da_conta(conn: AsyncConnection, conta_id: int) -> Row | None:
    """A assinatura mais recente da conta, qualquer status (para `GET /v1/assinatura`
    informar "expirada"/"cancelada" em vez de só "nunca assinou")."""
    a = schema.assinatura
    stmt = (
        select(a.c.status, a.c.expira_em, a.c.em_trial)
        .where(a.c.conta_id == conta_id)
        .order_by(a.c.atualizada_em.desc())
        .limit(1)
    )
    return (await conn.execute(stmt)).first()


async def xp_total_do_aluno(conn: AsyncConnection, usuario_id: int) -> int:
    p = schema.aluno_progresso
    stmt = select(p.c.xp_total).where(p.c.usuario_id == usuario_id)
    return (await conn.execute(stmt)).scalar_one_or_none() or 0


async def limiar_gratis_xp(conn: AsyncConnection) -> int | None:
    """XP do último nó do 1º destino do 1º país — teto do free tier (R-AS-2).
    Lido do catálogo semeado (não hardcoded), então acompanha sozinho qualquer
    recalibração de `seed_trilha.py` (MVP hoje: 4500×4 = 18000). `None` se a
    trilha ainda não foi semeada — quem chama trata como "sem limite"
    (não é o gate que deve derrubar um ambiente sem `seed_trilha` rodado)."""
    d, p, tn = schema.destino, schema.pais, schema.trilha_no
    primeiro_destino_id = (
        await conn.execute(
            select(d.c.id)
            .select_from(d.join(p, p.c.id == d.c.pais_id))
            .where(p.c.ordem == 1, d.c.ordem == 1)
        )
    ).scalar_one_or_none()
    if primeiro_destino_id is None:
        return None
    return (
        await conn.execute(
            select(func.max(tn.c.xp_limiar)).where(tn.c.destino_id == primeiro_destino_id)
        )
    ).scalar_one_or_none()


async def inserir_evento_loja(
    conn: AsyncConnection, *, loja: str, tipo: str, payload: dict, dedup: str
) -> bool:
    """Grava o evento cru; `False` se já existia (R-AS-6: reentrega é no-op)."""
    stmt = (
        pg_insert(schema.evento_loja)
        .values(loja=loja, tipo=tipo, payload=payload, assinatura_dedup=dedup)
        .on_conflict_do_nothing(index_elements=[schema.evento_loja.c.assinatura_dedup])
        .returning(schema.evento_loja.c.id)
    )
    return (await conn.execute(stmt)).first() is not None


async def marcar_evento_processado(conn: AsyncConnection, dedup: str) -> None:
    await conn.execute(
        update(schema.evento_loja)
        .where(schema.evento_loja.c.assinatura_dedup == dedup)
        .values(processado_em=func.now())
    )


async def upsert_assinatura(
    conn: AsyncConnection,
    *,
    conta_id: int,
    loja: str,
    produto_id: str,
    transacao_original_id: str,
    status: str | None,
    expira_em: datetime | None,
    em_trial: bool,
    ambiente: str,
) -> None:
    """Upsert por `transacao_original_id` (chave natural da loja). `status=None`
    (ex.: evento CANCELLATION, que não muda o acesso até a expiração de fato)
    preserva o status atual — só atualiza os demais campos."""
    a = schema.assinatura
    valores = dict(
        conta_id=conta_id,
        loja=loja,
        produto_id=produto_id,
        transacao_original_id=transacao_original_id,
        status=status or "ativa",  # 1ª vez que vemos esta transação: teve que ter começado ativa
        expira_em=expira_em,
        em_trial=em_trial,
        ambiente=ambiente,
    )
    stmt = pg_insert(a).values(**valores)
    set_ = {
        "produto_id": stmt.excluded.produto_id,
        "expira_em": stmt.excluded.expira_em,
        "em_trial": stmt.excluded.em_trial,
        "ambiente": stmt.excluded.ambiente,
        "atualizada_em": func.now(),
    }
    if status is not None:
        set_["status"] = status
    stmt = stmt.on_conflict_do_update(
        index_elements=[a.c.transacao_original_id], set_=set_
    )
    await conn.execute(stmt)
