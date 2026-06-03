"""Autenticação PROVISÓRIA da fatia A (apresentável).

ATENÇÃO: isto **não** é autenticação real. O token é apenas `prov_<usuario_id>`,
sem assinatura nem expiração — suficiente para a demo, onde o acesso nasce do
`codigo_turma` (arquitetura, seção 3.11 / Bloco 3 decisão #4).

Princípio auth-agnóstico: a janela do 1º cliente (Out–Jan) troca SÓ este módulo
(validar JWT/provedor real) sem mexer nas rotas — `get_usuario_atual` continua
sendo a dependency que resolve a identidade.
"""
from dataclasses import dataclass
from typing import Annotated

from fastapi import Depends, Header
from sqlalchemy.ext.asyncio import AsyncConnection

from app.api.deps import get_conn
from app.errors import ApiError
from app.identidade import repository as repo

_PREFIXO = "prov_"


@dataclass
class UsuarioAutenticado:
    id: int
    nome: str


def criar_token_provisorio(usuario_id: int) -> str:
    return f"{_PREFIXO}{usuario_id}"


def _ler_token(token: str) -> int:
    if not token.startswith(_PREFIXO):
        raise ApiError(401, "nao_autenticado", "Token de sessão inválido.")
    try:
        return int(token[len(_PREFIXO):])
    except ValueError:
        raise ApiError(401, "nao_autenticado", "Token de sessão inválido.")


def _extrair_bearer(authorization: str | None) -> str:
    if not authorization or not authorization.lower().startswith("bearer "):
        raise ApiError(401, "nao_autenticado", "Credencial de acesso ausente.")
    return authorization[len("bearer "):].strip()


async def get_usuario_atual(
    conn: Annotated[AsyncConnection, Depends(get_conn)],
    authorization: Annotated[str | None, Header()] = None,
) -> UsuarioAutenticado:
    """Resolve o usuário do header `Authorization: Bearer <token>`."""
    usuario_id = _ler_token(_extrair_bearer(authorization))
    row = await repo.buscar_usuario(conn, usuario_id)
    if row is None:
        raise ApiError(401, "nao_autenticado", "Sessão inválida.")
    return UsuarioAutenticado(id=row.id, nome=row.nome)
