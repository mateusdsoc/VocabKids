"""Contratos do domínio responsável (Fase 5, `docs/plano_b2c.md` §08)."""
from datetime import datetime

from pydantic import BaseModel, Field


class PinIn(BaseModel):
    pin: str = Field(min_length=4, max_length=4, pattern=r"^\d{4}$")


class PinStatusOut(BaseModel):
    definido: bool


class MetaSemanalOut(BaseModel):
    atual: int
    alvo: int


class PalavraAprendidaOut(BaseModel):
    palavra: str
    definicao: str


class NivelDimensaoOut(BaseModel):
    redacao_id: int
    analisada_em: datetime | None
    niveis: dict[str, str]  # dimensão → 'começando'|'avançando'|'consolidando'|'dominando'


class ResumoSemanalOut(BaseModel):
    perfil_usuario_id: int
    apelido: str
    palavras_dominadas: MetaSemanalOut
    minutos_na_semana: int
    sessoes_na_semana: int
    aprendeu_essa_semana: list[PalavraAprendidaOut]
    evolucao_redacao: list[NivelDimensaoOut]
