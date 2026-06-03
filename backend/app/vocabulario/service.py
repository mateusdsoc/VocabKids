"""Lógica de domínio do vocabulário — sem SQL cru nem detalhe de HTTP."""
from sqlalchemy.ext.asyncio import AsyncConnection

from app.errors import ApiError
from app.vocabulario import repository as repo

LIMITE_MAX = 100
LIMITE_PADRAO = 20


def _decodificar_cursor(cursor: str | None) -> int | None:
    if cursor is None:
        return None
    try:
        return int(cursor)
    except ValueError:
        raise ApiError(400, "cursor_invalido", "Cursor de paginação inválido.")


async def listar(conn: AsyncConnection, cursor: str | None, limite: int) -> dict:
    limite = max(1, min(limite, LIMITE_MAX))
    depois_de = _decodificar_cursor(cursor)

    # Pede uma linha a mais para saber se há próxima página sem um COUNT.
    rows = await repo.listar_palavras(conn, depois_de, limite + 1)
    tem_mais = len(rows) > limite
    rows = rows[:limite]
    next_cursor = str(rows[-1].id) if tem_mais and rows else None

    return {
        "items": [
            {"id": r.id, "lema": r.lema, "nivel_dificuldade": r.nivel_dificuldade}
            for r in rows
        ],
        "next_cursor": next_cursor,
    }


async def detalhe(conn: AsyncConnection, palavra_id: int) -> dict:
    p = await repo.buscar_palavra(conn, palavra_id)
    if p is None:
        raise ApiError(404, "palavra_nao_encontrada", "Palavra não encontrada.")
    sinonimos = await repo.listar_sinonimos(conn, palavra_id)
    return {
        "id": p.id,
        "lema": p.lema,
        "definicao": p.definicao,
        "exemplo_uso": p.exemplo_uso,
        "nivel_dificuldade": p.nivel_dificuldade,
        "audio_url": p.audio_url,
        "sinonimos": sinonimos,
    }
