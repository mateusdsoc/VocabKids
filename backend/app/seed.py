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

    return {"escola_id": escola_id, "turma_id": turma_id, "codigo_turma": CODIGO_TURMA}


if __name__ == "__main__":
    print("seed ok:", asyncio.run(seed()))
