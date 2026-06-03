"""Regras puras de XP/combo (seção 3.7) — sem banco."""
from datetime import date, timedelta

from app.progressao import xp


def test_xp_base_por_tentativa():
    assert xp.xp_base(1) == 100
    assert xp.xp_base(2) == 70
    assert xp.xp_base(3) == 50
    assert xp.xp_base(9) == 50  # piso


def test_acerto_primeira_inicia_combo():
    hoje = date.today()
    r = xp.pontuar(correto=True, tentativa=1, combo_atual=0, combo_data=None, hoje=hoje)
    assert r.combo == 1
    assert r.xp == 100 + (18 + 2 * 1)  # 120


def test_combo_cresce_no_acerto_de_primeira():
    hoje = date.today()
    r = xp.pontuar(correto=True, tentativa=1, combo_atual=1, combo_data=hoje, hoje=hoje)
    assert r.combo == 2
    assert r.xp == 100 + (18 + 2 * 2)  # 122


def test_erro_zera_combo_e_nao_da_xp():
    hoje = date.today()
    r = xp.pontuar(correto=False, tentativa=1, combo_atual=5, combo_data=hoje, hoje=hoje)
    assert r.combo == 0
    assert r.xp == 0


def test_acerto_na_segunda_zera_combo_e_xp_70():
    hoje = date.today()
    r = xp.pontuar(correto=True, tentativa=2, combo_atual=4, combo_data=hoje, hoje=hoje)
    assert r.combo == 0
    assert r.xp == 70


def test_combo_zera_em_novo_dia():
    hoje = date.today()
    ontem = hoje - timedelta(days=1)
    r = xp.pontuar(correto=True, tentativa=1, combo_atual=9, combo_data=ontem, hoje=hoje)
    assert r.combo == 1  # recomeçou do zero e incrementou
    assert r.xp == 100 + (18 + 2 * 1)
