"""Schemas Pydantic do domínio redação (lado do aluno).

O item da lista é a **atribuição** sob a ótica do aluno: o professor atribui à
turma (`redacao_atribuicao`); `redacao` é o envio deste aluno em resposta —
`null` enquanto não enviou (a tela mostra como "aberta").
"""
from datetime import date, datetime

from pydantic import BaseModel


class EnvioOut(BaseModel):
    redacao_id: int
    # enviada | processando | analisada | erro_ingestao | erro_analise
    # (máquina de estados do pipeline — Bloco 2b; na fatia 1 para em "enviada").
    status: str
    enviada_em: datetime
    paginas: int


class RedacaoAlunoOut(BaseModel):
    atribuicao_id: int
    tema: str
    prazo: date | None
    redacao: EnvioOut | None


class RedacoesAlunoOut(BaseModel):
    itens: list[RedacaoAlunoOut]
