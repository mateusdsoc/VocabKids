"""Contratos de entrada/saída (Pydantic) do domínio vocabulário."""
from pydantic import BaseModel


class PalavraResumoOut(BaseModel):
    id: int
    lema: str
    nivel_dificuldade: int


class PalavraListaOut(BaseModel):
    items: list[PalavraResumoOut]
    next_cursor: str | None  # paginação por cursor (decisão #5); null no fim


class PalavraOut(BaseModel):
    """Conteúdo do card de descoberta (seção 3.2) — sem questões/respostas."""

    id: int
    lema: str
    definicao: str
    exemplo_uso: str
    nivel_dificuldade: int
    audio_url: str | None
    sinonimos: list[str]
