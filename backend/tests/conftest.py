"""Fixtures de teste. Usa um Postgres dedicado (vocabkids_test por padrão).

Aponta o `DATABASE_URL` para o banco de teste ANTES de importar o app (a config
é lida na importação). O schema vem do próprio `metadata` (mesma fonte das
migrations), criado uma vez por sessão; cada teste roda em tabelas limpas.
"""
import os

os.environ["DATABASE_URL"] = os.environ.get(
    "TEST_DATABASE_URL", "postgresql+asyncpg://postgres@localhost:5432/vocabkids_test"
)
# Auth JWT: segredo fixo de teste (a suíte não depende de .env).
os.environ["JWT_SECRET"] = "segredo-de-teste-nao-usar-fora-da-suite"
# Rate limit desligado por padrão (a suíte compartilha um "IP" só — httpx ASGI);
# o middleware é exercitado por teste próprio com limites baixos via monkeypatch.
os.environ["RATE_LIMIT_HABILITADO"] = "false"
# CORS ligado com uma origem de teste (o middleware só é montado se houver origem).
os.environ["CORS_ORIGINS"] = "http://cors-permitido.test"

import pytest  # noqa: E402
import pytest_asyncio  # noqa: E402
from httpx import ASGITransport, AsyncClient  # noqa: E402
from procrastinate import testing as procrastinate_testing  # noqa: E402
from sqlalchemy import create_engine, text  # noqa: E402

from app.config import settings  # noqa: E402
from app.db import engine  # noqa: E402
from app.fila import fila  # noqa: E402
from app.main import app  # noqa: E402
from app.schema import metadata  # noqa: E402


@pytest.fixture(scope="session", autouse=True)
def _schema():
    sync = create_engine(settings.sync_database_url)
    metadata.drop_all(sync)
    metadata.create_all(sync)
    yield
    metadata.drop_all(sync)
    sync.dispose()


@pytest.fixture(autouse=True)
def _tabelas_limpas():
    sync = create_engine(settings.sync_database_url)
    nomes = ", ".join(t.name for t in metadata.sorted_tables)
    with sync.begin() as conn:
        conn.execute(text(f"TRUNCATE {nomes} RESTART IDENTITY CASCADE"))
    sync.dispose()
    yield


@pytest.fixture(autouse=True)
def storage_dir(tmp_path, monkeypatch):
    """Storage local de redações num diretório temporário por teste — asserts
    de arquivo olham o disco de verdade sem sujar o repositório."""
    monkeypatch.setattr(settings, "redacoes_dir", str(tmp_path))
    return tmp_path


@pytest.fixture(autouse=True)
def fila_em_memoria():
    """Fila com conector em memória: o defer das rotas funciona sem as tabelas
    `procrastinate_*` (os testes criam o schema via metadata, não via Alembic)
    e sem worker externo. Testes do pipeline inspecionam `.jobs` e rodam o
    worker inline (`fila.run_worker_async(wait=False, ...)`)."""
    conector = procrastinate_testing.InMemoryConnector()
    with fila.replace_connector(conector):
        yield conector


@pytest_asyncio.fixture
async def client():
    # asyncpg prende conexões ao event loop; cada teste tem o seu. Soltar o pool
    # antes/depois garante que as conexões nasçam no loop corrente.
    await engine.dispose()
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as c:
        yield c
    await engine.dispose()


@pytest_asyncio.fixture
async def aluno(client):
    """Semeia a turma de demo, entra como aluno e devolve headers + usuario_id."""
    from app.seed import seed

    s = await seed()
    r = await client.post(
        "/v1/acesso/turma", json={"codigo_turma": s["codigo_turma"], "nome": "Ana"}
    )
    b = r.json()
    return {
        "headers": {"Authorization": f"Bearer {b['token']}"},
        "usuario_id": b["usuario_id"],
    }


@pytest_asyncio.fixture
async def auth_headers(aluno):
    return aluno["headers"]


@pytest_asyncio.fixture
async def professor(client):
    """Professora do seed — JWT com papel professor (não há login de professor)."""
    from app.identidade.auth import criar_token
    from app.seed import seed

    s = await seed()
    token = criar_token(s["professor_id"], "professor")
    return {
        "headers": {"Authorization": f"Bearer {token}"},
        "usuario_id": s["professor_id"],
    }


@pytest_asyncio.fixture
async def coordenador(client):
    """Coordenador criado direto no banco (papel só-leitura, §3.11)."""
    from sqlalchemy import insert

    from app import schema
    from app.identidade.auth import criar_token
    from app.seed import seed

    s = await seed()
    async with engine.begin() as conn:
        usuario_id = (
            await conn.execute(
                insert(schema.usuario)
                .values(nome="Coordenador Teste")
                .returning(schema.usuario.c.id)
            )
        ).scalar_one()
        await conn.execute(
            insert(schema.associacao).values(
                usuario_id=usuario_id, escola_id=s["escola_id"], papel="coordenador"
            )
        )
    token = criar_token(usuario_id, "coordenador")
    return {
        "headers": {"Authorization": f"Bearer {token}"},
        "usuario_id": usuario_id,
    }
