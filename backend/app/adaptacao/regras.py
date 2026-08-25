"""Adaptação contínua de nível — decisão pura (Bloco 2a).

Roda ao fim de cada sessão. O **sinal limpo** é a acurácia de 1ª tentativa nas
questões de palavras do nível atual (janela móvel ~10); revisão é excluída para
não inflar o número (aproximada aqui pelo filtro de nível — ver `service`).

    ≥ 90% → sobe um nível (acelera)
    ≤ 50% → desce um nível (recupera placement alto demais)
    entre → mantém

Histerese: só move com a **janela cheia**; um nível por vez; **cooldown** de 1
sessão após mover. Limiares/janela/cooldown são configuráveis (telemetria calibra).

Tolerância de nível (`NIVEL_TOLERANCIA_SINAL`): quando o banco não tem palavras
no nível exato, a seleção puxa vizinhos (`selecionar_palavras_novas` ordena por
distância). Sem isso, a janela do sinal — que filtra pelo nível — ficaria vazia
e a adaptação nunca dispararia (fome de janela). A janela conta o nível ±N para
acompanhar a mesma banda que a seleção usa.

B2C (docs/plano_b2c.md Fase 2, R-FX-1): a adaptação sobe DENTRO da faixa etária
da criança, nunca extrapola para cima — `nivel_max` vem de
`progressao/faixa.nivel_maximo(faixa_etaria)`, não mais só do teto global 10
(que continua sendo o default para quem não tem perfil de criança — ex.: aluno
B2B congelado, sem `perfil_crianca`).
"""
JANELA = 10
LIMIAR_SOBE = 0.90
LIMIAR_DESCE = 0.50
COOLDOWN_SESSOES = 1
NIVEL_MIN = 1
NIVEL_MAX = 10
NIVEL_TOLERANCIA_SINAL = 1  # conta o nível ±1 no sinal (banco esparso → vizinhos)


def decidir(
    *,
    acuracia: float | None,
    amostra: int,
    nivel_atual: int,
    pode_mover: bool,
    nivel_max: int = NIVEL_MAX,
) -> tuple[int, bool]:
    """Retorna (novo_nivel, mudou).

    `pode_mover` carrega o cooldown (resolvido no serviço a partir de
    `nivel_mudou_em_sessao`). Sem janela cheia, não move (histerese).
    `nivel_max` é o teto da faixa etária (R-FX-1) — nunca sobe além dele.
    """
    if not pode_mover or acuracia is None or amostra < JANELA:
        return nivel_atual, False
    if acuracia >= LIMIAR_SOBE and nivel_atual < nivel_max:
        return nivel_atual + 1, True
    if acuracia <= LIMIAR_DESCE and nivel_atual > NIVEL_MIN:
        return nivel_atual - 1, True
    return nivel_atual, False
