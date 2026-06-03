"""Escada grosso→fino do diagnóstico — lógica pura (Bloco 2a)."""
from app.diagnostico import escada


def _rodar(ano, respostas):
    """Roda a escada com uma sequência de acertos/erros; devolve o nível final."""
    estado = escada.iniciar(ano)
    for acertou in respostas:
        estado, nivel = escada.avancar(estado, acertou)
        if nivel is not None:
            return nivel
    raise AssertionError("não terminou com a sequência dada")


def test_nivel_inicial_por_ano():
    assert escada.nivel_inicial(7) == 3
    assert escada.nivel_inicial(6) == 2
    assert escada.nivel_inicial(9) == 5
    assert escada.nivel_inicial(None) == 3  # default


def test_iniciar_fase_grossa():
    e = escada.iniciar(7)
    assert e.fase == "grossa" and e.nivel == 3 and e.passo == 2


def test_bracket_e_confirmacao_dao_placement_conservador():
    # 7º (nível 3): acerta 3 e 5, erra 7 e 6, acerta 5, confirma 2x → ceiling 5
    nivel = _rodar(7, [True, True, False, False, True, True, True])
    assert nivel == 4  # max(1, 5 - 1) conservador


def test_desconto_de_chute_derruba_o_ceiling():
    # mesmo bracket (candidato 5), mas erra uma da confirmação → ceiling 4
    nivel = _rodar(7, [True, True, False, False, True, True, False])
    assert nivel == 3  # max(1, 4 - 1)


def test_aluno_fraco_cai_para_o_minimo():
    # erra a 1ª (vai p/ fina nível 2), acerta nível 2, confirma 2x → ceiling 2
    nivel = _rodar(7, [False, True, True, True])
    assert nivel == 1  # max(1, 2 - 1)


def test_falhar_ate_o_nivel_1():
    # erra tudo descendo até o piso
    nivel = _rodar(7, [False, False, False])
    assert nivel == 1


def test_aluno_forte_chega_ao_topo():
    # acerta tudo: sobe 3→5→7→9→10, confirma 10 duas vezes → ceiling 10
    nivel = _rodar(7, [True, True, True, True, True, True, True])
    assert nivel == 9  # max(1, 10 - 1)


def test_orcamento_maximo_de_15_perguntas():
    estado = escada.iniciar(7)
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
