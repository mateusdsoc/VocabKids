"""Rotas do domínio identidade (montadas sob `/v1` pelo agregador da API).

B2C (docs/plano_b2c.md Fase 1): conta do responsável + perfis de criança no
lugar do acesso por código de turma.
"""
from typing import Annotated

from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncConnection

from app.api.deps import get_conn
from app.errors import ApiError
from app.identidade import service
from app.identidade.auth import UsuarioAutenticado, get_usuario_atual, require_papel
from app.identidade.schemas import (
    CadastroResponsavelIn,
    ContaOut,
    ExcluirContaIn,
    LoginIn,
    MeOut,
    PerfilCriancaIn,
    PerfilCriancaOut,
    TokenOut,
)

router = APIRouter(tags=["identidade"])


def _exigir_consentimento(body: CadastroResponsavelIn) -> CadastroResponsavelIn:
    # R-LG-1 (docs/plano_b2c.md): consentimento parental é SEMPRE explícito.
    # Um POST com o campo `false` é rejeitado aqui, não silenciosamente aceito.
    if not body.aceite_termos or not body.consentimento_lgpd:
        raise ApiError(
            422,
            "consentimento_obrigatorio",
            "É preciso aceitar os termos e o consentimento de dados da criança "
            "para criar a conta.",
        )
    return body


@router.post(
    "/conta",
    response_model=TokenOut,
    summary="Cadastro do responsável (conta B2C)",
)
async def cadastrar_conta(
    body: CadastroResponsavelIn, conn: Annotated[AsyncConnection, Depends(get_conn)]
):
    _exigir_consentimento(body)
    return await service.cadastrar_responsavel(
        conn, nome=body.nome, email=body.email, senha=body.senha
    )


@router.post(
    "/sessao",
    response_model=TokenOut,
    summary="Login do responsável (e-mail/senha)",
)
async def entrar(body: LoginIn, conn: Annotated[AsyncConnection, Depends(get_conn)]):
    return await service.login(conn, email=body.email, senha=body.senha)


@router.get(
    "/conta",
    response_model=ContaOut,
    summary="Dados da conta do responsável + perfis",
)
async def obter_conta(
    usuario: Annotated[UsuarioAutenticado, Depends(require_papel("responsavel"))],
    conn: Annotated[AsyncConnection, Depends(get_conn)],
):
    return await service.conta(conn, usuario.id)


@router.get(
    "/conta/perfis",
    response_model=list[PerfilCriancaOut],
    summary="Lista os perfis de criança da conta",
)
async def listar_perfis(
    usuario: Annotated[UsuarioAutenticado, Depends(require_papel("responsavel"))],
    conn: Annotated[AsyncConnection, Depends(get_conn)],
):
    return await service.listar_perfis(conn, usuario.id)


@router.post(
    "/conta/perfis",
    response_model=PerfilCriancaOut,
    summary="Cria um perfil de criança (até 3 por conta)",
)
async def criar_perfil(
    body: PerfilCriancaIn,
    usuario: Annotated[UsuarioAutenticado, Depends(require_papel("responsavel"))],
    conn: Annotated[AsyncConnection, Depends(get_conn)],
):
    return await service.criar_perfil_crianca(
        conn,
        responsavel_usuario_id=usuario.id,
        apelido=body.apelido,
        ano_nascimento=body.ano_nascimento,
    )


@router.post(
    "/perfis/{perfil_usuario_id}/entrar",
    response_model=TokenOut,
    summary="Troca o token do responsável por um token de gameplay do perfil escolhido",
)
async def entrar_como_crianca(
    perfil_usuario_id: int,
    usuario: Annotated[UsuarioAutenticado, Depends(require_papel("responsavel"))],
    conn: Annotated[AsyncConnection, Depends(get_conn)],
):
    return await service.entrar_como_crianca(
        conn, responsavel_usuario_id=usuario.id, perfil_usuario_id=perfil_usuario_id
    )


@router.delete(
    "/conta",
    status_code=204,
    summary="Exclui a conta e os dados de todos os perfis (R-ID-6)",
)
async def excluir_conta(
    body: ExcluirContaIn,
    usuario: Annotated[UsuarioAutenticado, Depends(require_papel("responsavel"))],
    conn: Annotated[AsyncConnection, Depends(get_conn)],
):
    await service.excluir_conta(conn, usuario_id=usuario.id, senha=body.senha)


@router.get(
    "/me",
    response_model=MeOut,
    summary="Perfil da criança autenticada + progresso",
)
async def me(
    usuario: Annotated[UsuarioAutenticado, Depends(require_papel("aluno"))],
    conn: Annotated[AsyncConnection, Depends(get_conn)],
):
    return await service.perfil(conn, usuario.id)
