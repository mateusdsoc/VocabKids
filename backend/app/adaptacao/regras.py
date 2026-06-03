"""Adaptação contínua de nível — decisão pura (Bloco 2a).

Roda ao fim de cada sessão. O **sinal limpo** é a acurácia de 1ª tentativa nas
questões de palavras do nível atual (janela móvel ~10); revisão é excluída para
não inflar o número (aproximada aqui pelo filtro de nível — ver `service`).

    ≥ 90% → sobe um nível (acelera)
    ≤ 50% → desce um nível (recupera placement alto demais)
    entre → mantém

Histerese: só move com a **janela cheia**; um nível por vez; **cooldown** de 1
sessão após mover. Limiares/janela/cooldown são configuráveis (telemetria calibra).
"""
JANELA = 10
LIMIAR_SOBE = 0.90
LIMIAR_DESCE = 0.50
COOLDOWN_SESSOES = 1
NIVEL_MIN = 1
NIVEL_MAX = 10


def decidir(
    *,
    acuracia: float | None,
    amostra: int,
    nivel_atual: int,
    pode_mover: bool,
) -> tuple[int, bool]:
    """Retorna (novo_nivel, mudou).

    `pode_mover` carrega o cooldown (resolvido no serviço a partir de
    `nivel_mudou_em_sessao`). Sem janela cheia, não move (histerese).
    """
    if not pode_mover or acuracia is None or amostra < JANELA:
        return nivel_atual, False
    if acuracia >= LIMIAR_SOBE and nivel_atual < NIVEL_MAX:
        return nivel_atual + 1, True
    if acuracia <= LIMIAR_DESCE and nivel_atual > NIVEL_MIN:
        return nivel_atual - 1, True
    return nivel_atual, False
