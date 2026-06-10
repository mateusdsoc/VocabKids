"""Regras de XP e combo no momento da resposta (seção 3.7 / Bloco 2a).

Funções **puras** (sem banco) — fáceis de calibrar e testar. Valores são
constantes do MVP, ajustáveis com telemetria depois.

    xp_base = 100 (1ª tentativa) | 70 (2ª) | 50 (3ª+, piso)
    combo:   só acerto de 1ª tentativa incrementa; bônus = 18 + 2×posição
             zera ao errar e ao acertar só na 2ª; é POR SESSÃO — zera ao
             abrir cada sessão (decidido 10/06), não carrega entre sessões
    bônus de domínio (passar o N4): +500
"""
from dataclasses import dataclass

XP_PRIMEIRA = 100
XP_SEGUNDA = 70
XP_PISO = 50
COMBO_BONUS_BASE = 18
COMBO_BONUS_POR_POSICAO = 2
BONUS_DOMINIO = 500


def xp_base(tentativa: int) -> int:
    if tentativa <= 1:
        return XP_PRIMEIRA
    if tentativa == 2:
        return XP_SEGUNDA
    return XP_PISO


@dataclass(frozen=True)
class ResultadoPontuacao:
    xp: int            # XP da questão (sem o bônus de domínio)
    combo: int         # novo combo


def pontuar(
    *,
    correto: bool,
    tentativa: int,
    combo_atual: int,
) -> ResultadoPontuacao:
    """XP/combo de uma resposta. `tentativa` é a nº desta resposta (1 = primeira).

    `combo_atual` é o combo da sessão corrente — quem zera entre sessões é a
    abertura da sessão (`montar_sessao`), não esta função.
    """
    combo = combo_atual

    if not correto:
        return ResultadoPontuacao(xp=0, combo=0)

    base = xp_base(tentativa)
    if tentativa == 1:
        combo += 1  # só o acerto de 1ª tentativa incrementa
        bonus = COMBO_BONUS_BASE + COMBO_BONUS_POR_POSICAO * combo
    else:
        combo = 0   # acertar só na 2ª (ou mais) zera o combo
        bonus = 0
    return ResultadoPontuacao(xp=base + bonus, combo=combo)
