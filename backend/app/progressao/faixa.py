"""Faixa etária — eixo de calibração do B2C (docs/plano_b2c.md Fase 2).

Substitui `ano_escolar` da turma como parâmetro que calibra nível inicial do
diagnóstico e meta semanal. Funções puras (sem I/O), no padrão de `xp.py` e
`adaptacao/regras.py`.

Faixas travadas (decisão do dono, seção 01 do plano): 7-8, 9-10, 11-12.
"""

FAIXAS = ("7-8", "9-10", "11-12")


def faixa_de(ano_nascimento: int, ano_atual: int) -> str:
    """Deriva a faixa etária a partir do ano de nascimento (R-ID-4: recalculada
    no aniversário, não fixada na criação — mas aqui é só a função pura;
    o "quando recalcular" é do job, não desta função)."""
    idade = ano_atual - ano_nascimento
    if idade <= 8:
        return "7-8"
    if idade <= 10:
        return "9-10"
    return "11-12"


# Nível inicial do diagnóstico por faixa (substitui o corte por ano_escolar).
_NIVEL_INICIAL_POR_FAIXA = {"7-8": 1, "9-10": 2, "11-12": 4}

# Meta semanal default por faixa (substitui META_DEFAULT_POR_ANO).
_META_SEMANAL_POR_FAIXA = {"7-8": 3, "9-10": 4, "11-12": 5}

# Nível máximo de palavra que a faixa pode receber (R-FX-1, docs/plano_b2c.md):
# a adaptação sobe DENTRO da faixa, nunca extrapola para cima.
_NIVEL_MAXIMO_POR_FAIXA = {"7-8": 4, "9-10": 7, "11-12": 10}


def nivel_inicial(faixa_etaria: str) -> int:
    return _NIVEL_INICIAL_POR_FAIXA[faixa_etaria]


def meta_semanal_default(faixa_etaria: str) -> int:
    return _META_SEMANAL_POR_FAIXA[faixa_etaria]


def nivel_maximo(faixa_etaria: str) -> int:
    return _NIVEL_MAXIMO_POR_FAIXA[faixa_etaria]
