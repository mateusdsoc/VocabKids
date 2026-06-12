"""Redação e dashboard — telas MOCKADAS/estáticas na fatia A.

No apresentável estas telas existem para a demo, mas devolvem dados fixos: o
pipeline real de redação (OCR→análise→extração→atribuição) e o dashboard com
dados de verdade são da fatia C (Bloco 2b). Mesmas rotas, sem reescrita depois.
"""
from typing import Annotated

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel

from app.identidade.auth import get_usuario_atual

router = APIRouter(tags=["redacao"], dependencies=[Depends(get_usuario_atual)])


class RedacaoMock(BaseModel):
    id: int
    tema: str
    prazo: str | None
    status: str


class RedacoesOut(BaseModel):
    mock: bool
    itens: list[RedacaoMock]


class DashboardOut(BaseModel):
    mock: bool
    turma: str
    palavras_dominadas_turma: int
    meta_semanal: int
    alunos_ativos: int
    top3_palavras_dificeis: list[str]


# Dados fixos só para a demo (fatia A).
_REDACOES = [
    {"id": 1, "tema": "Minhas férias dos sonhos", "prazo": "2026-06-20", "status": "pendente"},
    {"id": 2, "tema": "Um herói brasileiro", "prazo": "2026-06-10", "status": "analisada"},
    {"id": 3, "tema": "Se eu pudesse mudar o mundo", "prazo": None, "status": "rascunho"},
]

_DASHBOARD = {
    "mock": True,
    "turma": "7º Ano A",
    "palavras_dominadas_turma": 184,
    "meta_semanal": 5,
    "alunos_ativos": 23,
    "top3_palavras_dificeis": ["efêmero", "perspicaz", "meticuloso"],
}


@router.get(
    "/redacoes",
    response_model=RedacoesOut,
    summary="Lista de redações (MOCK estático na fatia A)",
)
async def listar_redacoes():
    return {"mock": True, "itens": _REDACOES}


@router.get(
    "/dashboard",
    response_model=DashboardOut,
    summary="Dashboard da turma (MOCK estático na fatia A)",
)
async def dashboard():
    return _DASHBOARD


# --- Análise da redação (MOCK) ---------------------------------------------
# Contrato em docs/arquitetura.md (pipeline §2). Esta rota devolve a view-model
# que a tela do aluno (telas §8.1) consome: anotações + palavras novas + texto.
#
# As âncoras são declaradas como (trecho, ocorrência) e RESOLVIDAS em offsets a
# cada request — é o próprio passo do contrato "o backend resolve, não confia no
# offset cru do LLM". Âncora não-resolvível é descartada (a anotação vira nota),
# nunca quebra a tela. Aqui isso torna os offsets do mock corretos de fato.


class Ancora(BaseModel):
    inicio: int
    fim: int
    trecho: str
    ocorrencia: int


class Anotacao(BaseModel):
    id: str
    dimensao: str
    subtipo: str | None = None
    titulo: str
    comentario: str
    sugestoes: list[str] = []
    ancoras: list[Ancora] = []  # vazia = holística → tela renderiza como nota


class Analise(BaseModel):
    versao: int
    dimensoes: list[str]
    pontos_fortes: list[str]
    anotacoes: list[Anotacao]


class PalavraNova(BaseModel):
    palavra: str
    gatilho: str
    anotacao_id: str


class AnaliseOut(BaseModel):
    mock: bool
    redacao_id: int
    status: str
    texto_extraido: str
    analise: Analise | None
    palavras_novas: list[PalavraNova]


# Texto "transcrito" da redação 2 ("Um herói brasileiro"), com erros plantados
# em três dimensões marcáveis (vocabulário, acentuação, pontuação).
_TEXTO_HEROI = (
    "Meu heroi brasileiro é Santos Dumont. Ele foi um inventor muito "
    "inteligente e muito corajoso, que sonhava em voar pelo céu.\n\n"
    "Santos Dumont criou o 14-Bis, um avião muito legal para a época. Muita "
    "gente duvidava do seu sonho mas ele não desistiu.\n\nEu acho que ele é um "
    "exemplo para todos nós, porque mostrou que tambem podemos realizar nossos "
    "sonhos."
)

# Anotações como (trecho, ocorrência); o resolver preenche inicio/fim.
_ANOTACOES_HEROI: list[dict] = [
    {
        "id": "an_1",
        "dimensao": "vocabulario",
        "subtipo": "superutilizada",
        "titulo": "“muito” apareceu 3 vezes",
        "comentario": "Repetir a mesma palavra deixa o texto cansado. "
        "Experimente variar com uma destas:",
        "sugestoes": ["bastante", "extremamente", "imensamente"],
        "marcas": [("muito", 1), ("muito", 2), ("muito", 3)],
    },
    {
        "id": "an_2",
        "dimensao": "acentuacao",
        "titulo": "Faltou um acento",
        "comentario": "“Heroi” leva acento agudo no “o”.",
        "sugestoes": ["herói"],
        "marcas": [("heroi", 1)],
    },
    {
        "id": "an_3",
        "dimensao": "vocabulario",
        "subtipo": "fraca",
        "titulo": "“legal” é uma palavra coringa",
        "comentario": "Ela serve para tudo — e por isso diz pouco. Uma palavra "
        "mais precisa deixa a frase mais forte:",
        "sugestoes": ["inovador", "impressionante"],
        "marcas": [("legal", 1)],
    },
    {
        "id": "an_4",
        "dimensao": "pontuacao",
        "titulo": "Vírgula antes de “mas”",
        "comentario": "Quando o “mas” liga duas ideias, costuma vir depois de "
        "uma vírgula: “...do seu sonho, mas ele não desistiu.”",
        "sugestoes": ["sonho, mas"],
        "marcas": [("mas", 1)],
    },
    {
        "id": "an_5",
        "dimensao": "acentuacao",
        "titulo": "Faltou um acento",
        "comentario": "“Tambem” leva acento agudo no “e”.",
        "sugestoes": ["também"],
        "marcas": [("tambem", 1)],
    },
    {
        "id": "an_6",
        "dimensao": "coesao_estrutura",
        "titulo": "Começo, meio e fim — muito bem!",
        "comentario": "Seu texto apresenta o herói, conta o que ele fez e fecha "
        "com a sua opinião. Para ficar ainda mais forte, experimente ligar os "
        "parágrafos com palavras de transição, como “por isso” ou “além disso”.",
        "sugestoes": [],
        "marcas": [],  # holística: sem grifo
    },
]

_PONTOS_FORTES_HEROI = [
    "Você contou uma história com começo, meio e fim",
    "Usou um exemplo de verdade — o 14-Bis!",
    "Terminou defendendo a sua opinião",
]

_PALAVRAS_NOVAS_HEROI = [
    {"palavra": "bastante", "gatilho": "muito", "anotacao_id": "an_1"},
    {"palavra": "inovador", "gatilho": "legal", "anotacao_id": "an_3"},
]


def _resolver_ancoras(texto: str, marcas: list[tuple[str, int]]) -> list[Ancora]:
    """(trecho, n-ésima ocorrência) → offsets [inicio, fim) em code points.

    Espelha o passo de resolução do contrato: o backend localiza o trecho no
    texto em vez de confiar em offset cru do modelo. Marca não encontrada é
    descartada (a anotação perde a âncora e vira holística).
    """
    ancoras: list[Ancora] = []
    for trecho, ocorrencia in marcas:
        pos, achados = -1, 0
        while achados < ocorrencia:
            pos = texto.find(trecho, pos + 1)
            if pos == -1:
                break
            achados += 1
        if pos != -1:
            ancoras.append(
                Ancora(inicio=pos, fim=pos + len(trecho), trecho=trecho, ocorrencia=ocorrencia)
            )
    return ancoras


def _montar_analise_heroi() -> Analise:
    anotacoes = [
        Anotacao(
            id=a["id"],
            dimensao=a["dimensao"],
            subtipo=a.get("subtipo"),
            titulo=a["titulo"],
            comentario=a["comentario"],
            sugestoes=a["sugestoes"],
            ancoras=_resolver_ancoras(_TEXTO_HEROI, a["marcas"]),
        )
        for a in _ANOTACOES_HEROI
    ]
    # dimensões efetivamente avaliadas nesta amostra (na ordem do produto 4.2)
    dimensoes = ["vocabulario", "acentuacao", "pontuacao", "coesao_estrutura"]
    return Analise(
        versao=1,
        dimensoes=dimensoes,
        pontos_fortes=_PONTOS_FORTES_HEROI,
        anotacoes=anotacoes,
    )


@router.get(
    "/redacoes/{redacao_id}/analise",
    response_model=AnaliseOut,
    summary="Análise da redação (MOCK estático na fatia A)",
)
async def analise_redacao(redacao_id: int):
    item = next((r for r in _REDACOES if r["id"] == redacao_id), None)
    if item is None:
        raise HTTPException(status_code=404, detail="redacao_nao_encontrada")

    # Só a redação 2 ("Um herói brasileiro") está analisada no mock; as demais
    # devolvem a análise vazia — a tela mostra o estado "em análise".
    if item["status"] == "analisada":
        return AnaliseOut(
            mock=True,
            redacao_id=redacao_id,
            status="analisada",
            texto_extraido=_TEXTO_HEROI,
            analise=_montar_analise_heroi(),
            palavras_novas=[PalavraNova(**p) for p in _PALAVRAS_NOVAS_HEROI],
        )
    return AnaliseOut(
        mock=True,
        redacao_id=redacao_id,
        status=item["status"],
        texto_extraido="",
        analise=None,
        palavras_novas=[],
    )
