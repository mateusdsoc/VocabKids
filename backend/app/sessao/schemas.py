"""Contratos de saída do domínio sessão.

A fila vai em **lote** (entrega híbrida, Bloco 3 decisão #3): o app renderiza
tudo e faz prefetch. As questões **nunca** carregam a resposta correta — só o
enunciado e as opções (embaralhadas server-side). A correção é server-side, por
resposta (próxima fatia).
"""
from typing import Annotated, Literal, Union

from pydantic import BaseModel, Field


class CardPalavra(BaseModel):
    id: int
    lema: str
    definicao: str
    exemplo_uso: str
    audio_url: str | None
    sinonimos: list[str]
    palavra_gatilho: str | None  # só origem pessoal (fatia C); null no banco base


class CardSlot(BaseModel):
    tipo: Literal["card"] = "card"
    palavra: CardPalavra


class QuestaoSlot(BaseModel):
    tipo: Literal["questao"] = "questao"
    questao_id: int
    palavra_id: int
    nivel: int
    is_revisao: bool
    enunciado: str
    opcoes: list[str]  # embaralhadas; sem indicação da correta


Slot = Annotated[Union[CardSlot, QuestaoSlot], Field(discriminator="tipo")]


class SessaoOut(BaseModel):
    sessao_id: int
    slots: list[Slot]
