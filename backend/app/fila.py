"""Fila de tarefas (procrastinate) — jobs no próprio Postgres (produto §12).

Sem Redis, sem serviço novo: a fila vive no mesmo banco do app. O pipeline de
redação (Bloco 2b) roda aqui, fora do caminho síncrono da API — a request só
ENFILEIRA (defer); quem executa é o **worker**, um processo separado da mesma
codebase:

    cd backend && uv run procrastinate --app=app.fila.fila worker

As tabelas `procrastinate_*` entram por migration Alembic (cadeia única) e o
autogenerate as ignora (filtro em alembic/env.py). Nos testes o conector é
trocado por um em memória (`tests/conftest.py`) — sem tabelas, sem worker
externo.
"""
import procrastinate

from app.config import settings


def _conninfo() -> str:
    """A fila fala psycopg puro; a URL async do app vira conninfo padrão."""
    return settings.database_url.replace("+asyncpg", "")


fila = procrastinate.App(
    connector=procrastinate.PsycopgConnector(conninfo=_conninfo()),
    # Onde o worker encontra as tasks registradas (a API as importa direto).
    import_paths=["app.redacao.tarefas"],
)
