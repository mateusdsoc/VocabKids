"""Contratos do domínio redação B2C (Fase 4, `docs/plano_b2c.md`).

Os shapes de `Ancora`/`Anotacao`/`Analise`/`PalavraNova` espelham de propósito
os da fatia A mockada (`design/telas.md` §8.1) — a tela do app não muda,
só o backend deixa de devolver dado fixo.
"""
from datetime import date

from pydantic import BaseModel


class RedacaoAtribuicaoOut(BaseModel):
    id: int
    tema: str
    prazo: date | None
    origem: str | None
    redacao_id: int | None
    status: str | None  # nulo = ainda não enviou


class RedacoesOut(BaseModel):
    itens: list[RedacaoAtribuicaoOut]
    extras_restantes_no_mes: int  # R-RD-4


class EnviarRedacaoIn(BaseModel):
    formato: str  # 'manuscrita' | 'digital' — OCR já rodou no app (on-device)
    texto_extraido: str


class EnviarRedacaoOut(BaseModel):
    redacao_id: int
    status: str


class TemaExtraOut(BaseModel):
    atribuicao_id: int
    tema: str


class Ancora(BaseModel):
    inicio: int
    fim: int
    trecho: str
    ocorrencia: int


class Anotacao(BaseModel):
    dimensao: str
    titulo: str
    comentario: str
    sugestoes: list[str] = []
    ancoras: list[Ancora] = []  # vazia = holística → tela renderiza como nota


class Analise(BaseModel):
    versao: int
    dimensoes: list[str]
    pontos_fortes: list[str]
    anotacoes: list[Anotacao]


class PalavraNova(BaseModel):
    palavra: str
    gatilho: str


class AnaliseOut(BaseModel):
    redacao_id: int
    status: str
    texto_extraido: str
    analise: Analise | None
    palavras_novas: list[PalavraNova]
