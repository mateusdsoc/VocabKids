"""Rubrica de redação por faixa etária (Fase 4, `docs/plano_b2c.md` §7.2).

Módulo **puro** (sem I/O), no padrão de `progressao/xp.py` e
`progressao/faixa.py`. R-RD-3: a rubrica é fixa por faixa, definida aqui no
código e versionada — nem pai nem criança editam.
"""
from dataclasses import dataclass

DIMENSOES = ["vocabulario", "coesao", "ortografia", "estrutura", "adequacao_ao_tema"]


@dataclass(frozen=True)
class RubricaFaixa:
    min_palavras: int
    max_palavras: int
    peso: dict[str, float]
    tolerancia_ortografica: str  # 'alta' | 'media' | 'baixa'
    tom: str


# ⚠️ Coesão pesa ZERO aos 7-8 de propósito: cobrar conectivo de quem está
# aprendendo a formar frase é pedagogicamente errado e desmotiva (§7.2).
RUBRICA: dict[str, RubricaFaixa] = {
    "7-8": RubricaFaixa(
        min_palavras=40,
        max_palavras=120,
        peso={
            "vocabulario": 0.3,
            "ortografia": 0.3,
            "adequacao_ao_tema": 0.3,
            "estrutura": 0.1,
            "coesao": 0.0,
        },
        tolerancia_ortografica="alta",
        tom="celebra o esforço; aponta 1 melhoria por vez, nunca uma lista de erros",
    ),
    "9-10": RubricaFaixa(
        min_palavras=80,
        max_palavras=200,
        peso={
            "vocabulario": 0.25,
            "ortografia": 0.2,
            "adequacao_ao_tema": 0.25,
            "estrutura": 0.15,
            "coesao": 0.15,
        },
        tolerancia_ortografica="media",
        tom="reconhece o que funcionou antes de sugerir uma melhoria",
    ),
    "11-12": RubricaFaixa(
        min_palavras=120,
        max_palavras=300,
        peso={
            "vocabulario": 0.2,
            "ortografia": 0.15,
            "adequacao_ao_tema": 0.2,
            "estrutura": 0.2,
            "coesao": 0.25,
        },
        tolerancia_ortografica="baixa",
        tom="direto, mas nunca punitivo — trata a criança como escritora em formação",
    ),
}


@dataclass(frozen=True)
class ValidacaoTamanho:
    ok: bool
    motivo: str | None = None


def validar_tamanho(faixa_etaria: str, texto: str) -> ValidacaoTamanho:
    """Texto curto demais não vai pra análise — devolve gentil (§7.3 passo 1).

    Não há reprovação por texto LONGO demais: `max_palavras` é só contexto
    pro prompt do analisador, não um corte.
    """
    rubrica = RUBRICA[faixa_etaria]
    n_palavras = len([p for p in texto.split() if p.strip()])
    if n_palavras < rubrica.min_palavras:
        return ValidacaoTamanho(
            ok=False,
            motivo=(
                f"Sua redação tem {n_palavras} palavras — escreva pelo menos "
                f"{rubrica.min_palavras} para a gente poder te dar um retorno completo."
            ),
        )
    return ValidacaoTamanho(ok=True)
