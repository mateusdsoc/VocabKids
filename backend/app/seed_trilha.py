"""Seed da trilha + colecionáveis (fatia A) — catálogo, não dado de aluno.

**MVP B2C** (decisão do dono, 24/08/2026 — `docs/plano_b2c.md`, "Escopo do
MVP"): só os 4 destinos com arte já pronta (`docs/referencia_arte.md`) — Rio,
Foz do Iguaçu e Amazônia (Brasil) + Paris (França). 2 países, 4 destinos, 16
nós (4 por destino) e 11 colecionáveis (4 cartões-postais + 2 carimbos + 5
selos). Japão e o restante de Brasil/França ficam para pós-MVP — o catálogo
completo (3 países / 20 destinos / 80 nós / 28 peças) está registrado em
`docs/referencia_arte.md` e pode voltar aqui sem mudar schema nem lógica,
só a lista `PAISES` abaixo. Idempotente (não duplica). Uso:

    python -m app.seed_trilha

Sobre `asset_ref`: é só uma **referência** (a arte é renderizada pelo app
Flutter) — os 4 destinos do MVP já têm asset real; o restante do catálogo
(quando voltar) usa placeholders até a arte ser gerada.

Sobre `trilha_no.xp_limiar`: guardamos o **XP total acumulado** para concluir o nó
(incremento de ~4.500 por nó, conforme arquitetura). Assim "nó atual" e "concluído"
saem de uma comparação direta com `aluno_progresso.xp_total`, sem somatórios.

`colecionavel.referencia` liga a recompensa ao que a dispara, por convenção:
`destino:<id>` (cartão), `pais:<id>` (carimbo), `feito:<chave>` (selo).
"""
import asyncio

from sqlalchemy import insert, select

from app import schema
from app.db import engine

NOS_POR_DESTINO = 4
XP_POR_NO = 4500  # incremento de XP por nó (limiar é cumulativo)

PAISES = [
    {
        "nome": "Brasil",
        "carimbo": "carimbo/brasil.png",
        "destinos": [
            ("Rio de Janeiro — Cristo Redentor", "cartao/rio.png"),
            ("Foz do Iguaçu — Cataratas", "cartao/foz_iguacu.png"),
            ("Amazônia — Encontro das Águas", "cartao/amazonia.png"),
        ],
    },
    {
        "nome": "França",
        "carimbo": "carimbo/franca.png",
        "destinos": [
            ("Paris — Torre Eiffel", "cartao/paris.png"),
        ],
    },
]

# Selos de feito (5). A `chave` é o gatilho usado pela lógica de recompensa.
SELOS = [
    ("redacao_1", "selo/primeira_carta.png"),       # 1ª redação enviada (fatia C)
    ("combo_10", "selo/bussola.png"),               # combo de 10 acertos seguidos
    ("dominadas_25", "selo/mala.png"),              # 25 palavras dominadas
    ("dominadas_100", "selo/globo.png"),            # 100 palavras dominadas
    ("dominadas_250", "selo/aviao.png"),            # 250 palavras dominadas
]


async def seed_trilha() -> dict:
    async with engine.begin() as conn:
        ja_existe = (await conn.execute(select(schema.pais.c.id).limit(1))).first()
        if ja_existe is not None:
            return {"ja_semeado": True}

        indice_global = 0
        n_paises = n_destinos = n_nos = n_colecionaveis = 0

        for ordem_pais, p in enumerate(PAISES, start=1):
            pais_id = (
                await conn.execute(
                    insert(schema.pais)
                    .values(nome=p["nome"], ordem=ordem_pais)
                    .returning(schema.pais.c.id)
                )
            ).scalar_one()
            n_paises += 1

            await conn.execute(
                insert(schema.colecionavel).values(
                    tipo="carimbo",
                    referencia=f"pais:{pais_id}",
                    asset_ref=p["carimbo"],
                )
            )
            n_colecionaveis += 1

            for ordem_destino, (nome, cartao) in enumerate(p["destinos"], start=1):
                destino_id = (
                    await conn.execute(
                        insert(schema.destino)
                        .values(pais_id=pais_id, nome=nome, ordem=ordem_destino)
                        .returning(schema.destino.c.id)
                    )
                ).scalar_one()
                n_destinos += 1

                await conn.execute(
                    insert(schema.colecionavel).values(
                        tipo="cartao_postal",
                        referencia=f"destino:{destino_id}",
                        asset_ref=cartao,
                    )
                )
                n_colecionaveis += 1

                for ordem_no in range(1, NOS_POR_DESTINO + 1):
                    indice_global += 1
                    await conn.execute(
                        insert(schema.trilha_no).values(
                            destino_id=destino_id,
                            ordem=ordem_no,
                            xp_limiar=XP_POR_NO * indice_global,  # cumulativo
                        )
                    )
                    n_nos += 1

        for chave, asset in SELOS:
            await conn.execute(
                insert(schema.colecionavel).values(
                    tipo="selo", referencia=f"feito:{chave}", asset_ref=asset
                )
            )
            n_colecionaveis += 1

    return {
        "paises": n_paises,
        "destinos": n_destinos,
        "nos": n_nos,
        "colecionaveis": n_colecionaveis,
    }


if __name__ == "__main__":
    print("seed trilha:", asyncio.run(seed_trilha()))
