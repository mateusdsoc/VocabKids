"""Contratos da trilha e do passaporte."""
from datetime import datetime

from pydantic import BaseModel


class RecompensaOut(BaseModel):
    tipo: str          # cartao_postal | carimbo | selo
    referencia: str
    asset_ref: str | None


class NoAtualOut(BaseModel):
    destino_id: int
    destino_nome: str
    pais_nome: str
    no_ordem: int           # 1..4 dentro do destino
    xp_inicio: int          # base da barra do nó
    xp_limiar: int          # topo da barra do nó


class DestinoOut(BaseModel):
    id: int
    nome: str
    ordem: int
    nos_total: int
    nos_concluidos: int
    concluido: bool
    atual: bool             # "você está aqui"


class PaisOut(BaseModel):
    id: int
    nome: str
    ordem: int
    concluido: bool
    destinos: list[DestinoOut]


class TrilhaOut(BaseModel):
    xp_total: int
    no_atual: NoAtualOut | None   # null quando a trilha inteira foi concluída
    paises: list[PaisOut]


class ItemPassaporteOut(BaseModel):
    id: int
    tipo: str
    referencia: str
    asset_ref: str | None
    conquistado: bool
    ganho_em: datetime | None


class PassaporteOut(BaseModel):
    total: int
    conquistados: int
    itens: list[ItemPassaporteOut]
