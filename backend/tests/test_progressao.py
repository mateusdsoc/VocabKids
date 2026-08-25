"""Regras puras de XP/combo (seção 3.7) — sem banco.

O combo é por sessão: quem zera entre sessões é a abertura da sessão
(`montar_sessao` → `zerar_combo`), testada em `test_sessao.py`. Aqui, `pontuar`
só continua o combo recebido.
"""
from app.progressao import xp


def test_xp_base_por_tentativa():
    assert xp.xp_base(1) == 100
    assert xp.xp_base(2) == 70
    assert xp.xp_base(3) == 50
    assert xp.xp_base(9) == 50  # piso


def test_acerto_primeira_inicia_combo():
    r = xp.pontuar(correto=True, tentativa=1, combo_atual=0)
    assert r.combo == 1
    assert r.xp == 100 + (18 + 2 * 1)  # 120


def test_combo_cresce_no_acerto_de_primeira():
    r = xp.pontuar(correto=True, tentativa=1, combo_atual=1)
    assert r.combo == 2
    assert r.xp == 100 + (18 + 2 * 2)  # 122


def test_erro_zera_combo_e_nao_da_xp():
    r = xp.pontuar(correto=False, tentativa=1, combo_atual=5)
    assert r.combo == 0
    assert r.xp == 0


def test_acerto_na_segunda_zera_combo_e_xp_70():
    r = xp.pontuar(correto=True, tentativa=2, combo_atual=4)
    assert r.combo == 0
    assert r.xp == 70


def test_pontuar_continua_o_combo_da_sessao():
    # `pontuar` não conhece dia/sessão: só continua o combo recebido.
    r = xp.pontuar(correto=True, tentativa=1, combo_atual=9)
    assert r.combo == 10
    assert r.xp == 100 + (18 + 2 * 10)  # 138


# ─────────────────── semana letiva e meta (§3.5) — regras puras ───────────────────

from datetime import datetime, timezone

from app.progressao.semana import FUSO_ESCOLA, inicio_da_semana


def test_inicio_da_semana_e_segunda_a_meia_noite_no_fuso_da_escola():
    # Quinta-feira 16/07/2026 15h em São Paulo → segunda 13/07 00:00.
    quinta = datetime(2026, 7, 16, 15, 0, tzinfo=FUSO_ESCOLA)
    inicio = inicio_da_semana(quinta)
    assert inicio == datetime(2026, 7, 13, 0, 0, tzinfo=FUSO_ESCOLA)
    # Segunda 00:00 é o próprio corte (não volta uma semana).
    assert inicio_da_semana(inicio) == inicio


def test_inicio_da_semana_converte_fusos():
    # Terça 00:30 UTC ainda é segunda 21:30 em São Paulo → corte é a MESMA segunda.
    terca_utc = datetime(2026, 7, 14, 0, 30, tzinfo=timezone.utc)
    assert inicio_da_semana(terca_utc) == datetime(
        2026, 7, 13, 0, 0, tzinfo=FUSO_ESCOLA
    )


# Meta semanal por faixa: coberta em test_progressao_faixa.py.
