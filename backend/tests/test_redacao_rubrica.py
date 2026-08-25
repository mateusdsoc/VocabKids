"""Rubrica de redação — regra pura (Fase 4, docs/plano_b2c.md §7.2)."""
from app.redacao.rubrica import RUBRICA, validar_tamanho


def test_coesao_pesa_zero_aos_7_8():
    assert RUBRICA["7-8"].peso["coesao"] == 0.0


def test_todas_as_faixas_tem_peso_1():
    for faixa, rubrica in RUBRICA.items():
        assert round(sum(rubrica.peso.values()), 6) == 1.0, faixa


def test_validar_tamanho_texto_curto_e_rejeitado_com_motivo_gentil():
    resultado = validar_tamanho("7-8", "um texto bem curto")
    assert resultado.ok is False
    assert "40" in resultado.motivo  # min_palavras da faixa 7-8


def test_validar_tamanho_dentro_do_minimo_passa():
    texto = " ".join(["palavra"] * 50)
    resultado = validar_tamanho("7-8", texto)
    assert resultado.ok is True
    assert resultado.motivo is None


def test_validar_tamanho_sem_limite_superior():
    texto = " ".join(["palavra"] * 1000)
    assert validar_tamanho("11-12", texto).ok is True
