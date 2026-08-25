"""Lógica de domínio do identidade — sem SQL cru nem detalhe de HTTP.

B2C (docs/plano_b2c.md Fase 1): substitui o acesso por código de turma por
conta do responsável (e-mail/senha) + perfis de criança. Criança nunca tem
credencial própria (R-ID-2) — o token dela é emitido a partir do token do
responsável, depois de confirmar que o perfil pertence à conta (R-ID-3).
"""
from datetime import datetime, timezone

from argon2 import PasswordHasher
from argon2.exceptions import VerifyMismatchError
from sqlalchemy.ext.asyncio import AsyncConnection

from app.errors import ApiError
from app.identidade import repository as repo
from app.identidade.auth import criar_token
from app.identidade.schemas import CONSENTIMENTO_VERSAO_ATUAL
from app.progressao.faixa import faixa_de, meta_semanal_default
from app.progressao.semana import inicio_da_semana

_hasher = PasswordHasher()

LIMITE_PERFIS_POR_CONTA = 3  # D4 do plano: até 3 crianças no mesmo preço


def _hash_senha(senha: str) -> str:
    return _hasher.hash(senha)


def _senha_confere(senha: str, senha_hash: str) -> bool:
    try:
        _hasher.verify(senha_hash, senha)
        return True
    except VerifyMismatchError:
        return False


async def cadastrar_responsavel(
    conn: AsyncConnection, *, nome: str, email: str, senha: str
) -> dict:
    """Cria a conta do responsável. `aceite_termos`/`consentimento_lgpd` já
    foram validados como `True` pelo Pydantic antes de chegar aqui (R-LG-1:
    o consentimento é sempre explícito, nunca implícito)."""
    existente = await repo.buscar_usuario_por_email(conn, email)
    if existente is not None:
        raise ApiError(409, "email_em_uso", "Já existe uma conta com este e-mail.")

    usuario_id, _conta_id = await repo.criar_conta_responsavel(
        conn,
        nome=nome.strip(),
        email=email.strip().lower(),
        senha_hash=_hash_senha(senha),
        consentimento_versao=CONSENTIMENTO_VERSAO_ATUAL,
    )
    return {"token": criar_token(usuario_id, "responsavel")}


async def login(conn: AsyncConnection, *, email: str, senha: str) -> dict:
    row = await repo.buscar_usuario_por_email(conn, email)
    if row is None or row.senha_hash is None or not _senha_confere(senha, row.senha_hash):
        raise ApiError(401, "credenciais_invalidas", "E-mail ou senha incorretos.")
    return {"token": criar_token(row.id, "responsavel")}


async def excluir_conta(conn: AsyncConnection, *, usuario_id: int, senha: str) -> None:
    """R-ID-6: exclusão exige reconfirmação de senha — evita que um token
    roubado apague a conta sem o responsável presente."""
    senha_hash = await repo.buscar_senha_hash(conn, usuario_id)
    if senha_hash is None or not _senha_confere(senha, senha_hash):
        raise ApiError(401, "credenciais_invalidas", "Senha incorreta.")
    await repo.excluir_conta_e_perfis(conn, usuario_id)


async def _conta_do_responsavel(conn: AsyncConnection, usuario_id: int) -> int:
    conta = await repo.buscar_conta_por_responsavel(conn, usuario_id)
    if conta is None:
        raise ApiError(404, "conta_nao_encontrada", "Conta não encontrada.")
    return conta.id


async def conta(conn: AsyncConnection, responsavel_usuario_id: int) -> dict:
    c = await repo.buscar_conta_completa(conn, responsavel_usuario_id)
    if c is None:
        raise ApiError(404, "conta_nao_encontrada", "Conta não encontrada.")
    perfis = await repo.listar_perfis_da_conta(conn, c.id)
    return {
        "conta_id": c.id,
        "nome_responsavel": c.nome,
        "email": c.email,
        "perfis": [
            {
                "usuario_id": p.usuario_id,
                "apelido": p.apelido,
                "faixa_etaria": p.faixa_etaria,
                "ano_escolar": p.ano_escolar,
            }
            for p in perfis
        ],
    }


async def listar_perfis(conn: AsyncConnection, responsavel_usuario_id: int) -> list[dict]:
    conta_id = await _conta_do_responsavel(conn, responsavel_usuario_id)
    perfis = await repo.listar_perfis_da_conta(conn, conta_id)
    return [
        {
            "usuario_id": p.usuario_id,
            "apelido": p.apelido,
            "faixa_etaria": p.faixa_etaria,
            "ano_escolar": p.ano_escolar,
        }
        for p in perfis
    ]


async def criar_perfil_crianca(
    conn: AsyncConnection, *, responsavel_usuario_id: int, apelido: str, ano_nascimento: int
) -> dict:
    conta_id = await _conta_do_responsavel(conn, responsavel_usuario_id)
    if await repo.contar_perfis_da_conta(conn, conta_id) >= LIMITE_PERFIS_POR_CONTA:
        raise ApiError(
            422,
            "limite_de_perfis",
            f"Cada conta pode ter até {LIMITE_PERFIS_POR_CONTA} perfis de criança.",
        )
    ano_atual = datetime.now(timezone.utc).year
    faixa_etaria = faixa_de(ano_nascimento, ano_atual)
    usuario_id = await repo.criar_perfil_crianca(
        conn,
        conta_id=conta_id,
        apelido=apelido.strip(),
        ano_nascimento=ano_nascimento,
        faixa_etaria=faixa_etaria,
    )
    return {
        "usuario_id": usuario_id,
        "apelido": apelido.strip(),
        "faixa_etaria": faixa_etaria,
        "ano_escolar": None,
    }


async def entrar_como_crianca(
    conn: AsyncConnection, *, responsavel_usuario_id: int, perfil_usuario_id: int
) -> dict:
    """Emite o token de gameplay (papel='aluno') para um perfil da própria
    conta. R-ID-3: um token de responsável nunca abre sessão de jogo
    diretamente — precisa passar por aqui, e só para os próprios filhos."""
    conta_id = await _conta_do_responsavel(conn, responsavel_usuario_id)
    perfil = await repo.buscar_perfil_na_conta(conn, conta_id, perfil_usuario_id)
    if perfil is None:
        raise ApiError(
            404, "perfil_nao_encontrado", "Perfil não encontrado nesta conta."
        )
    return {"token": criar_token(perfil_usuario_id, "aluno")}


async def perfil(conn: AsyncConnection, usuario_id: int) -> dict:
    """Perfil + progresso da criança (`GET /v1/me`)."""
    p = await repo.buscar_perfil(conn, usuario_id)
    if p is None:
        raise ApiError(404, "usuario_nao_encontrado", "Usuário não encontrado.")

    prog = await repo.buscar_progresso(conn, usuario_id)
    progresso = {
        "xp_total": prog.xp_total if prog else 0,
        "no_atual_id": prog.no_atual_id if prog else None,
        "palavras_dominadas": prog.palavras_dominadas if prog else 0,
        "nivel_dificuldade_atual": prog.nivel_dificuldade_atual if prog else 1,
    }

    perfil_out = None
    meta_semanal = None
    if p.faixa_etaria:
        perfil_out = {
            "usuario_id": p.usuario_id,
            "apelido": p.apelido,
            "faixa_etaria": p.faixa_etaria,
            "ano_escolar": p.ano_escolar,
        }
        atual = await repo.dominadas_na_semana(conn, usuario_id, inicio_da_semana())
        meta_semanal = {"atual": atual, "alvo": meta_semanal_default(p.faixa_etaria)}

    return {
        "usuario_id": p.usuario_id,
        "nome": p.nome,
        "papel": p.papel,
        "perfil": perfil_out,
        "progresso": progresso,
        "meta_semanal": meta_semanal,
    }
