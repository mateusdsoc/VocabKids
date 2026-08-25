"""Redação — pipeline real B2C (Fase 4, `docs/plano_b2c.md`).

Rotas de leitura/envio (`/redacoes*`) são do escopo `aluno` (o perfil da
criança). `POST /redacoes/tema-extra` é do escopo `responsavel` (R-RD-4: quem
decide gastar um dos 2 extras/mês é o adulto, não a criança em pleno jogo —
mesmo espírito de R-RS-1 na assinatura).
"""
from typing import Annotated

from fastapi import APIRouter, Depends
from pydantic import BaseModel
from sqlalchemy.ext.asyncio import AsyncConnection

from app.api.deps import get_conn
from app.identidade import repository as identidade_repo
from app.identidade.auth import UsuarioAutenticado, require_papel
from app.errors import ApiError
from app.redacao import service
from app.redacao.analisador import Analisador, get_analisador
from app.redacao.schemas import AnaliseOut, EnviarRedacaoIn, EnviarRedacaoOut, RedacoesOut, TemaExtraOut

router = APIRouter(tags=["redacao"])


@router.get("/redacoes", response_model=RedacoesOut, summary="Atribuições de redação do perfil")
async def listar_redacoes(
    usuario: Annotated[UsuarioAutenticado, Depends(require_papel("aluno"))],
    conn: Annotated[AsyncConnection, Depends(get_conn)],
):
    return await service.listar_redacoes(conn, usuario.id)


@router.post(
    "/redacoes/{atribuicao_id}/enviar",
    response_model=EnviarRedacaoOut,
    summary="Envia o texto da redação (OCR, se manuscrita, já rodou no app)",
)
async def enviar_redacao(
    atribuicao_id: int,
    corpo: EnviarRedacaoIn,
    usuario: Annotated[UsuarioAutenticado, Depends(require_papel("aluno"))],
    conn: Annotated[AsyncConnection, Depends(get_conn)],
    analisador: Annotated[Analisador, Depends(get_analisador)],
):
    return await service.enviar_redacao(
        conn,
        usuario_id=usuario.id,
        atribuicao_id=atribuicao_id,
        formato=corpo.formato,
        texto_extraido=corpo.texto_extraido,
        analisador=analisador,
    )


@router.get(
    "/redacoes/{redacao_id}/analise",
    response_model=AnaliseOut,
    summary="Análise da redação (anotações + palavras novas)",
)
async def analise_redacao(
    redacao_id: int,
    usuario: Annotated[UsuarioAutenticado, Depends(require_papel("aluno"))],
    conn: Annotated[AsyncConnection, Depends(get_conn)],
):
    return await service.obter_analise(conn, usuario_id=usuario.id, redacao_id=redacao_id)


class TemaExtraIn(BaseModel):
    perfil_usuario_id: int


@router.post(
    "/redacoes/tema-extra",
    response_model=TemaExtraOut,
    summary="Responsável pede um tema extra agora (R-RD-4: máx. 2/mês/perfil)",
)
async def pedir_tema_extra(
    corpo: TemaExtraIn,
    usuario: Annotated[UsuarioAutenticado, Depends(require_papel("responsavel"))],
    conn: Annotated[AsyncConnection, Depends(get_conn)],
):
    conta = await identidade_repo.buscar_conta_por_responsavel(conn, usuario.id)
    if conta is None:
        raise ApiError(404, "conta_nao_encontrada", "Conta não encontrada.")
    pertence = await identidade_repo.buscar_perfil_na_conta(conn, conta.id, corpo.perfil_usuario_id)
    if pertence is None:
        raise ApiError(404, "perfil_nao_encontrado", "Perfil não pertence a esta conta.")
    return await service.pedir_tema_extra(conn, corpo.perfil_usuario_id)
