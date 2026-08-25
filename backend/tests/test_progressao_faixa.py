"""Faixa etária — regra pura (docs/plano_b2c.md Fase 2)."""
from app.progressao import faixa


def test_faixa_de_por_idade():
    assert faixa.faixa_de(2019, 2026) == "7-8"   # 7 anos
    assert faixa.faixa_de(2018, 2026) == "7-8"   # 8 anos
    assert faixa.faixa_de(2017, 2026) == "9-10"  # 9 anos
    assert faixa.faixa_de(2015, 2026) == "11-12"  # 11 anos
    assert faixa.faixa_de(2010, 2026) == "11-12"  # 16 anos (acima da faixa, cai no topo)


def test_nivel_inicial_sobe_com_a_faixa():
    assert faixa.nivel_inicial("7-8") < faixa.nivel_inicial("9-10") < faixa.nivel_inicial("11-12")


def test_meta_semanal_default_sobe_com_a_faixa():
    assert (
        faixa.meta_semanal_default("7-8")
        < faixa.meta_semanal_default("9-10")
        < faixa.meta_semanal_default("11-12")
    )


def test_nivel_maximo_respeita_o_teto_de_10():
    for f in faixa.FAIXAS:
        assert 1 <= faixa.nivel_maximo(f) <= 10
    assert faixa.nivel_maximo("11-12") == 10
