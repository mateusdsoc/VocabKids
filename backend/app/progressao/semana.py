"""Semana letiva — regra pura, sem I/O.

A "semana" da meta (§3.5) começa na **segunda-feira à meia-noite** no fuso das
escolas (America/Sao_Paulo — produto BR). Todo agregado "nesta semana" (meta
do aluno na Home, resumo semanal do responsável) usa este corte.
"""
from datetime import datetime, timedelta
from zoneinfo import ZoneInfo

FUSO_ESCOLA = ZoneInfo("America/Sao_Paulo")


def inicio_da_semana(agora: datetime | None = None) -> datetime:
    """Segunda-feira 00:00 (fuso da escola) da semana de `agora` (tz-aware)."""
    agora = agora if agora is not None else datetime.now(FUSO_ESCOLA)
    local = agora.astimezone(FUSO_ESCOLA)
    segunda = local - timedelta(days=local.weekday())
    return segunda.replace(hour=0, minute=0, second=0, microsecond=0)
