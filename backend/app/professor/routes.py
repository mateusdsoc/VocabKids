"""Professor / coordenação — fatia C: dados reais + escopo por associação.

Superfície do professor (produto §07 e §3.11; telas §8.2). Os contratos são os
mesmos desde a fatia A (o app não mudou); o miolo trocou os dados fixos por
queries reais em `repository.py` via `service.py`.

Autorização: leitura exige papel professor OU coordenador; configurar meta e
atribuir redação são só do professor (coordenador é leitura, §3.11). O papel
vem do banco via `require_papel` (auth.py); o **alcance** (só as próprias
turmas / só a própria escola) é do serviço.
"""
from typing import Annotated

from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncConnection

from app.api.deps import get_conn
from app.identidade.auth import UsuarioAutenticado, require_papel
from app.professor import service
from app.professor.schemas import (
    AlunoDetalheOut,
    AtribuirRedacaoIn,
    AtualizarMetaIn,
    EscolaPainelOut,
    MetaTurmaOut,
    PainelOut,
    RedacaoAtribuicaoOut,
    TurmasOut,
)

router = APIRouter(tags=["professor"])

_Conn = Annotated[AsyncConnection, Depends(get_conn)]
_Leitor = Annotated[
    UsuarioAutenticado, Depends(require_papel("professor", "coordenador"))
]
# Ações de configuração (meta, atribuir redação): só professor.
_Professor = Annotated[UsuarioAutenticado, Depends(require_papel("professor"))]


@router.get(
    "/professor/turmas",
    response_model=TurmasOut,
    summary="Turmas no escopo do usuário (professor: as suas; coordenador: da escola)",
)
async def listar_turmas(conn: _Conn, usuario: _Leitor):
    return await service.listar_turmas(conn, usuario)


@router.get(
    "/professor/turmas/{turma_id}/painel",
    response_model=PainelOut,
    summary="Painel da turma — KPIs, sinal e alunos (§3.5, telas §8.2)",
)
async def painel_turma(turma_id: int, conn: _Conn, usuario: _Leitor):
    return await service.painel_turma(conn, usuario, turma_id)


@router.get(
    "/professor/escola",
    response_model=EscolaPainelOut,
    summary="Painel da escola — agregado só-leitura (§3.11)",
)
async def painel_escola(conn: _Conn, usuario: _Leitor):
    return await service.painel_escola(conn, usuario)


@router.get(
    "/professor/alunos/{aluno_id}",
    response_model=AlunoDetalheOut,
    summary="Detalhe do aluno — drill-down do painel (telas §8.2)",
)
async def detalhe_aluno(aluno_id: int, conn: _Conn, usuario: _Leitor):
    return await service.detalhe_aluno(conn, usuario, aluno_id)


@router.post(
    "/professor/turmas/{turma_id}/redacoes",
    response_model=RedacaoAtribuicaoOut,
    status_code=201,
    summary="Atribuir redação à turma — tema + prazo (§4.6)",
)
async def atribuir_redacao(
    turma_id: int, body: AtribuirRedacaoIn, conn: _Conn, usuario: _Professor
):
    return await service.atribuir_redacao(
        conn, usuario, turma_id, body.tema, body.prazo
    )


@router.put(
    "/professor/turmas/{turma_id}/meta",
    response_model=MetaTurmaOut,
    summary="Configurar meta semanal da turma — §3.5 (persiste em turma_config)",
)
async def atualizar_meta(
    turma_id: int, body: AtualizarMetaIn, conn: _Conn, usuario: _Professor
):
    return await service.atualizar_meta(conn, usuario, turma_id, body.meta_semanal)
