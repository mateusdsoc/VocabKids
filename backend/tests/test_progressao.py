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
