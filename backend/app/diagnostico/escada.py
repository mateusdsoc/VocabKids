"""Escada grosso→fino do diagnóstico — lógica pura (Bloco 2a, decisão #1).

    fase GROSSA (passo 2): acha a faixa rápido
       acertou → sobe 2;  errou → vira FINA (teto = nível) e desce 1
    fase FINA (passo 1): refina
       acertou → bracket (passou L, falhou L+1) → CONFIRMAÇÃO no candidato
       errou → teto = nível, desce 1
    CONFIRMAÇÃO (desconto de chute): 2 questões no candidato
       2 acertos → ceiling = candidato;  senão → ceiling = candidato − 1
    placement CONSERVADOR: nivel_dificuldade_atual = max(1, ceiling − 1)

Para no bracket+confirmação ou ao esgotar o orçamento de perguntas — que varia
por faixa etária (B2C, docs/plano_b2c.md Fase 2, §5.1: 7-8 anos aguenta menos
perguntas seguidas que 11-12). As 2 demos (acerto/erro) que antecedem o
diagnóstico são da UI (3.5), não daqui.

Funções puras (sem banco). A escolha das questões e a persistência ficam no
serviço; aqui só decidimos o próximo nível / quando terminou.
"""
from app.diagnostico.schemas import EstadoDiagnostico
from app.progressao import faixa as faixa_mod

MAX_PERGUNTAS = 15  # teto do orçamento (faixa 11-12) — default de cliente antigo
CONFIRMA_NECESSARIAS = 2
PASSO_GROSSO = 2
NIVEL_MIN = 1
NIVEL_MAX = 10
FAIXA_PADRAO = "11-12"

MAX_PERGUNTAS_POR_FAIXA = {"7-8": 10, "9-10": 12, "11-12": 15}


def nivel_inicial(faixa_etaria: str | None) -> int:
    """Default por faixa etária da criança (B2C — substitui o corte por
    `ano_escolar` da turma, docs/plano_b2c.md Fase 2)."""
    faixa_valida = faixa_etaria or FAIXA_PADRAO
    return max(NIVEL_MIN, min(NIVEL_MAX, faixa_mod.nivel_inicial(faixa_valida)))


def max_perguntas_da_faixa(faixa_etaria: str | None) -> int:
    return MAX_PERGUNTAS_POR_FAIXA.get(faixa_etaria or FAIXA_PADRAO, MAX_PERGUNTAS)


def iniciar(faixa_etaria: str | None) -> EstadoDiagnostico:
    return EstadoDiagnostico(
        fase="grossa",
        nivel=nivel_inicial(faixa_etaria),
        passo=PASSO_GROSSO,
        max_perguntas=max_perguntas_da_faixa(faixa_etaria),
    )


def _placement(ceiling: int) -> int:
    return max(NIVEL_MIN, ceiling - 1)


def _confirmar(estado: EstadoDiagnostico, base: dict, candidato: int):
    e = estado.model_copy(
        update={
            **base,
            "fase": "confirmacao",
            "nivel": candidato,
            "ceiling_candidato": candidato,
            "confirma_acertos": 0,
            "confirma_feitas": 0,
        }
    )
    if e.perguntas >= e.max_perguntas:
        return None, _placement(candidato)  # sem orçamento para confirmar; aceita
    return e, None


def _continuar_ou_orcamento(e: EstadoDiagnostico, ultimo_passou: int | None):
    if e.perguntas >= e.max_perguntas:
        ceiling = ultimo_passou if ultimo_passou is not None else NIVEL_MIN
        return None, _placement(ceiling)
    return e, None


def avancar(estado: EstadoDiagnostico, acertou: bool) -> tuple[EstadoDiagnostico | None, int | None]:
    """Processa uma resposta. Retorna (proximo_estado, None) para continuar ou
    (None, nivel_final) quando o diagnóstico termina."""
    perguntas = estado.perguntas + 1
    ultimo = estado.ultimo_passou
    if acertou and (ultimo is None or estado.nivel > ultimo):
        ultimo = estado.nivel
    base = {"perguntas": perguntas, "ultimo_passou": ultimo}

    if estado.fase == "grossa":
        if acertou:
            if estado.nivel >= NIVEL_MAX:
                return _confirmar(estado, base, candidato=NIVEL_MAX)
            e = estado.model_copy(
                update={**base, "nivel": min(NIVEL_MAX, estado.nivel + estado.passo)}
            )
            return _continuar_ou_orcamento(e, ultimo)
        if estado.nivel <= NIVEL_MIN:
            return None, _placement(0)  # falhou até no mínimo
        e = estado.model_copy(
            update={
                **base,
                "fase": "fina",
                "passo": 1,
                "teto": estado.nivel,
                "nivel": estado.nivel - 1,
            }
        )
        return _continuar_ou_orcamento(e, ultimo)

    if estado.fase == "fina":
        if acertou:
            return _confirmar(estado, base, candidato=estado.nivel)
        if estado.nivel <= NIVEL_MIN:
            return None, _placement(0)
        e = estado.model_copy(
            update={**base, "teto": estado.nivel, "nivel": estado.nivel - 1}
        )
        return _continuar_ou_orcamento(e, ultimo)

    # confirmacao
    feitas = estado.confirma_feitas + 1
    acertos = estado.confirma_acertos + (1 if acertou else 0)
    candidato = estado.ceiling_candidato
    if feitas >= CONFIRMA_NECESSARIAS:
        ceiling = candidato if acertos >= CONFIRMA_NECESSARIAS else candidato - 1
        return None, _placement(ceiling)
    e = estado.model_copy(
        update={**base, "confirma_feitas": feitas, "confirma_acertos": acertos}
    )
    if perguntas >= estado.max_perguntas:
        ceiling = candidato if acertos >= 1 else candidato - 1
        return None, _placement(ceiling)
    return e, None
