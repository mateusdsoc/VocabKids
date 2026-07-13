"""Repositório do domínio identidade — acesso ao Postgres (SQLAlchemy Core).

Um lugar só para o SQL deste agregado (decisão #2 do Bloco 3). Serviços chamam
estas funções; não há SQL cru em rotas nem em serviços.
"""
from sqlalchemy import func, insert, select
from sqlalchemy.engine import Row
from sqlalchemy.ext.asyncio import AsyncConnection

from app import schema


async def buscar_turma_por_codigo(conn: AsyncConnection, codigo: str) -> Row | None:
    stmt = select(
        schema.turma.c.id,
        schema.turma.c.escola_id,
        schema.turma.c.nome,
        schema.turma.c.ano_escolar,
    ).where(schema.turma.c.codigo_turma == codigo)
    return (await conn.execute(stmt)).first()


async def buscar_aluno_na_turma(
    conn: AsyncConnection, turma_id: int, nome: str
) -> Row | None:
    """Aluno (papel='aluno') de uma turma cujo nome bate (case-insensitive)."""
    u, a, at = schema.usuario, schema.associacao, schema.associacao_turma
    stmt = (
        select(u.c.id, u.c.nome)
        .select_from(
            u.join(a, a.c.usuario_id == u.c.id).join(
                at, at.c.associacao_id == a.c.id
            )
        )
        .where(
            a.c.papel == "aluno",
            at.c.turma_id == turma_id,
            func.lower(u.c.nome) == func.lower(nome),
        )
        .limit(1)
    )
    return (await conn.execute(stmt)).first()


async def criar_aluno(
    conn: AsyncConnection, escola_id: int, turma_id: int, nome: str
) -> int:
    """Cria usuario + associação (aluno) + vínculo de turma + linha de progresso."""
    usuario_id = (
        await conn.execute(
            insert(schema.usuario)
            .values(nome=nome)
            .returning(schema.usuario.c.id)
        )
    ).scalar_one()
    associacao_id = (
        await conn.execute(
            insert(schema.associacao)
            .values(usuario_id=usuario_id, escola_id=escola_id, papel="aluno")
            .returning(schema.associacao.c.id)
        )
    ).scalar_one()
    await conn.execute(
        insert(schema.associacao_turma).values(
            associacao_id=associacao_id, turma_id=turma_id
        )
    )
    # Demais colunas têm server_default (xp 0, nivel 1, …) — ver schema.aluno_progresso.
    await conn.execute(
        insert(schema.aluno_progresso).values(usuario_id=usuario_id)
    )
    return usuario_id


async def buscar_usuario(conn: AsyncConnection, usuario_id: int) -> Row | None:
    """Usuário + papel (da associação — fonte da verdade para autorização)."""
    u, a = schema.usuario, schema.associacao
    stmt = (
        select(u.c.id, u.c.nome, a.c.papel)
        .select_from(u.outerjoin(a, a.c.usuario_id == u.c.id))
        .where(u.c.id == usuario_id)
        .limit(1)
    )
    return (await conn.execute(stmt)).first()


async def buscar_perfil(conn: AsyncConnection, usuario_id: int) -> Row | None:
    """Perfil + escola + turma. Assume aluno (única persona da fatia A)."""
    u, a, e = schema.usuario, schema.associacao, schema.escola
    at, t = schema.associacao_turma, schema.turma
    stmt = (
        select(
            u.c.id.label("usuario_id"),
            u.c.nome,
            a.c.papel,
            e.c.id.label("escola_id"),
            e.c.nome.label("escola_nome"),
            t.c.id.label("turma_id"),
            t.c.nome.label("turma_nome"),
            t.c.ano_escolar,
        )
        .select_from(
            u.join(a, a.c.usuario_id == u.c.id)
            .outerjoin(e, e.c.id == a.c.escola_id)
            .outerjoin(at, at.c.associacao_id == a.c.id)
            .outerjoin(t, t.c.id == at.c.turma_id)
        )
        .where(u.c.id == usuario_id)
        .limit(1)
    )
    return (await conn.execute(stmt)).first()


async def buscar_progresso(conn: AsyncConnection, usuario_id: int) -> Row | None:
    p = schema.aluno_progresso
    stmt = select(
        p.c.xp_total,
        p.c.no_atual_id,
        p.c.palavras_dominadas,
        p.c.nivel_dificuldade_atual,
    ).where(p.c.usuario_id == usuario_id)
    return (await conn.execute(stmt)).first()
