"""Miolos do pipeline de redação (Bloco 2b) — cada etapa como função sem fila.

Fatia 2: os miolos são **stubs declarados** — devolvem `None` ("etapa ainda não
implementada") para a máquina de estados e o encadeamento serem reais desde já,
sem inventar resultado. Com o miolo em stub o pipeline para em `processando`
(honesto: a tela mostra "em análise"). As fatias seguintes trocam só o miolo:

- fatia 3 → `extrair_texto` (extração de PDF; OCR de manuscrita via Vision);
- fatia 4 → `analisar` (LLM multidimensional atrás de interface);
- fatia 5 → `extrair_palavras` (Hunspell/spaCy + buscar_ou_gerar + atribuição).

As tarefas da fila (`tarefas.py`) chamam estas funções — trocar o miolo não
muda a orquestração nem os testes de estado.

Contrato de erro: exceção PERMANENTE (o problema é da redação — foto ilegível,
PDF vazio) é sinalizada com `ErroIngestao`/`ErroAnalise` e vira `status
erro_*`; qualquer outra exceção é tratada como TRANSITÓRIA (infra) e a fila
faz retry com backoff.
"""


class ErroIngestao(Exception):
    """Falha permanente de ingestão (ex.: arquivo ilegível) → `erro_ingestao`."""


class ErroAnalise(Exception):
    """Falha permanente de análise → `erro_analise`."""


async def extrair_texto(formato: str, paginas: list[bytes]) -> str | None:
    """OCR (manuscrita) / extração de PDF (digital) → `texto_extraido` (§4.7).

    STUB da fatia 2: `None` = ainda não implementado.
    """
    return None


async def analisar(texto: str) -> dict | None:
    """LLM multidimensional → anotações por dimensão (JSONB, §4.2).

    STUB da fatia 2 (miolo real na fatia 4): `None` = ainda não implementado.
    """
    return None


async def extrair_palavras(anotacoes: dict) -> list[dict]:
    """Candidatas fraca|superutilizada validadas (Hunspell) e lematizadas
    (spaCy) a partir da dimensão de vocabulário (§3.6/4.5).

    STUB da fatia 2 (miolo real na fatia 5): lista vazia = nada a atribuir —
    a tarefa finaliza a redação como `analisada` mesmo assim (a análise em si
    já existe; palavras são o elo com a trilha, não pré-requisito do status).
    """
    return []
