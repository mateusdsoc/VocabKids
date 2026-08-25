"""Repositório do domínio redação B2C — acesso ao Postgres (SQLAlchemy Core)."""
from datetime import date, datetime, timedelta, timezone

from sqlalchemy import func, select
from sqlalchemy.engine import Row
from sqlalchemy.ext.asyncio import AsyncConnection

from app import schema
from app.redacao.analisador import PalavraExtraida


async def faixa_etaria_do_perfil(conn: AsyncConnection, usuario_id: int) -> str | None:
    pc = schema.perfil_crianca
    stmt = select(pc.c.faixa_etaria).where(pc.c.usuario_id == usuario_id)
    return (await conn.execute(stmt)).scalar_one_or_none()


async def tema_disponivel(conn: AsyncConnection, *, faixa_etaria: str, usuario_id: int) -> Row | None:
    """Tema do catálogo da faixa, sem repetir os últimos 6 meses do PERFIL
    (R-RD-2). Ordem determinística (id) — não há aleatoriedade a calibrar."""
    tc, ra = schema.tema_catalogo, schema.redacao_atribuicao
    seis_meses_atras = datetime.now(timezone.utc) - timedelta(days=180)
    usados = (
        select(ra.c.tema_catalogo_id)
        .where(
            ra.c.usuario_id == usuario_id,
            ra.c.tema_catalogo_id.is_not(None),
            ra.c.created_at >= seis_meses_atras,
        )
        .scalar_subquery()
    )
    stmt = (
        select(tc.c.id, tc.c.titulo, tc.c.enunciado, tc.c.apoio, tc.c.genero)
        .where(tc.c.faixa_etaria == faixa_etaria, tc.c.id.not_in(usados))
        .order_by(tc.c.id)
        .limit(1)
    )
    return (await conn.execute(stmt)).first()


async def atribuicao_mais_recente(conn: AsyncConnection, usuario_id: int) -> Row | None:
    ra = schema.redacao_atribuicao
    stmt = (
        select(ra.c.id, ra.c.tema, ra.c.created_at, ra.c.origem)
        .where(ra.c.usuario_id == usuario_id)
        .order_by(ra.c.created_at.desc())
        .limit(1)
    )
    return (await conn.execute(stmt)).first()


async def criar_atribuicao(
    conn: AsyncConnection, *, usuario_id: int, tema_catalogo_id: int, tema: str, origem: str
) -> int:
    ra = schema.redacao_atribuicao
    stmt = (
        ra.insert()
        .values(
            usuario_id=usuario_id,
            tema_catalogo_id=tema_catalogo_id,
            tema=tema,
            origem=origem,
            prazo=date.today() + timedelta(days=15),
        )
        .returning(ra.c.id)
    )
    return (await conn.execute(stmt)).scalar_one()


async def listar_atribuicoes(conn: AsyncConnection, usuario_id: int) -> list[Row]:
    """Atribuições do perfil + status do envio dele, se houver."""
    ra, r = schema.redacao_atribuicao, schema.redacao
    stmt = (
        select(
            ra.c.id,
            ra.c.tema,
            ra.c.prazo,
            ra.c.origem,
            ra.c.created_at,
            r.c.id.label("redacao_id"),
            r.c.status,
            r.c.enviada_em,
        )
        .select_from(
            ra.outerjoin(r, (r.c.atribuicao_id == ra.c.id) & (r.c.usuario_id == usuario_id))
        )
        .where(ra.c.usuario_id == usuario_id)
        .order_by(ra.c.created_at.desc())
    )
    return list((await conn.execute(stmt)).all())


async def contar_extras_do_mes(conn: AsyncConnection, usuario_id: int) -> int:
    """R-RD-4: no máx. 2 temas extras/mês/perfil — mês corrente em UTC."""
    ra = schema.redacao_atribuicao
    inicio_mes = datetime.now(timezone.utc).replace(
        day=1, hour=0, minute=0, second=0, microsecond=0
    )
    stmt = select(func.count()).where(
        ra.c.usuario_id == usuario_id,
        ra.c.origem == "sob_demanda",
        ra.c.created_at >= inicio_mes,
    )
    return (await conn.execute(stmt)).scalar_one()


async def buscar_atribuicao(conn: AsyncConnection, atribuicao_id: int) -> Row | None:
    ra = schema.redacao_atribuicao
    stmt = select(ra.c.id, ra.c.usuario_id, ra.c.tema).where(ra.c.id == atribuicao_id)
    return (await conn.execute(stmt)).first()


async def criar_envio(
    conn: AsyncConnection, *, atribuicao_id: int, usuario_id: int, formato: str, texto_extraido: str
) -> int:
    r = schema.redacao
    stmt = (
        r.insert()
        .values(
            atribuicao_id=atribuicao_id,
            usuario_id=usuario_id,
            formato=formato,
            texto_extraido=texto_extraido,
            status="processando",
            enviada_em=func.now(),
        )
        .returning(r.c.id)
    )
    return (await conn.execute(stmt)).scalar_one()


async def marcar_erro_ingestao(conn: AsyncConnection, redacao_id: int, motivo: str) -> None:
    r = schema.redacao
    await conn.execute(
        r.update().where(r.c.id == redacao_id).values(status="erro_ingestao", risco_motivo=motivo)
    )


async def marcar_revisao_humana(conn: AsyncConnection, redacao_id: int, motivo: str | None) -> None:
    r = schema.redacao
    await conn.execute(
        r.update()
        .where(r.c.id == redacao_id)
        .values(status="revisao_humana", risco_sinalizado=True, risco_motivo=motivo)
    )


async def gravar_analise(
    conn: AsyncConnection,
    redacao_id: int,
    *,
    pontos_fortes: list[str],
    anotacoes: list[dict],
    dimensoes: list[str],
    niveis_dimensao: dict[str, str],
) -> None:
    r, ra = schema.redacao, schema.redacao_analise
    await conn.execute(
        ra.insert().values(
            redacao_id=redacao_id,
            anotacoes={
                "versao": 1,
                "dimensoes": dimensoes,
                "pontos_fortes": pontos_fortes,
                "anotacoes": anotacoes,
                "niveis_dimensao": niveis_dimensao,
            },
        )
    )
    await conn.execute(
        r.update().where(r.c.id == redacao_id).values(status="analisada", analisada_em=func.now())
    )


async def gravar_palavras(conn: AsyncConnection, redacao_id: int, palavras: list[PalavraExtraida]) -> None:
    if not palavras:
        return
    rp = schema.redacao_palavra
    await conn.execute(
        rp.insert(),
        [
            {"redacao_id": redacao_id, "texto": p.texto, "lema": p.lema, "tipo": p.tipo}
            for p in palavras
        ],
    )


async def marcar_erro_analise(conn: AsyncConnection, redacao_id: int) -> None:
    r = schema.redacao
    await conn.execute(r.update().where(r.c.id == redacao_id).values(status="erro_analise"))


async def buscar_redacao(conn: AsyncConnection, redacao_id: int) -> Row | None:
    r = schema.redacao
    stmt = select(
        r.c.id, r.c.atribuicao_id, r.c.usuario_id, r.c.status, r.c.texto_extraido, r.c.risco_sinalizado
    ).where(r.c.id == redacao_id)
    return (await conn.execute(stmt)).first()


async def buscar_analise(conn: AsyncConnection, redacao_id: int) -> Row | None:
    ra = schema.redacao_analise
    stmt = select(ra.c.anotacoes).where(ra.c.redacao_id == redacao_id)
    return (await conn.execute(stmt)).first()


async def historico_analises(conn: AsyncConnection, usuario_id: int) -> list[Row]:
    """Análises concluídas do perfil, mais antiga primeiro (Fase 5 — evolução
    por dimensão ao longo do tempo, R-RD-6)."""
    r, ra = schema.redacao, schema.redacao_analise
    stmt = (
        select(r.c.id.label("redacao_id"), r.c.analisada_em, ra.c.anotacoes)
        .select_from(ra.join(r, r.c.id == ra.c.redacao_id))
        .where(r.c.usuario_id == usuario_id)
        .order_by(r.c.analisada_em)
    )
    return list((await conn.execute(stmt)).all())
