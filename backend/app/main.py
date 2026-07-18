"""App FastAPI — ponto de entrada.

As rotas de domínio (identidade, sessão, trilha…) entram via `api_router`. O
trabalho pesado (pipeline de redação, Bloco 2b) NÃO roda aqui: a API só
enfileira; o worker (`procrastinate ... worker`) executa em processo próprio.
"""
import hashlib
from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from sqlalchemy import text
from starlette.requests import Request

from app.api.v1 import api_router
from app.config import settings
from app.db import engine
from app.errors import register_error_handlers
from app.fila import fila
from app.seguranca.rate_limit import LimitadorJanelaFixa


@asynccontextmanager
async def _ciclo_de_vida(_: FastAPI):
    # Conector da fila aberto pelo processo (pool psycopg próprio, fora da
    # transação por request) — necessário para o defer das rotas de envio.
    async with fila.open_async():
        yield


app = FastAPI(title="VocabBR Kids API", version="0.1.0", lifespan=_ciclo_de_vida)
register_error_handlers(app)
app.include_router(api_router)

limitador = LimitadorJanelaFixa()


@app.middleware("http")
async def db_transacao(request: Request, call_next):
    """Transação por request, commitada ANTES de a resposta sair.

    Centraliza o ciclo de vida da conexão (lida pelos handlers via `get_conn`):
    commit no sucesso (status < 400), rollback em erro. Evita a corrida do
    teardown de dependência `yield`, que comita depois da resposta.
    """
    async with engine.connect() as conn:
        # request.state é lastreado no `scope` (Starlette), então a conexão é
        # visível ao handler via get_conn mesmo cruzando o BaseHTTPMiddleware.
        request.state.conn = conn
        transacao = await conn.begin()
        try:
            response = await call_next(request)
        except Exception:
            await transacao.rollback()
            raise
        if response.status_code < 400:
            await transacao.commit()
        else:
            await transacao.rollback()
        return response


def _ip_cliente(request: Request) -> str:
    # Atrás de um reverse-proxy, rodar o uvicorn com --proxy-headers (e
    # --forwarded-allow-ips) para que request.client seja o IP real do cliente.
    return request.client.host if request.client else "desconhecido"


@app.middleware("http")
async def rate_limit(request: Request, call_next):
    """Freio de abuso por janela de 60s (fora da transação de banco: request
    bloqueado nem abre conexão).

    Chaves: o login (`/acesso/turma`) conta por IP com limite próprio — é a
    porta de brute-force de código de turma e de criação de contas. Rotas
    autenticadas contam por token (não por IP: uma turma inteira compartilha o
    NAT da escola). O resto conta por IP.
    """
    if not settings.rate_limit_habilitado or request.method == "OPTIONS":
        return await call_next(request)

    autorizacao = request.headers.get("authorization")
    if request.url.path.endswith("/acesso/turma"):
        chave = f"login:{_ip_cliente(request)}"
        limite = settings.rl_login_por_minuto
    elif autorizacao:
        # Hash do token como chave: não reter credenciais em memória.
        sufixo = hashlib.sha256(autorizacao.encode()).hexdigest()[:16]
        chave = f"token:{sufixo}"
        limite = settings.rl_autenticado_por_minuto
    else:
        chave = f"anonimo:{_ip_cliente(request)}"
        limite = settings.rl_anonimo_por_minuto

    if not limitador.permitir(chave, limite):
        return JSONResponse(
            status_code=429,
            content={
                "error": {
                    "code": "limite_excedido",
                    "message": "Muitas requisições. Tente de novo em instantes.",
                    "details": {},
                }
            },
            headers={"Retry-After": str(LimitadorJanelaFixa.JANELA_SEGUNDOS)},
        )
    return await call_next(request)


# CORS por último = camada mais externa: o preflight é respondido aqui e não
# atravessa rate limit nem transação de banco. Origens explícitas via env
# (CORS_ORIGINS) — nunca "*". Sem origens configuradas, nada é permitido.
if settings.cors_origins_list:
    app.add_middleware(
        CORSMiddleware,
        allow_origins=settings.cors_origins_list,
        allow_methods=["GET", "POST", "PUT"],
        allow_headers=["Authorization", "Content-Type"],
        max_age=3600,  # cacheia o preflight no browser — menos ida-e-volta
    )


@app.get("/health")
async def health(request: Request):
    """Liveness + checagem de conexão com o banco."""
    await request.state.conn.execute(text("SELECT 1"))
    return {"status": "ok"}
