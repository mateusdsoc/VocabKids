"""Fixtures de teste. Usa um Postgres dedicado (vocabkids_test por padrão).

Aponta o `DATABASE_URL` para o banco de teste ANTES de importar o app (a config
é lida na importação). O schema vem do próprio `metadata` (mesma fonte das
migrations), criado uma vez por sessão; cada teste roda em tabelas limpas.
"""
import os

os.environ["DATABASE_URL"] = os.environ.get(
    "TEST_DATABASE_URL", "postgresql+asyncpg://postgres@localhost:5432/vocabkids_test"
)

import pytest  # noqa: E402
import pytest_asyncio  # noqa: E402
from httpx import ASGITransport, AsyncClient  # noqa: E402
from sqlalchemy import create_engine, text  # noqa: E402

from app.config import settings  # noqa: E402
from app.db import engine  # noqa: E402
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
