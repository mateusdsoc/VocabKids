"""Professor / coordenação — telas MOCKADAS na fatia A.

Superfície do professor (produto §07 e §3.11; telas §8.2). No apresentável estas
rotas devolvem dados fixos para a demo a escolas; o painel real (dados de
verdade, escopo por papel e configuração) é da fatia C. Mesmas rotas, sem
reescrita depois — os shapes espelham `associacao_turma`, `turma_config` e
`redacao_atribuicao` de `docs/arquitetura.md`.

Autorização: leitura exige papel professor OU coordenador; configurar meta e
atribuir redação são só do professor (coordenador é leitura, §3.11). O papel
vem do banco via `require_papel` (auth.py).

TODO fatia C: escopo por associação (professor só nas turmas de
`associacao_turma`) — sem sentido enquanto as turmas daqui são mock.
"""
import itertools
from datetime import date

from fastapi import APIRouter, Depends
from pydantic import BaseModel, Field, field_validator

from app.errors import ApiError
from app.identidade.auth import require_papel

router = APIRouter(
    tags=["professor"],
    dependencies=[Depends(require_papel("professor", "coordenador"))],
)
# Ações de configuração (meta, atribuir redação): só professor.
_so_professor = [Depends(require_papel("professor"))]


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


class AlunoPalavra(BaseModel):
    """Uma palavra no vocabulário do aluno (espelha `aluno_palavra`)."""

    texto: str
    estado: str  # descoberta | nivel_1..4 | dominada (máquina de estados, §3.4)
    origem: str  # pessoal_redacao | sinal_turma | banco_base (§3.2/§3.5)


class AlunoRedacao(BaseModel):
    """Redação do aluno (espelha `redacao` + `redacao_atribuicao.tema`)."""

    id: int
    tema: str
    status: str  # pendente | em_analise | analisada | rascunho
    enviada_em: str | None


class AlunoDetalheOut(BaseModel):
    """Detalhe do aluno — drill-down do painel (telas §8.2). Só leitura.

    Counters + uma lista **limitada** de palavras notáveis (não o histórico
    inteiro — produto §3.5: "o contador, não a lista, que ficaria longa demais")
    e as redações do aluno. Sem % de acerto / tempo (decisões de produto).
    """

    mock: bool
    id: int
    nome: str
    turma_id: int
    turma_nome: str
    ano_escolar: int
    palavras_semana: int  # dominadas nesta semana (unidade da meta, §3.5)
    meta_semana: int
    palavras_dominadas: int  # acumulado histórico (counter)
    palavras_em_progresso: int  # em nivel_1..4, ainda não dominadas (counter)
    palavras: list[AlunoPalavra]  # subconjunto notável (recentes/ativas)
    redacoes: list[AlunoRedacao]


class AtribuirRedacaoIn(BaseModel):
    """Corpo de POST /professor/turmas/{id}/redacoes (espelha `redacao_atribuicao`,
    §4.6): o professor atribui **tema + prazo**; o aluno é quem envia depois."""

    tema: str
    prazo: str | None = None  # data ISO (yyyy-mm-dd) ou null (sem prazo)

    @field_validator("tema")
    @classmethod
    def _tema_nao_vazio(cls, v: str) -> str:
        v = v.strip()
        if not v:
            raise ValueError("tema obrigatório")
        return v

    @field_validator("prazo")
    @classmethod
    def _prazo_iso(cls, v: str | None) -> str | None:
        if v is None:
            return v
        try:
            date.fromisoformat(v)
        except ValueError as e:
            raise ValueError("prazo deve ser uma data ISO (yyyy-mm-dd)") from e
        return v


class RedacaoAtribuicaoOut(BaseModel):
    mock: bool
    id: int
    turma_id: int
    tema: str
    prazo: str | None


class AtualizarMetaIn(BaseModel):
    """Corpo de PUT /professor/turmas/{id}/meta (espelha `turma_config.meta_semanal`,
    §3.5): meta em **palavras dominadas por semana, por aluno**. Só professor."""

    meta_semanal: int = Field(ge=1, le=50)


class MetaTurmaOut(BaseModel):
    mock: bool
    turma_id: int
    meta_semanal: int


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

# Detalhe por aluno (drill-down). Só o **extra** vive aqui (palavras notáveis,
# redações e o counter de "em progresso"); nome/meta/dominadas saem do painel
# (`_PAINEIS`) para não duplicar — fonte única, demo e backend coincidem. As
# palavras misturam as origens de propósito: `pessoal_redacao` mostra o loop
# redação→vocabulário (§3.2) e `sinal_turma` casa com o "sinal" do painel (§3.5).
_ALUNOS_DETALHE = {
    1: {  # Ana Beatriz — forte, meta cumprida (6/5)
        "palavras_em_progresso": 7,
        "palavras": [
            {"texto": "perspicaz", "estado": "dominada", "origem": "sinal_turma"},
            {"texto": "resiliente", "estado": "dominada", "origem": "pessoal_redacao"},
            {"texto": "meticuloso", "estado": "dominada", "origem": "banco_base"},
            {"texto": "efêmero", "estado": "nivel_3", "origem": "sinal_turma"},
            {"texto": "âmbar", "estado": "nivel_2", "origem": "pessoal_redacao"},
            {"texto": "conciso", "estado": "nivel_1", "origem": "banco_base"},
        ],
        "redacoes": [
            {"id": 1, "tema": "Um herói brasileiro", "status": "analisada", "enviada_em": "2026-06-09"},
            {"id": 2, "tema": "Minhas férias dos sonhos", "status": "em_analise", "enviada_em": "2026-06-14"},
        ],
    },
    2: {  # Bruno Carvalho — no ritmo (5/5)
        "palavras_em_progresso": 5,
        "palavras": [
            {"texto": "meticuloso", "estado": "dominada", "origem": "sinal_turma"},
            {"texto": "próspero", "estado": "dominada", "origem": "banco_base"},
            {"texto": "perspicaz", "estado": "nivel_3", "origem": "sinal_turma"},
            {"texto": "vasto", "estado": "nivel_2", "origem": "pessoal_redacao"},
            {"texto": "sutil", "estado": "nivel_1", "origem": "banco_base"},
        ],
        "redacoes": [
            {"id": 1, "tema": "Um herói brasileiro", "status": "analisada", "enviada_em": "2026-06-08"},
        ],
    },
    3: {  # Carla Dias — semana fraca (3/5), histórico bom
        "palavras_em_progresso": 6,
        "palavras": [
            {"texto": "nítido", "estado": "dominada", "origem": "banco_base"},
            {"texto": "eloquente", "estado": "dominada", "origem": "pessoal_redacao"},
            {"texto": "efêmero", "estado": "nivel_2", "origem": "sinal_turma"},
            {"texto": "perspicaz", "estado": "nivel_1", "origem": "sinal_turma"},
        ],
        "redacoes": [
            {"id": 1, "tema": "Um herói brasileiro", "status": "em_analise", "enviada_em": "2026-06-13"},
        ],
    },
    4: {  # Diego Fernandes — em dificuldade (1/5)
        "palavras_em_progresso": 4,
        "palavras": [
            {"texto": "próspero", "estado": "dominada", "origem": "banco_base"},
            {"texto": "efêmero", "estado": "nivel_1", "origem": "sinal_turma"},
            {"texto": "perspicaz", "estado": "nivel_1", "origem": "sinal_turma"},
            {"texto": "conciso", "estado": "descoberta", "origem": "banco_base"},
        ],
        "redacoes": [
            {"id": 1, "tema": "Um herói brasileiro", "status": "pendente", "enviada_em": None},
        ],
    },
    5: {  # Elisa Gomes — histórico mais alto da turma (173)
        "palavras_em_progresso": 8,
        "palavras": [
            {"texto": "audacioso", "estado": "dominada", "origem": "pessoal_redacao"},
            {"texto": "perspicaz", "estado": "dominada", "origem": "sinal_turma"},
            {"texto": "meticuloso", "estado": "dominada", "origem": "sinal_turma"},
            {"texto": "lúcido", "estado": "dominada", "origem": "banco_base"},
            {"texto": "efêmero", "estado": "nivel_4", "origem": "sinal_turma"},
            {"texto": "sagaz", "estado": "nivel_2", "origem": "pessoal_redacao"},
        ],
        "redacoes": [
            {"id": 1, "tema": "Um herói brasileiro", "status": "analisada", "enviada_em": "2026-06-07"},
            {"id": 2, "tema": "Minhas férias dos sonhos", "status": "analisada", "enviada_em": "2026-06-13"},
        ],
    },
    6: {  # Felipe Henrique — sem atividade na semana (0/5)
        "palavras_em_progresso": 3,
        "palavras": [
            {"texto": "vasto", "estado": "dominada", "origem": "banco_base"},
            {"texto": "perspicaz", "estado": "nivel_1", "origem": "sinal_turma"},
            {"texto": "meticuloso", "estado": "descoberta", "origem": "sinal_turma"},
        ],
        "redacoes": [
            {"id": 1, "tema": "Um herói brasileiro", "status": "pendente", "enviada_em": None},
        ],
    },
    7: {  # Gabriela Lima (8º C) — superou a meta (7/6)
        "palavras_em_progresso": 9,
        "palavras": [
            {"texto": "pertinente", "estado": "dominada", "origem": "sinal_turma"},
            {"texto": "eloquente", "estado": "dominada", "origem": "pessoal_redacao"},
            {"texto": "conciso", "estado": "dominada", "origem": "sinal_turma"},
            {"texto": "ínterim", "estado": "nivel_3", "origem": "sinal_turma"},
            {"texto": "sagaz", "estado": "nivel_1", "origem": "banco_base"},
        ],
        "redacoes": [
            {"id": 1, "tema": "Tecnologia na escola", "status": "analisada", "enviada_em": "2026-06-11"},
        ],
    },
    8: {  # Heitor Moraes (8º C) — no caminho (4/6)
        "palavras_em_progresso": 6,
        "palavras": [
            {"texto": "conciso", "estado": "dominada", "origem": "sinal_turma"},
            {"texto": "próspero", "estado": "nivel_2", "origem": "banco_base"},
            {"texto": "pertinente", "estado": "nivel_1", "origem": "sinal_turma"},
        ],
        "redacoes": [
            {"id": 1, "tema": "Tecnologia na escola", "status": "em_analise", "enviada_em": "2026-06-12"},
        ],
    },
    9: {  # Isabela Nunes (8º C) — semana fraca (2/6)
        "palavras_em_progresso": 5,
        "palavras": [
            {"texto": "vasto", "estado": "dominada", "origem": "banco_base"},
            {"texto": "ínterim", "estado": "nivel_1", "origem": "sinal_turma"},
            {"texto": "pertinente", "estado": "descoberta", "origem": "sinal_turma"},
        ],
        "redacoes": [
            {"id": 1, "tema": "Tecnologia na escola", "status": "pendente", "enviada_em": None},
        ],
    },
    10: {  # João Pedro (8º C) — meta cumprida (6/6)
        "palavras_em_progresso": 7,
        "palavras": [
            {"texto": "pertinente", "estado": "dominada", "origem": "sinal_turma"},
            {"texto": "nítido", "estado": "dominada", "origem": "pessoal_redacao"},
            {"texto": "conciso", "estado": "nivel_3", "origem": "sinal_turma"},
            {"texto": "sutil", "estado": "nivel_1", "origem": "banco_base"},
        ],
        "redacoes": [
            {"id": 1, "tema": "Tecnologia na escola", "status": "analisada", "enviada_em": "2026-06-10"},
        ],
    },
}


def _aluno_base(aluno_id: int) -> tuple[dict, dict] | tuple[None, None]:
    """Acha o aluno nos painéis (fonte única dos campos-base). (painel, aluno)."""
    for painel in _PAINEIS.values():
        for aluno in painel["alunos"]:
            if aluno["id"] == aluno_id:
                return painel, aluno
    return None, None


# Mock não persiste: gera um id de atribuição por processo (não confiar entre
# reinícios). Na fatia C vira a PK real de `redacao_atribuicao`.
_ATRIBUICAO_IDS = itertools.count(101)


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
        raise ApiError(404, "turma_nao_encontrada", "Turma não encontrada.")
    return data


@router.get(
    "/professor/escola",
    response_model=EscolaPainelOut,
    summary="Painel da escola — escopo coordenador, só leitura (MOCK)",
)
async def painel_escola():
    return _ESCOLA


@router.get(
    "/professor/alunos/{aluno_id}",
    response_model=AlunoDetalheOut,
    summary="Detalhe do aluno — drill-down do painel (MOCK estático na fatia A)",
)
async def detalhe_aluno(aluno_id: int):
    painel, aluno = _aluno_base(aluno_id)
    if painel is None or aluno is None:
        raise ApiError(404, "aluno_nao_encontrado", "Aluno não encontrado.")
    extra = _ALUNOS_DETALHE.get(aluno_id, {})
    palavras = extra.get("palavras", [])
    return {
        "mock": True,
        "id": aluno["id"],
        "nome": aluno["nome"],
        "turma_id": painel["turma_id"],
        "turma_nome": painel["turma_nome"],
        "ano_escolar": painel["ano_escolar"],
        "palavras_semana": aluno["palavras_semana"],
        "meta_semana": aluno["meta_semana"],
        "palavras_dominadas": aluno["palavras_dominadas"],
        # Sem entrada curada: deriva um counter plausível (>= dominadas na lista).
        "palavras_em_progresso": extra.get(
            "palavras_em_progresso",
            sum(1 for p in palavras if p["estado"] != "dominada"),
        ),
        "palavras": palavras,
        "redacoes": extra.get("redacoes", []),
    }


@router.post(
    "/professor/turmas/{turma_id}/redacoes",
    response_model=RedacaoAtribuicaoOut,
    status_code=201,
    summary="Atribuir redação à turma — tema + prazo (MOCK na fatia A)",
    dependencies=_so_professor,
)
async def atribuir_redacao(turma_id: int, body: AtribuirRedacaoIn):
    if turma_id not in _PAINEIS:
        raise ApiError(404, "turma_nao_encontrada", "Turma não encontrada.")
    # Mock: não persiste; só ecoa a atribuição criada (tema já validado/strip).
    return {
        "mock": True,
        "id": next(_ATRIBUICAO_IDS),
        "turma_id": turma_id,
        "tema": body.tema,
        "prazo": body.prazo,
    }


@router.put(
    "/professor/turmas/{turma_id}/meta",
    response_model=MetaTurmaOut,
    summary="Configurar meta semanal da turma — §3.5 (MOCK na fatia A)",
    dependencies=_so_professor,
)
async def atualizar_meta(turma_id: int, body: AtualizarMetaIn):
    if turma_id not in _PAINEIS:
        raise ApiError(404, "turma_nao_encontrada", "Turma não encontrada.")
    # Mock: não persiste (a faixa já foi validada). Ecoa a nova meta; na fatia C
    # grava `turma_config.meta_semanal`. O app reflete otimisticamente.
    return {"mock": True, "turma_id": turma_id, "meta_semanal": body.meta_semanal}
