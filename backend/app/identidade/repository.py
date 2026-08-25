"""Repositório do domínio identidade — acesso ao Postgres (SQLAlchemy Core).

Um lugar só para o SQL deste agregado (decisão #2 do Bloco 3). Serviços chamam
estas funções; não há SQL cru em rotas nem em serviços.

B2C (docs/plano_b2c.md Fase 1): entrada por turma/escola saiu daqui. Fica só o
que serve identidade familiar (conta do responsável + perfis de criança).
"""
from sqlalchemy import func, insert, select
from sqlalchemy.engine import Row
from sqlalchemy.ext.asyncio import AsyncConnection

from app import schema


# ─────────────────────────── Responsável / conta ───────────────────────────

async def buscar_usuario_por_email(conn: AsyncConnection, email: str) -> Row | None:
    u = schema.usuario
    stmt = select(u.c.id, u.c.nome, u.c.senha_hash).where(
        func.lower(u.c.email) == func.lower(email)
    )
    return (await conn.execute(stmt)).first()


async def buscar_conta_completa(conn: AsyncConnection, responsavel_usuario_id: int) -> Row | None:
    c, u = schema.conta, schema.usuario
    stmt = (
        select(c.c.id, u.c.nome, u.c.email)
        .select_from(c.join(u, u.c.id == c.c.responsavel_usuario_id))
        .where(c.c.responsavel_usuario_id == responsavel_usuario_id)
    )
    return (await conn.execute(stmt)).first()


async def criar_conta_responsavel(
    conn: AsyncConnection,
    *,
    nome: str,
    email: str,
    senha_hash: str,
    consentimento_versao: str,
) -> tuple[int, int]:
    """Cria usuario + associação (papel=responsavel) + conta. Retorna
    (usuario_id, conta_id)."""
    usuario_id = (
        await conn.execute(
            insert(schema.usuario)
            .values(nome=nome, email=email, senha_hash=senha_hash)
            .returning(schema.usuario.c.id)
        )
    ).scalar_one()
    await conn.execute(
        insert(schema.associacao).values(usuario_id=usuario_id, papel="responsavel")
    )
    conta_id = (
        await conn.execute(
            insert(schema.conta)
            .values(
                responsavel_usuario_id=usuario_id,
                consentimento_lgpd_em=func.now(),
                consentimento_versao=consentimento_versao,
            )
            .returning(schema.conta.c.id)
        )
    ).scalar_one()
    return usuario_id, conta_id


async def buscar_senha_hash(conn: AsyncConnection, usuario_id: int) -> str | None:
    u = schema.usuario
    stmt = select(u.c.senha_hash).where(u.c.id == usuario_id)
    return (await conn.execute(stmt)).scalar_one_or_none()


async def buscar_conta_por_responsavel(conn: AsyncConnection, usuario_id: int) -> Row | None:
    c = schema.conta
    stmt = select(c.c.id).where(c.c.responsavel_usuario_id == usuario_id)
    return (await conn.execute(stmt)).first()


async def excluir_conta_e_perfis(conn: AsyncConnection, responsavel_usuario_id: int) -> None:
    """Apaga a conta inteira: os `usuario` de cada criança (CASCADE arrasta
    perfil_crianca, aluno_progresso, aluno_palavra, sessão…) e, por fim, o
    `usuario` do responsável (CASCADE arrasta `conta`). R-ID-6: exigido pela
    Apple 5.1.1(v) e pela LGPD — a exclusão remove os dados da família toda,
    não só o login."""
    from sqlalchemy import delete

    conta = await buscar_conta_por_responsavel(conn, responsavel_usuario_id)
    if conta is not None:
        perfis = await listar_perfis_da_conta(conn, conta.id)
        for p in perfis:
            await conn.execute(
                delete(schema.usuario).where(schema.usuario.c.id == p.usuario_id)
            )
    await conn.execute(
        delete(schema.usuario).where(schema.usuario.c.id == responsavel_usuario_id)
    )


# ─────────────────────────── Perfis de criança ───────────────────────────

async def contar_perfis_da_conta(conn: AsyncConnection, conta_id: int) -> int:
    pc = schema.perfil_crianca
    stmt = select(func.count()).where(pc.c.conta_id == conta_id)
    return (await conn.execute(stmt)).scalar_one()


async def criar_perfil_crianca(
    conn: AsyncConnection,
    *,
    conta_id: int,
    apelido: str,
    ano_nascimento: int,
    faixa_etaria: str,
) -> int:
    """Cria usuario (a criança) + associação (papel=aluno) + progresso +
    perfil_crianca. Retorna o usuario_id da criança."""
    usuario_id = (
        await conn.execute(
            insert(schema.usuario).values(nome=apelido).returning(schema.usuario.c.id)
        )
    ).scalar_one()
    await conn.execute(
        insert(schema.associacao).values(usuario_id=usuario_id, papel="aluno")
    )
    await conn.execute(insert(schema.aluno_progresso).values(usuario_id=usuario_id))
    await conn.execute(
        insert(schema.perfil_crianca).values(
            usuario_id=usuario_id,
            conta_id=conta_id,
            apelido=apelido,
            ano_nascimento=ano_nascimento,
            faixa_etaria=faixa_etaria,
        )
    )
    return usuario_id


async def listar_perfis_da_conta(conn: AsyncConnection, conta_id: int) -> list[Row]:
    pc = schema.perfil_crianca
    stmt = (
        select(pc.c.usuario_id, pc.c.apelido, pc.c.faixa_etaria, pc.c.ano_escolar)
        .where(pc.c.conta_id == conta_id)
        .order_by(pc.c.created_at)
    )
    return list((await conn.execute(stmt)).all())


async def buscar_perfil_na_conta(
    conn: AsyncConnection, conta_id: int, usuario_id: int
) -> Row | None:
    """Confirma que o perfil pertence à conta antes de emitir token de criança
    (evita um responsável entrar como filho de outra família)."""
    pc = schema.perfil_crianca
    stmt = select(pc.c.usuario_id).where(
        pc.c.conta_id == conta_id, pc.c.usuario_id == usuario_id
    )
    return (await conn.execute(stmt)).first()


# ─────────────────────────── Sessão (auth) ───────────────────────────

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
    """Perfil + progresso da criança (`GET /v1/me`) — só faz sentido para
    usuário com papel='aluno'."""
    u, a, pc = schema.usuario, schema.associacao, schema.perfil_crianca
    stmt = (
        select(
            u.c.id.label("usuario_id"),
            u.c.nome,
            a.c.papel,
            pc.c.apelido,
            pc.c.faixa_etaria,
            pc.c.ano_escolar,
        )
        .select_from(
            u.join(a, a.c.usuario_id == u.c.id).outerjoin(pc, pc.c.usuario_id == u.c.id)
        )
        .where(u.c.id == usuario_id)
        .limit(1)
    )
    return (await conn.execute(stmt)).first()


async def dominadas_na_semana(conn: AsyncConnection, usuario_id: int, inicio) -> int:
    ap = schema.aluno_palavra
    stmt = select(func.count()).where(
        ap.c.usuario_id == usuario_id, ap.c.dominada_em >= inicio
    )
    return (await conn.execute(stmt)).scalar_one()


async def buscar_progresso(conn: AsyncConnection, usuario_id: int) -> Row | None:
    p = schema.aluno_progresso
    stmt = select(
        p.c.xp_total,
        p.c.no_atual_id,
        p.c.palavras_dominadas,
        p.c.nivel_dificuldade_atual,
    ).where(p.c.usuario_id == usuario_id)
    return (await conn.execute(stmt)).first()
