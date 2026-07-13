"""Seed mínimo da fatia A: 1 escola + 1 turma com código provisório.

Idempotente — re-rodar não duplica. Uso:

    python -m app.seed

O conteúdo de verdade da fatia A (trilha, colecionáveis, banco base) entra por
seed próprio mais tarde (arquitetura, Bloco 3 — "Conteúdo/seed"). Aqui é só o
mínimo para exercitar o acesso por código de turma.
"""
import asyncio

from sqlalchemy import insert, select

from app import schema
from app.db import engine

ESCOLA_NOME = "Escola Demonstração"
TURMA_NOME = "7º Ano A"
TURMA_ANO = 7
CODIGO_TURMA = "DEMO7A"
PROFESSOR_NOME = "Professora Demo"


async def seed() -> dict:
    async with engine.begin() as conn:
        escola_id = (
            await conn.execute(
                select(schema.escola.c.id).where(schema.escola.c.nome == ESCOLA_NOME)
            )
        ).scalar_one_or_none()
        if escola_id is None:
            escola_id = (
                await conn.execute(
                    insert(schema.escola)
                    .values(nome=ESCOLA_NOME)
                    .returning(schema.escola.c.id)
                )
            ).scalar_one()

        turma_id = (
            await conn.execute(
                select(schema.turma.c.id).where(
                    schema.turma.c.codigo_turma == CODIGO_TURMA
                )
            )
        ).scalar_one_or_none()
        if turma_id is None:
            turma_id = (
                await conn.execute(
                    insert(schema.turma)
                    .values(
                        escola_id=escola_id,
                        nome=TURMA_NOME,
                        ano_escolar=TURMA_ANO,
                        codigo_turma=CODIGO_TURMA,
                    )
                    .returning(schema.turma.c.id)
                )
            ).scalar_one()

        # Professora demo (papel professor, associada à escola e à turma).
        # Não há rota de login de professor na fatia A — o token sai do
        # `python -m app.seed` (abaixo) enquanto o acesso real não chega (fatia C).
        professor_id = (
            await conn.execute(
                select(schema.associacao.c.usuario_id)
                .select_from(
                    schema.usuario.join(
                        schema.associacao,
                        schema.associacao.c.usuario_id == schema.usuario.c.id,
                    )
                )
                .where(
                    schema.usuario.c.nome == PROFESSOR_NOME,
                    schema.associacao.c.papel == "professor",
                )
            )
        ).scalar_one_or_none()
        if professor_id is None:
            professor_id = (
                await conn.execute(
                    insert(schema.usuario)
                    .values(nome=PROFESSOR_NOME)
                    .returning(schema.usuario.c.id)
                )
            ).scalar_one()
            associacao_id = (
                await conn.execute(
                    insert(schema.associacao)
                    .values(
                        usuario_id=professor_id, escola_id=escola_id, papel="professor"
                    )
                    .returning(schema.associacao.c.id)
                )
            ).scalar_one()
            await conn.execute(
                insert(schema.associacao_turma).values(
                    associacao_id=associacao_id, turma_id=turma_id
                )
            )

    return {
        "escola_id": escola_id,
        "turma_id": turma_id,
        "codigo_turma": CODIGO_TURMA,
        "professor_id": professor_id,
    }


if __name__ == "__main__":
    resultado = asyncio.run(seed())
    print("seed ok:", resultado)
    # Conveniência de dev: um token de professor para exercitar as rotas
    # (exige JWT_SECRET configurado; o login real do professor é fatia C).
    from app.config import settings

    if settings.jwt_secret:
        from app.identidade.auth import criar_token

        print("token professor (demo):", criar_token(resultado["professor_id"], "professor"))
