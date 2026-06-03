"""Contratos de entrada/saída (Pydantic) do domínio identidade."""
from pydantic import BaseModel, Field


class AcessoTurmaIn(BaseModel):
    codigo_turma: str = Field(
        min_length=1, max_length=64, description="Código provisório da turma."
    )
    nome: str = Field(min_length=1, max_length=120, description="Nome do aluno.")


class TurmaOut(BaseModel):
    id: int
    nome: str
    ano_escolar: int


class EscolaOut(BaseModel):
    id: int
    nome: str


class AcessoTurmaOut(BaseModel):
    token: str
    usuario_id: int
    nome: str
    turma: TurmaOut
    novo: bool = Field(description="True se o aluno foi criado agora; False se já existia.")


class ProgressoOut(BaseModel):
    xp_total: int
    no_atual_id: int | None
    palavras_dominadas: int
    nivel_dificuldade_atual: int


class MeOut(BaseModel):
    usuario_id: int
    nome: str
    papel: str
    escola: EscolaOut | None
    turma: TurmaOut | None
    progresso: ProgressoOut
