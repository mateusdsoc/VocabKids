# VocabBR Kids — Backend (FastAPI)

Backend do app, fatia **A** (apresentável) em diante. Stack: **FastAPI + SQLAlchemy Core
+ Alembic + PostgreSQL** (seção 12 do produto / Bloco 3 da arquitetura).

> **Onde roda:** o backend é construído e testado na cloud (Python + Postgres
> disponíveis). O app **Flutter** é autorado no repositório e **rodado em casa** (precisa
> do SDK Flutter + emulador/dispositivo, ausentes no container).

## Estrutura

```
backend/
  app/
    config.py      # settings via env (DATABASE_URL async; deriva a URL síncrona do Alembic)
    db.py          # engine/sessão async (asyncpg)
    schema.py      # Bloco 1 — 25 tabelas (SQLAlchemy Core), fonte única do schema
    main.py        # app FastAPI + /health
  alembic/         # migrations (env.py aponta para app.schema:metadata)
  alembic.ini
  pyproject.toml
  .env.example     # copie para .env
```

Organização por domínio (identidade, vocabulário, sessão…) cresce dentro de `app/`
conforme as rotas/serviços do Bloco 3 forem implementados.

## Rodar localmente

Pré-requisito: um PostgreSQL acessível e a `DATABASE_URL` apontando para ele.

```bash
cd backend
python3 -m venv .venv && . .venv/bin/activate
pip install -e .
cp .env.example .env            # ajuste a DATABASE_URL se necessário

alembic upgrade head            # cria as tabelas do Bloco 1
uvicorn app.main:app --reload   # sobe a API
curl localhost:8000/health      # -> {"status":"ok"}
```

### Subir um Postgres de desenvolvimento (sem Docker)

```bash
PGBIN=$(ls -d /usr/lib/postgresql/*/bin | head -1)
su postgres -c "$PGBIN/initdb -D /tmp/pgdata -U postgres --auth=trust"
su postgres -c "$PGBIN/pg_ctl -D /tmp/pgdata -o '-p 5432 -k /tmp' -l /tmp/pglog.log start"
psql -h localhost -U postgres -c "create database vocabkids;"
```

## Migrations (Alembic)

O schema vive em `app/schema.py` (SQLAlchemy Core). O Alembic autogera a partir dele:

```bash
alembic revision --autogenerate -m "descrição"   # após mudar o schema
alembic upgrade head                              # aplica
alembic downgrade -1                              # reverte uma
```

Decisões relevantes (Bloco 1 / Bloco 3 da arquitetura):
- PK `BIGINT GENERATED ALWAYS AS IDENTITY`; `created_at TIMESTAMPTZ DEFAULT now()`.
- Enums via `VARCHAR + CHECK` (fáceis de evoluir).
- **Schema único**: as tabelas da fatia C (redação, report, telemetria) já existem —
  ficam vazias/mock no apresentável, evitando migração dupla.
