"""Contratos do diagnóstico inicial (onboarding).

`EstadoDiagnostico` é o estado da escada **carregado pelo cliente** (stateless no
servidor): o app reenvia o `estado` recebido a cada passo. É aceitável porque o
diagnóstico não é sensível a trapaça — só define o nível INICIAL, que a adaptação
contínua corrige (filosofia "diagnóstico leve + adaptação forte", Bloco 2a).
"""
from typing import Literal

from pydantic import BaseModel


class EstadoDiagnostico(BaseModel):
    fase: Literal["grossa", "fina", "confirmacao"]
    nivel: int
    passo: int
    teto: int | None = None
    ceiling_candidato: int | None = None
    confirma_acertos: int = 0
    confirma_feitas: int = 0
    ultimo_passou: int | None = None
    perguntas: int = 0
    usadas: list[int] = []
    questao_atual: int | None = None
    # Orçamento de perguntas por faixa etária (B2C, docs/plano_b2c.md Fase 2,
    # §5.1) — 7-8 anos aguenta menos perguntas seguidas que 11-12. Carregado
    # pelo cliente como o resto do estado; default = teto antigo (15), só usado
    # se um estado sem o campo chegar de um cliente desatualizado.
    max_perguntas: int = 15


class QuestaoDiagnostico(BaseModel):
    questao_id: int
    enunciado: str
    opcoes: list[str]  # embaralhadas; sem indicar a correta


class DiagnosticoIn(BaseModel):
    # estado=None inicia; com estado, é uma resposta a avançar.
    estado: EstadoDiagnostico | None = None
    questao_id: int | None = None
    opcao: str | None = None


class DiagnosticoOut(BaseModel):
    concluido: bool
    perguntas: int
    max_perguntas: int
    questao: QuestaoDiagnostico | None = None
    estado: EstadoDiagnostico | None = None
    nivel_dificuldade_atual: int | None = None  # preenchido quando concluido
