"""Autenticação por JWT assinado (HS256) com expiração.

Substitui o token provisório `prov_<usuario_id>` da fatia A. O contrato das
rotas não muda (princípio auth-agnóstico): `get_usuario_atual` continua sendo a
dependency que resolve a identidade a partir do `Authorization: Bearer <token>`.

Decisões:
- HS256 com segredo único (`JWT_SECRET`) — API monolítica, sem federação; o
  algoritmo é fixado na validação (nunca aceitar o `alg` do próprio token).
- Claims: `sub` (usuario_id), `papel`, `iat`, `exp`. O `papel` no token é
  informativo; a autorização usa o papel do banco (fonte da verdade), então
  promover/rebaixar um usuário tem efeito imediato, sem esperar o token expirar.
- Tokens antigos `prov_*` falham a validação e caem no 401 normal → o app
  descarta e pede novo acesso pelo código de turma.
"""
import time
from dataclasses import dataclass
from typing import Annotated

import jwt
from fastapi import Depends, Header
from sqlalchemy.ext.asyncio import AsyncConnection

from app.api.deps import get_conn
from app.config import settings
from app.errors import ApiError
from app.identidade import repository as repo

_ALGORITMO = "HS256"


@dataclass
class UsuarioAutenticado:
    id: int
    nome: str
    papel: str | None  # 'aluno' | 'responsavel'


def _segredo() -> str:
    if not settings.jwt_secret:
        raise RuntimeError(
            "JWT_SECRET não configurado. Gere um segredo com "
            "`openssl rand -hex 32` e defina JWT_SECRET no ambiente/.env."
        )
    return settings.jwt_secret


def criar_token(usuario_id: int, papel: str) -> str:
    agora = int(time.time())
    return jwt.encode(
        {
            "sub": str(usuario_id),
            "papel": papel,
            "iat": agora,
            "exp": agora + settings.jwt_ttl_horas * 3600,
        },
        _segredo(),
        algorithm=_ALGORITMO,
    )


def _ler_token(token: str) -> int:
    try:
        claims = jwt.decode(
            token,
            _segredo(),
            algorithms=[_ALGORITMO],
            options={"require": ["exp", "sub"]},
        )
        return int(claims["sub"])
    except jwt.ExpiredSignatureError:
        raise ApiError(
            401, "sessao_expirada", "Sua sessão expirou. Entre de novo."
        )
    except (jwt.InvalidTokenError, ValueError):
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
    return UsuarioAutenticado(id=row.id, nome=row.nome, papel=row.papel)


def require_papel(*papeis: str):
    """Dependency que restringe a rota aos papéis dados (papel vem do banco)."""

    async def _dep(
        usuario: Annotated[UsuarioAutenticado, Depends(get_usuario_atual)],
    ) -> UsuarioAutenticado:
        if usuario.papel not in papeis:
            raise ApiError(
                403,
                "sem_permissao",
                "Você não tem permissão para acessar este recurso.",
            )
        return usuario

    return _dep
