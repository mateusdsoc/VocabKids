"""Contratos de entrada/saída (Pydantic) do domínio identidade.

B2C (docs/plano_b2c.md Fase 1): entrada por `codigo_turma` deu lugar a conta
do responsável (e-mail/senha) + perfis de criança. `turma`/`escola` saíram
destes contratos — quem ainda precisa deles é o domínio `professor` (fatia
B2B congelada), que tem os próprios schemas.
"""
from datetime import datetime, timezone

from pydantic import BaseModel, EmailStr, Field, field_validator

CONSENTIMENTO_VERSAO_ATUAL = "1.0"  # bump ao mudar o termo — força novo aceite

# Janela de idade aceita no cadastro (produto mira 7-12, com folga nas pontas
# para não travar quem está bem na borda). Calculada contra o ano corrente —
# nunca hardcoded, ou vira bug de calendário em poucos anos (visto em revisão).
_IDADE_MIN = 5
_IDADE_MAX = 14


class CadastroResponsavelIn(BaseModel):
    nome: str = Field(min_length=1, max_length=120)
    email: EmailStr
    senha: str = Field(min_length=8, max_length=128)
    aceite_termos: bool
    consentimento_lgpd: bool = Field(
        description="Consentimento específico e destacado para tratar dados da "
        "criança (LGPD art. 14 §1) — distinto do aceite genérico dos termos."
    )


class LoginIn(BaseModel):
    email: EmailStr
    senha: str = Field(min_length=1, max_length=128)


class ExcluirContaIn(BaseModel):
    senha: str = Field(min_length=1, max_length=128, description="Reconfirmação de senha.")


class PerfilCriancaIn(BaseModel):
    apelido: str = Field(min_length=1, max_length=60, description="Nunca o nome completo.")
    ano_nascimento: int

    @field_validator("ano_nascimento")
    @classmethod
    def _idade_dentro_da_janela(cls, v: int) -> int:
        ano_atual = datetime.now(timezone.utc).year
        if not (ano_atual - _IDADE_MAX <= v <= ano_atual - _IDADE_MIN):
            raise ValueError(f"ano_nascimento deve corresponder a {_IDADE_MIN}-{_IDADE_MAX} anos")
        return v


class PerfilCriancaOut(BaseModel):
    usuario_id: int
    apelido: str
    faixa_etaria: str
    ano_escolar: int | None


class ContaOut(BaseModel):
    conta_id: int
    nome_responsavel: str
    email: str
    perfis: list[PerfilCriancaOut]


class TokenOut(BaseModel):
    token: str


class ProgressoOut(BaseModel):
    xp_total: int
    no_atual_id: int | None
    palavras_dominadas: int
    nivel_dificuldade_atual: int


class MetaSemanalOut(BaseModel):
    """Meta da semana (§3.5): dominadas desde segunda-feira sobre o alvo da
    faixa etária (B2C — não há mais professor configurando)."""

    atual: int
    alvo: int


class MeOut(BaseModel):
    usuario_id: int
    nome: str
    papel: str
    perfil: PerfilCriancaOut | None
    progresso: ProgressoOut
    meta_semanal: MetaSemanalOut | None  # nulo se, por algum motivo, sem perfil
