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
    config.py        # settings via env (DATABASE_URL async; deriva a URL síncrona do Alembic)
    db.py            # engine/sessão async (asyncpg)
    schema.py        # Bloco 1 — 25 tabelas (SQLAlchemy Core), fonte única do schema
    errors.py        # convenção de erro única (Bloco 3, decisão #5)
    seed.py          # seed mínimo da fatia A (escola + turma); `python -m app.seed`
    main.py          # app FastAPI: /health + handlers de erro + router /v1
    api/
      deps.py        # dependências compartilhadas (conexão transacional por request)
      v1.py          # agregador das rotas sob /v1
    identidade/      # domínio: acesso por código de turma, /me (camadas abaixo)
      routes.py      # rotas (validação Pydantic, serialização)
      service.py     # lógica de domínio
      repository.py  # SQLAlchemy Core (1 lugar para o SQL do agregado)
      schemas.py     # contratos de entrada/saída (Pydantic)
      auth.py        # token PROVISÓRIO da fatia A (auth real é plugada depois)
  tests/             # pytest + httpx (ASGI), contra um Postgres de teste
  alembic/           # migrations (env.py aponta para app.schema:metadata)
  alembic.ini
  pyproject.toml
  .env.example       # copie para .env
```

Organização **por domínio** (rotas→serviço→repositório), espelhando o Bloco 1. Novos
domínios (vocabulário, sessão, trilha…) entram como pastas-irmãs de `identidade/` e uma
linha em `api/v1.py`.

> **Acesso é provisório na fatia A.** A entrada nasce do `codigo_turma` e o token é só
> `prov_<usuario_id>` (sem assinatura/expiração) — ver `app/identidade/auth.py`. A
> autenticação real é plugada na janela do 1º cliente **sem mexer nas rotas** (princípio
> auth-agnóstico; arquitetura seção 3.11 / Bloco 3 decisão #4).

## Rodar localmente

Pré-requisito: um PostgreSQL acessível e a `DATABASE_URL` apontando para ele.

```bash
cd backend
python3 -m venv .venv && . .venv/bin/activate
pip install -e .
cp .env.example .env            # ajuste a DATABASE_URL se necessário

alembic upgrade head            # cria as tabelas do Bloco 1
python -m app.seed              # cria a turma de demo (código DEMO7A) — idempotente
uvicorn app.main:app --reload   # sobe a API
curl localhost:8000/health      # -> {"status":"ok"}
```

### Endpoints da fatia A (já implementados)

```bash
# entrar por código de turma (acha-ou-cria o aluno) → token provisório
curl -s -X POST localhost:8000/v1/acesso/turma \
  -H 'Content-Type: application/json' \
  -d '{"codigo_turma":"DEMO7A","nome":"Ana"}'
# -> {"token":"prov_1","usuario_id":1,"nome":"Ana","turma":{...},"novo":true}

# perfil + progresso do aluno autenticado
curl -s localhost:8000/v1/me -H 'Authorization: Bearer prov_1'
```

Erros saem no formato único (Bloco 3, decisão #5):
`{ "error": { "code": <snake_case>, "message": <legível>, "details": {} } }`.

## Testes

```bash
pip install -e ".[dev]"                       # pytest, pytest-asyncio, httpx
createdb -h localhost -U postgres vocabkids_test   # ou TEST_DATABASE_URL=...
pytest                                        # cria o schema a partir de app.schema
```

Os testes sobem o app via ASGI (sem rede) e usam um Postgres dedicado
(`vocabkids_test` por padrão; sobrescreva com `TEST_DATABASE_URL`). O schema vem do
mesmo `metadata` das migrations.

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
