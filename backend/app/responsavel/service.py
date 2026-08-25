"""Orquestração da Área do Responsável (Fase 5, `docs/plano_b2c.md` §08).

R-RS-1: o PIN é o portão ANTES de qualquer dado ou link externo. Aqui isso
significa: o backend valida o PIN contra o hash (nunca em texto puro, nunca no
cliente) e devolve ok/erro; é o APP quem só deixa entrar na Área do
Responsável depois de um `verificar_pin` bem-sucedido — mesmo padrão já usado
pelo paywall (Fase 3): o portão é de navegação no app, a fonte da verdade do
segredo é o backend. Reaproveita o hasher argon2 de `identidade/service.py`
(mesmo algoritmo, chave de domínio diferente — não dá pra reusar a função
porque ela guarda em `usuario.senha_hash`, não em `conta.pin_hash`).

R-RS-2/R-RS-3: nunca taxa de acerto, tempo/velocidade por questão nem
comparação entre crianças — só o que já está listado em §08.
"""
from datetime import datetime, timezone

from argon2 import PasswordHasher
from argon2.exceptions import VerifyMismatchError
from sqlalchemy.ext.asyncio import AsyncConnection

from app.errors import ApiError
from app.identidade import repository as identidade_repo
from app.progressao.faixa import meta_semanal_default
from app.progressao.semana import inicio_da_semana
from app.redacao import repository as redacao_repo
from app.responsavel import repository as repo

_hasher = PasswordHasher()


def _hash_pin(pin: str) -> str:
    return _hasher.hash(pin)


def _pin_confere(pin: str, pin_hash: str) -> bool:
    try:
        _hasher.verify(pin_hash, pin)
        return True
    except VerifyMismatchError:
        return False


async def definir_pin(conn: AsyncConnection, conta_id: int, pin: str) -> None:
    await repo.definir_pin_hash(conn, conta_id, _hash_pin(pin))


async def pin_status(conn: AsyncConnection, conta_id: int) -> dict:
    pin_hash = await repo.buscar_pin_hash(conn, conta_id)
    return {"definido": pin_hash is not None}


async def verificar_pin(conn: AsyncConnection, conta_id: int, pin: str) -> None:
    pin_hash = await repo.buscar_pin_hash(conn, conta_id)
    if pin_hash is None or not _pin_confere(pin, pin_hash):
        raise ApiError(401, "pin_invalido", "PIN incorreto.")


async def _validar_perfil_da_conta(conn: AsyncConnection, conta_id: int, perfil_usuario_id: int):
    pertence = await identidade_repo.buscar_perfil_na_conta(conn, conta_id, perfil_usuario_id)
    if pertence is None:
        raise ApiError(404, "perfil_nao_encontrado", "Perfil não pertence a esta conta.")


async def resumo_semanal(conn: AsyncConnection, *, conta_id: int, perfil_usuario_id: int) -> dict:
    await _validar_perfil_da_conta(conn, conta_id, perfil_usuario_id)

    perfil = await identidade_repo.buscar_perfil(conn, perfil_usuario_id)
    if perfil is None:
        raise ApiError(404, "perfil_nao_encontrado", "Perfil não encontrado.")

    inicio = inicio_da_semana()
    dominadas = await identidade_repo.dominadas_na_semana(conn, perfil_usuario_id, inicio)
    sessoes, minutos = await repo.sessoes_e_minutos_da_semana(conn, perfil_usuario_id, inicio)
    aprendidas = await repo.palavras_aprendidas_na_semana(conn, perfil_usuario_id, inicio)
    historico = await redacao_repo.historico_analises(conn, perfil_usuario_id)

    return {
        "perfil_usuario_id": perfil_usuario_id,
        "apelido": perfil.apelido,
        "palavras_dominadas": {"atual": dominadas, "alvo": meta_semanal_default(perfil.faixa_etaria)},
        "minutos_na_semana": minutos,
        "sessoes_na_semana": sessoes,
        "aprendeu_essa_semana": [
            {"palavra": linha.lema, "definicao": linha.definicao} for linha in aprendidas
        ],
        "evolucao_redacao": [
            {
                "redacao_id": linha.redacao_id,
                "analisada_em": linha.analisada_em,
                "niveis": linha.anotacoes.get("niveis_dimensao", {}),
            }
            for linha in historico
        ],
    }
