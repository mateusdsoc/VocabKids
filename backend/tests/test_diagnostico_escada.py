"""Escada grosso→fino do diagnóstico — lógica pura (Bloco 2a).

B2C (docs/plano_b2c.md Fase 2): nível inicial vem da faixa etária da criança,
não mais do ano da turma. Sequências recalculadas para a faixa 11-12 (nível
inicial 4), que é a que mais se aproxima do 7º ano usado nos testes originais.
"""
from app.diagnostico import escada


def _rodar(faixa, respostas):
    """Roda a escada com uma sequência de acertos/erros; devolve o nível final."""
    estado = escada.iniciar(faixa)
    for acertou in respostas:
        estado, nivel = escada.avancar(estado, acertou)
        if nivel is not None:
            return nivel
    raise AssertionError("não terminou com a sequência dada")


def test_nivel_inicial_por_faixa():
    assert escada.nivel_inicial("7-8") == 1
    assert escada.nivel_inicial("9-10") == 2
    assert escada.nivel_inicial("11-12") == 4
    assert escada.nivel_inicial(None) == 4  # default (FAIXA_PADRAO = '11-12')


def test_iniciar_fase_grossa():
    e = escada.iniciar("11-12")
    assert e.fase == "grossa" and e.nivel == 4 and e.passo == 2


def test_bracket_e_confirmacao_dao_placement_conservador():
    # 11-12 (nível 4): acerta 4 e 6, erra 8 e 7, acerta 6, confirma 2x → ceiling 6
    nivel = _rodar("11-12", [True, True, False, False, True, True, True])
    assert nivel == 5  # max(1, 6 - 1) conservador


def test_desconto_de_chute_derruba_o_ceiling():
    # mesmo bracket (candidato 6), mas erra uma da confirmação → ceiling 5
    nivel = _rodar("11-12", [True, True, False, False, True, True, False])
    assert nivel == 4  # max(1, 5 - 1)


def test_aluno_fraco_cai_para_o_minimo():
    # erra a 1ª (vai p/ fina nível 3), acerta nível 3, confirma 2x → ceiling 3
    nivel = _rodar("11-12", [False, True, True, True])
    assert nivel == 2  # max(1, 3 - 1)


def test_falhar_ate_o_nivel_1():
    # erra tudo descendo até o piso
    nivel = _rodar("11-12", [False, False, False, False, False])
    assert nivel == 1


def test_aluno_forte_chega_ao_topo():
    # acerta tudo: sobe 4→6→8→10, confirma 10 duas vezes → ceiling 10
    nivel = _rodar("11-12", [True, True, True, True, True, True, True])
    assert nivel == 9  # max(1, 10 - 1)


def test_orcamento_de_perguntas_varia_por_faixa():
    """docs/plano_b2c.md Fase 2, §5.1: 7-8 anos aguenta menos perguntas
    seguidas — o orçamento nasce no `iniciar()` e viaja no estado."""
    assert escada.iniciar("7-8").max_perguntas == 10
    assert escada.iniciar("9-10").max_perguntas == 12
    assert escada.iniciar("11-12").max_perguntas == 15
    assert escada.iniciar(None).max_perguntas == 15  # default = FAIXA_PADRAO


def test_orcamento_da_faixa_7_8_encerra_mais_cedo():
    """Alternando acerto/erro (sem bracket rápido), a faixa 7-8 termina em até
    10 perguntas — não nas 15 do teto antigo."""
    estado = escada.iniciar("7-8")
    perguntas = 0
    seq = [True, False] * 10
    nivel = None
    for acertou in seq:
        estado, nivel = escada.avancar(estado, acertou)
        perguntas += 1
        if nivel is not None:
            break
    assert nivel is not None
    assert perguntas <= 10


def test_orcamento_maximo_de_15_perguntas():
    estado = escada.iniciar("11-12")
    perguntas = 0
    # alterna para evitar bracket rápido; deve terminar em <= 15
    seq = [True, False] * 10
    for acertou in seq:
        estado, nivel = escada.avancar(estado, acertou)
        perguntas += 1
        if nivel is not None:
            break
    assert nivel is not None
    assert perguntas <= escada.MAX_PERGUNTAS
