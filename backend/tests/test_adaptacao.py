"""Regra pura da adaptação contínua (Bloco 2a) — sem banco."""
from app.adaptacao import regras


def test_sobe_com_acuracia_alta_e_janela_cheia():
    novo, mudou = regras.decidir(acuracia=0.95, amostra=10, nivel_atual=3, pode_mover=True)
    assert mudou and novo == 4


def test_desce_com_acuracia_baixa():
    novo, mudou = regras.decidir(acuracia=0.40, amostra=10, nivel_atual=3, pode_mover=True)
    assert mudou and novo == 2


def test_mantem_na_zona_intermediaria():
    novo, mudou = regras.decidir(acuracia=0.70, amostra=10, nivel_atual=3, pode_mover=True)
    assert not mudou and novo == 3


def test_histerese_exige_janela_cheia():
    # sinal forte, mas amostra insuficiente → não move
    novo, mudou = regras.decidir(acuracia=1.0, amostra=4, nivel_atual=3, pode_mover=True)
    assert not mudou and novo == 3


def test_cooldown_bloqueia_movimento():
    novo, mudou = regras.decidir(acuracia=1.0, amostra=10, nivel_atual=3, pode_mover=False)
    assert not mudou and novo == 3


def test_respeita_limites():
    assert regras.decidir(acuracia=1.0, amostra=10, nivel_atual=10, pode_mover=True) == (10, False)
    assert regras.decidir(acuracia=0.0, amostra=10, nivel_atual=1, pode_mover=True) == (1, False)


def test_sem_amostra_nao_move():
    novo, mudou = regras.decidir(acuracia=None, amostra=0, nivel_atual=3, pode_mover=True)
    assert not mudou and novo == 3
