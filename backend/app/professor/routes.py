"""Professor / coordenação — telas MOCKADAS na fatia A.

Superfície do professor (produto §07 e §3.11; telas §8.2). No apresentável estas
rotas devolvem dados fixos para a demo a escolas; o painel real (dados de
verdade, escopo por papel e configuração) é da fatia C. Mesmas rotas, sem
reescrita depois — os shapes espelham `associacao_turma`, `turma_config` e
`redacao_atribuicao` de `docs/arquitetura.md`.

TODO fatia C: exigir papel professor/coordenador + escopo (associação). Hoje só
exige autenticação, como os demais mocks (report, redação).
"""
from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel

from app.identidade.auth import get_usuario_atual

router = APIRouter(tags=["professor"], dependencies=[Depends(get_usuario_atual)])


class TurmaResumo(BaseModel):
    id: int
    nome: str
    ano_escolar: int
    alunos_ativos: int
    meta_semanal: int


class TurmasOut(BaseModel):
    mock: bool
    turmas: list[TurmaResumo]


class AlunoPainel(BaseModel):
    id: int
    nome: str
    palavras_semana: int  # palavras dominadas nesta semana (unidade da meta, §3.5)
    meta_semana: int
    palavras_dominadas: int  # acumulado histórico


class PainelOut(BaseModel):
    mock: bool
    turma_id: int
    turma_nome: str
    ano_escolar: int
    alunos_ativos: int
    alunos_total: int
    palavras_dominadas_semana: int
    meta_semanal: int
    sinal_turma: list[str]  # palavras fracas recorrentes na turma (§3.5)
    alunos: list[AlunoPainel]


class TurmaLinha(BaseModel):
    id: int
    nome: str
    ano_escolar: int
    alunos_ativos: int
    alunos_total: int
    palavras_dominadas_semana: int
    meta_semanal: int


class EscolaPainelOut(BaseModel):
    """Escopo do coordenador (§3.11): escola inteira, só leitura (sem configurar)."""

    mock: bool
    escola_nome: str
    turmas_total: int
    alunos_ativos: int
    alunos_total: int
    palavras_dominadas_semana: int
    sinal_escola: list[str]
    turmas: list[TurmaLinha]


# Dados fixos só para a demo (fatia A). A turma 1 espelha o sample do app
# (`features/professor/professor_data.dart`) para que demo e backend coincidam.
_TURMAS = [
    {"id": 1, "nome": "7º Ano A", "ano_escolar": 7, "alunos_ativos": 23, "meta_semanal": 5},
    {"id": 2, "nome": "8º Ano C", "ano_escolar": 8, "alunos_ativos": 19, "meta_semanal": 6},
]

_PAINEIS = {
    1: {
        "mock": True,
        "turma_id": 1,
        "turma_nome": "7º Ano A",
        "ano_escolar": 7,
        "alunos_ativos": 23,
        "alunos_total": 26,
        "palavras_dominadas_semana": 184,
        "meta_semanal": 5,
        "sinal_turma": ["efêmero", "perspicaz", "meticuloso"],
        "alunos": [
            {"id": 1, "nome": "Ana Beatriz", "palavras_semana": 6, "meta_semana": 5, "palavras_dominadas": 142},
            {"id": 2, "nome": "Bruno Carvalho", "palavras_semana": 5, "meta_semana": 5, "palavras_dominadas": 98},
            {"id": 3, "nome": "Carla Dias", "palavras_semana": 3, "meta_semana": 5, "palavras_dominadas": 110},
            {"id": 4, "nome": "Diego Fernandes", "palavras_semana": 1, "meta_semana": 5, "palavras_dominadas": 64},
            {"id": 5, "nome": "Elisa Gomes", "palavras_semana": 5, "meta_semana": 5, "palavras_dominadas": 173},
            {"id": 6, "nome": "Felipe Henrique", "palavras_semana": 0, "meta_semana": 5, "palavras_dominadas": 41},
        ],
    },
    2: {
        "mock": True,
        "turma_id": 2,
        "turma_nome": "8º Ano C",
        "ano_escolar": 8,
        "alunos_ativos": 19,
        "alunos_total": 22,
        "palavras_dominadas_semana": 151,
        "meta_semanal": 6,
        "sinal_turma": ["ínterim", "conciso", "pertinente"],
        "alunos": [
            {"id": 7, "nome": "Gabriela Lima", "palavras_semana": 7, "meta_semana": 6, "palavras_dominadas": 188},
            {"id": 8, "nome": "Heitor Moraes", "palavras_semana": 4, "meta_semana": 6, "palavras_dominadas": 132},
            {"id": 9, "nome": "Isabela Nunes", "palavras_semana": 2, "meta_semana": 6, "palavras_dominadas": 95},
            {"id": 10, "nome": "João Pedro", "palavras_semana": 6, "meta_semana": 6, "palavras_dominadas": 147},
        ],
    },
}

# Agregado da escola (escopo coordenador). Os totais batem com a soma das turmas.
_ESCOLA = {
    "mock": True,
    "escola_nome": "Colégio Horizonte",
    "turmas_total": 2,
    "alunos_ativos": 42,
    "alunos_total": 48,
    "palavras_dominadas_semana": 335,
    "sinal_escola": ["efêmero", "pertinente", "conciso"],
    "turmas": [
        {"id": 1, "nome": "7º Ano A", "ano_escolar": 7, "alunos_ativos": 23, "alunos_total": 26, "palavras_dominadas_semana": 184, "meta_semanal": 5},
        {"id": 2, "nome": "8º Ano C", "ano_escolar": 8, "alunos_ativos": 19, "alunos_total": 22, "palavras_dominadas_semana": 151, "meta_semanal": 6},
    ],
}


@router.get(
    "/professor/turmas",
    response_model=TurmasOut,
    summary="Turmas do professor (MOCK estático na fatia A)",
)
async def listar_turmas():
    return {"mock": True, "turmas": _TURMAS}


@router.get(
    "/professor/turmas/{turma_id}/painel",
    response_model=PainelOut,
    summary="Painel da turma (MOCK estático na fatia A)",
)
async def painel_turma(turma_id: int):
    data = _PAINEIS.get(turma_id)
    if data is None:
        raise HTTPException(status_code=404, detail="turma_nao_encontrada")
    return data


@router.get(
    "/professor/escola",
    response_model=EscolaPainelOut,
    summary="Painel da escola — escopo coordenador, só leitura (MOCK)",
)
async def painel_escola():
    return _ESCOLA
