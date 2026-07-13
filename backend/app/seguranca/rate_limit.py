"""Rate limiting em memória — regra pura, sem I/O (testável sem banco/app).

Janela fixa de 60s por chave: simples e O(1) por chamada, suficiente para
frear os abusos mapeados (brute-force de código de turma, criação de contas
em massa, farm de requisições). O estado vive no processo — se a API ganhar
mais de uma réplica, o estado migra para um armazenamento compartilhado
(ex.: Redis) sem mudar a interface daqui.
"""
import time


class LimitadorJanelaFixa:
    """Conta requisições por chave dentro da janela corrente de 60s."""

    JANELA_SEGUNDOS = 60

    def __init__(self) -> None:
        self._contagens: dict[str, int] = {}
        self._janela = -1

    def permitir(self, chave: str, limite: int, agora: float | None = None) -> bool:
        """True se a chave ainda cabe no limite da janela (e consome 1)."""
        agora = time.monotonic() if agora is None else agora
        janela = int(agora // self.JANELA_SEGUNDOS)
        if janela != self._janela:
            # Janela virou: zera tudo de uma vez — poda que impede o dicionário
            # de crescer sem limite com chaves que não voltam mais.
            self._janela = janela
            self._contagens.clear()
        atual = self._contagens.get(chave, 0)
        if atual >= limite:
            return False
        self._contagens[chave] = atual + 1
        return True

    def zerar(self) -> None:
        self._contagens.clear()
        self._janela = -1
