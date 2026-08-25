"""Contratos do domínio assinatura (B2C, docs/plano_b2c.md Fase 3)."""
from datetime import datetime

from pydantic import BaseModel


class AssinaturaStatusOut(BaseModel):
    assinante: bool  # True = acesso liberado (ativa ou em período de graça)
    status: str | None  # nulo = nunca assinou (pode estar no free tier)
    expira_em: datetime | None
    em_trial: bool
    em_free_tier: bool  # ainda dentro do 1º destino, sem precisar assinar
