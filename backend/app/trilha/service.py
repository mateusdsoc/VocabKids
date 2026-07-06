"""Trilha: mapa, passaporte e o loop de recompensa (avanço de nó + colecionáveis).

`processar_recompensas` é chamado pelo `responder` após o XP ser aplicado: avança
`no_atual_id`, concede cartão (fecha destino) / carimbo (fecha país) ao cruzar o
limiar de um nó, e selos por feito (combo, palavras dominadas). Tudo idempotente.
"""
from sqlalchemy.ext.asyncio import AsyncConnection

from app.errors import ApiError
from app.trilha import repository as repo

NOS_POR_DESTINO = 4
COMBO_SELO = 10
MARCOS_DOMINADAS = (25, 100, 250)


async def mapa(conn: AsyncConnection, xp_total: int) -> dict:
    linhas = await repo.agregado_mapa(conn, xp_total)

    paises: dict[int, dict] = {}
    destino_atual_id: int | None = None
    for r in linhas:
        pais = paises.setdefault(
            r.pais_id,
            {"id": r.pais_id, "nome": r.pais_nome, "ordem": r.pais_ordem, "destinos": []},
        )
        concluido = r.nos_concluidos == r.nos_total
        atual = (not concluido) and destino_atual_id is None
        if atual:
            destino_atual_id = r.destino_id
        pais["destinos"].append(
            {
                "id": r.destino_id,
                "nome": r.destino_nome,
                "ordem": r.destino_ordem,
                "nos_total": r.nos_total,
                "nos_concluidos": r.nos_concluidos,
                "concluido": concluido,
                "atual": atual,
            }
        )

    lista_paises = []
    for p in paises.values():
        p["concluido"] = all(d["concluido"] for d in p["destinos"])
        lista_paises.append(p)

    no = await repo.no_atual_detalhe(conn, xp_total)
    no_atual = None
    if no is not None:
        no_atual = {
            "destino_id": no.destino_id,
            "destino_nome": no.destino_nome,
            "pais_nome": no.pais_nome,
            "no_ordem": no.no_ordem,
            "xp_inicio": await repo.xp_inicio_do_no(conn, no.xp_limiar),
            "xp_limiar": no.xp_limiar,
        }

    return {"xp_total": xp_total, "no_atual": no_atual, "paises": lista_paises}


async def passaporte(conn: AsyncConnection, usuario_id: int) -> dict:
    linhas = await repo.listar_passaporte(conn, usuario_id)
    itens = [
        {
            "id": r.id,
            "tipo": r.tipo,
            "referencia": r.referencia,
            "asset_ref": r.asset_ref,
            "conquistado": r.ganho_em is not None,
            "ganho_em": r.ganho_em,
            "revelado": r.revelado_em is not None,
        }
        for r in linhas
    ]
    conquistados = sum(1 for i in itens if i["conquistado"])
    return {"total": len(itens), "conquistados": conquistados, "itens": itens}


async def marcar_revelado(
    conn: AsyncConnection, usuario_id: int, colecionavel_id: int
) -> dict:
    """Marca um item ganho como revelado (o Modo Conquista tocou).

    Idempotente: revelar de novo não muda o timestamp — o reveal dispara 1×,
    mas o app pode repetir o POST num retry de rede sem efeito colateral.
    """
    linha = await repo.ler_aluno_colecionavel(conn, usuario_id, colecionavel_id)
    if linha is None:
        raise ApiError(404, "item_nao_conquistado", "Item não conquistado pelo aluno.")
    if linha.revelado_em is None:
        await repo.marcar_revelado(conn, usuario_id, colecionavel_id)
    return {"revelado": True, "colecionavel_id": colecionavel_id}


async def _conceder_por_referencia(
    conn: AsyncConnection, usuario_id: int, referencia: str, ganhos: list
) -> None:
    col = await repo.colecionavel_por_referencia(conn, referencia)
    if col and await repo.conceder(conn, usuario_id, col.id):
        ganhos.append(
            {
                "tipo": col.tipo,
                "colecionavel_id": col.id,
                "referencia": col.referencia,
                "asset_ref": col.asset_ref,
            }
        )


async def processar_recompensas(
    conn: AsyncConnection,
    usuario_id: int,
    xp_anterior: int,
    xp_total: int,
    combo_atual: int,
    palavras_dominadas: int,
) -> list[dict]:
    """Avança a trilha e concede recompensas devidas. Retorna o que foi ganho agora."""
    ganhos: list[dict] = []

    # 1. Nós cruzados nesta resposta → cartão (fecha destino) / carimbo (fecha país).
    if xp_total > xp_anterior:
        cruzados = await repo.nos_concluidos_entre(conn, xp_anterior, xp_total)
        if cruzados:
            ultimo_destino = await repo.max_destino_ordem_por_pais(conn)
            for no in cruzados:
                # Invariante do seed: xp_limiar é monotônico na ordem
                # país→destino→nó. Por isso "fecha país" = fechar o último nó do
                # último destino (os anteriores já foram cruzados). Se o seed
                # reordenar os limiares, esta lógica precisa ser revista.
                fecha_destino = no.no_ordem == NOS_POR_DESTINO
                if fecha_destino:
                    await _conceder_por_referencia(
                        conn, usuario_id, f"destino:{no.destino_id}", ganhos
                    )
                    if no.destino_ordem == ultimo_destino.get(no.pais_id):
                        await _conceder_por_referencia(
                            conn, usuario_id, f"pais:{no.pais_id}", ganhos
                        )
            novo_no = await repo.id_no_atual(conn, xp_total)
            await repo.definir_no_atual(conn, usuario_id, novo_no)

    # 2. Selos por feito (idempotentes).
    if combo_atual >= COMBO_SELO:
        await _conceder_por_referencia(conn, usuario_id, "feito:combo_10", ganhos)
    for marco in MARCOS_DOMINADAS:
        if palavras_dominadas >= marco:
            await _conceder_por_referencia(
                conn, usuario_id, f"feito:dominadas_{marco}", ganhos
            )

    return ganhos
