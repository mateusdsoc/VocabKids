"""Cliente de IA para a análise de redação (Fase 4, `docs/plano_b2c.md` §7.3/7.5).

Uma chamada só cobre TRIAGEM DE RISCO (R-RD-7) + análise pedagógica pela
rubrica da faixa — trade-off deliberado de custo por chamada de LLM (§7.3: "1
chamada Claude"). Isto é mais fraco do que um classificador de segurança
dedicado e independente do prompt pedagógico (que não erra junto se o prompt
pedagógico "distrair" o modelo) — ver a pendência registrada em
`design/notas-implementacao.md` (Fase 4, 25/08) antes de tratar isto como
hardening suficiente para produção.

`Analisador` é um Protocol para o service depender de uma interface, não da
implementação Claude — os testes usam um fake em memória (sem chamada de rede,
sem precisar de `ANTHROPIC_API_KEY`).
"""
from dataclasses import dataclass, field
from typing import Protocol

from anthropic import AsyncAnthropic

from app.config import settings
from app.errors import ApiError
from app.redacao.rubrica import DIMENSOES, RUBRICA

# R-RD-6: pro RESPONSÁVEL, métrica por dimensão em escala visual nomeada (não
# número de 0 a 10 — isso é só pra criança, R-RD-5). 4 níveis, do mais cedo ao
# mais consolidado — nomes neutros, sem "ruim"/"péssimo".
NIVEIS_DIMENSAO = ("começando", "avançando", "consolidando", "dominando")


@dataclass(frozen=True)
class Ancora:
    trecho: str
    ocorrencia: int  # 1ª, 2ª, ... ocorrência do trecho no texto


@dataclass(frozen=True)
class AnotacaoAnalise:
    dimensao: str
    titulo: str
    comentario: str
    sugestoes: list[str] = field(default_factory=list)
    ancoras: list[Ancora] = field(default_factory=list)  # vazia = holística


@dataclass(frozen=True)
class PalavraExtraida:
    texto: str
    lema: str
    tipo: str  # 'fraca' | 'superutilizada'


@dataclass(frozen=True)
class ResultadoAnalise:
    risco_sinalizado: bool
    risco_motivo: str | None
    pontos_fortes: list[str] = field(default_factory=list)
    anotacoes: list[AnotacaoAnalise] = field(default_factory=list)
    palavras: list[PalavraExtraida] = field(default_factory=list)
    # R-RD-6 — só as dimensões efetivamente avaliadas (rubrica pode zerar uma,
    # ex. coesão aos 7-8); dashboard do responsável (Fase 5) lê isto ao longo
    # do tempo pra montar a evolução por dimensão.
    niveis_dimensao: dict[str, str] = field(default_factory=dict)


class Analisador(Protocol):
    async def analisar(
        self, *, texto: str, faixa_etaria: str, tema: str
    ) -> ResultadoAnalise: ...


_PROMPT_SISTEMA = """Você é um assistente pedagógico que analisa redações de \
crianças de 7 a 12 anos para o app VocabKids. Sua resposta tem dois papéis, \
NESTA ORDEM DE PRIORIDADE:

1. TRIAGEM DE SEGURANÇA (a mais importante): se o texto contiver qualquer \
sinal de violência doméstica, abuso, autolesão ou risco à criança — mesmo que \
sutil ou indireto — marque `risco_sinalizado=true`, descreva o motivo em \
`risco_motivo` (linguagem factual, para um adulto ler) e NÃO preencha \
`anotacoes`/`pontos_fortes`/`palavras`. Na dúvida, sinalize — falso positivo \
custa uma revisão humana; falso negativo pode custar uma criança.

2. Se não houver risco, analise a redação pela rubrica da faixa etária \
informada: aponte pontos fortes primeiro, depois de 2 a 4 anotações \
acionáveis (uma por dimensão relevante), e extraia palavras fracas \
(genéricas, tipo "legal"/"coisa") ou superutilizadas (repetidas 3+ vezes) \
como sugestão de vocabulário novo. Tom: NUNCA aponte erro como falha — trate \
como oportunidade de aprender uma palavra melhor. Siga a tolerância \
ortográfica e o tom da rubrica à risca; nunca mostre nota numérica.

Cada anotação pode citar até 2 âncoras (trecho literal do texto + número da \
ocorrência, contando do início) para grifar no app — omita quando a \
observação for holística (ex.: estrutura do texto como um todo).

3. Classifique CADA dimensão com peso > 0 na rubrica desta faixa em um dos 4 \
níveis: "começando", "avançando", "consolidando", "dominando" — isto NUNCA é \
mostrado à criança (só ao responsável, depois, em outra tela), então seja \
honesto mesmo quando o nível for baixo; não é punição, é calibração."""


def _montar_prompt(*, texto: str, faixa_etaria: str, tema: str) -> str:
    rubrica = RUBRICA[faixa_etaria]
    pesos = ", ".join(f"{d}={rubrica.peso[d]}" for d in DIMENSOES)
    return (
        f"Tema proposto: {tema}\n"
        f"Faixa etária: {faixa_etaria} anos\n"
        f"Pesos da rubrica: {pesos}\n"
        f"Tolerância ortográfica: {rubrica.tolerancia_ortografica}\n"
        f"Tom esperado: {rubrica.tom}\n\n"
        f"Texto da criança:\n{texto}"
    )


_FERRAMENTA_RELATORIO = {
    "name": "reportar_analise",
    "description": "Reporta o resultado da triagem de segurança e (se aplicável) da análise pedagógica.",
    "input_schema": {
        "type": "object",
        "properties": {
            "risco_sinalizado": {"type": "boolean"},
            "risco_motivo": {"type": ["string", "null"]},
            "pontos_fortes": {"type": "array", "items": {"type": "string"}},
            "anotacoes": {
                "type": "array",
                "items": {
                    "type": "object",
                    "properties": {
                        "dimensao": {"type": "string", "enum": DIMENSOES},
                        "titulo": {"type": "string"},
                        "comentario": {"type": "string"},
                        "sugestoes": {"type": "array", "items": {"type": "string"}},
                        "ancoras": {
                            "type": "array",
                            "items": {
                                "type": "object",
                                "properties": {
                                    "trecho": {"type": "string"},
                                    "ocorrencia": {"type": "integer", "minimum": 1},
                                },
                                "required": ["trecho", "ocorrencia"],
                            },
                        },
                    },
                    "required": ["dimensao", "titulo", "comentario"],
                },
            },
            "palavras": {
                "type": "array",
                "items": {
                    "type": "object",
                    "properties": {
                        "texto": {"type": "string"},
                        "lema": {"type": "string"},
                        "tipo": {"type": "string", "enum": ["fraca", "superutilizada"]},
                    },
                    "required": ["texto", "lema", "tipo"],
                },
            },
            "niveis_dimensao": {
                "type": "object",
                "description": "Uma entrada por dimensão com peso > 0 na rubrica da faixa.",
                "additionalProperties": {"type": "string", "enum": list(NIVEIS_DIMENSAO)},
            },
        },
        "required": ["risco_sinalizado"],
    },
}


def _parse_resposta(entrada: dict) -> ResultadoAnalise:
    return ResultadoAnalise(
        risco_sinalizado=bool(entrada.get("risco_sinalizado", False)),
        risco_motivo=entrada.get("risco_motivo"),
        pontos_fortes=list(entrada.get("pontos_fortes") or []),
        anotacoes=[
            AnotacaoAnalise(
                dimensao=a["dimensao"],
                titulo=a["titulo"],
                comentario=a["comentario"],
                sugestoes=list(a.get("sugestoes") or []),
                ancoras=[
                    Ancora(trecho=n["trecho"], ocorrencia=n["ocorrencia"])
                    for n in (a.get("ancoras") or [])
                ],
            )
            for a in (entrada.get("anotacoes") or [])
        ],
        palavras=[
            PalavraExtraida(texto=p["texto"], lema=p["lema"], tipo=p["tipo"])
            for p in (entrada.get("palavras") or [])
        ],
        niveis_dimensao=dict(entrada.get("niveis_dimensao") or {}),
    )


class AnalisadorClaude:
    """Implementação real — chamada única ao Claude, JSON forçado por tool-use.

    ⚠️ Pendência explícita (ver `design/notas-implementacao.md`, Fase 4,
    25/08): este código nunca rodou contra a API de verdade nesta sessão (sem
    `ANTHROPIC_API_KEY` no ambiente do agente). O contrato do prompt/schema
    está implementado por inteiro, mas falta VALIDAR ao vivo que o modelo
    respeita o schema e que o prompt produz anotações de qualidade — inclusive
    a triagem de risco (R-RD-7), que é a parte mais crítica de acertar.
    """

    def __init__(self, api_key: str | None = None, modelo: str | None = None):
        self._api_key = api_key if api_key is not None else settings.anthropic_api_key
        self._modelo = modelo or settings.anthropic_modelo_redacao

    async def analisar(self, *, texto: str, faixa_etaria: str, tema: str) -> ResultadoAnalise:
        if not self._api_key:
            raise ApiError(
                503,
                "analise_indisponivel",
                "Configuração de IA pendente — defina ANTHROPIC_API_KEY.",
            )
        cliente = AsyncAnthropic(api_key=self._api_key)
        resposta = await cliente.messages.create(
            model=self._modelo,
            max_tokens=2000,
            system=_PROMPT_SISTEMA,
            tools=[_FERRAMENTA_RELATORIO],
            tool_choice={"type": "tool", "name": "reportar_analise"},
            messages=[
                {"role": "user", "content": _montar_prompt(texto=texto, faixa_etaria=faixa_etaria, tema=tema)}
            ],
        )
        bloco = next((b for b in resposta.content if b.type == "tool_use"), None)
        if bloco is None:
            raise ApiError(502, "analise_malformada", "A IA não devolveu um relatório estruturado.")
        return _parse_resposta(bloco.input)


def get_analisador() -> Analisador:
    """Dependency FastAPI — troca por um fake em teste via `app.dependency_overrides`
    (a suíte não faz chamada de rede nem depende de `ANTHROPIC_API_KEY`)."""
    return AnalisadorClaude()
