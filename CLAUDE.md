# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with
code in this repository.

# VocabKids — guia para agentes e devs

App de vocabulário (Flutter) + backend FastAPI para o Fundamental II brasileiro.
Tema: viagem/passaporte (3 países → 20 destinos → 80 nós). **Cliente fino,
servidor autoritativo**: o cliente nunca calcula pontuação nem recebe a
resposta correta antecipada.

> **Ambiente:** o backend é construído e testado na cloud (Python + Postgres
> disponíveis). O app **Flutter** é autorado no repositório e rodado na máquina
> do dono (o SDK Flutter normalmente **não existe** no container — nesse caso,
> não tente `flutter analyze`/`flutter test`; registre a pendência de
> verificação).

## Comandos

### Backend (`backend/`) — FastAPI + SQLAlchemy Core + Alembic + PostgreSQL

```bash
cd backend

# Testes (exigem um Postgres; usam vocabkids_test por padrão)
uv run pytest                          # suíte completa
uv run pytest tests/test_sessao.py     # um arquivo
uv run pytest tests/test_sessao.py -k nome_do_teste   # um teste
# Banco custom: TEST_DATABASE_URL=postgresql+asyncpg://... uv run pytest

# Subir um Postgres de desenvolvimento (sem Docker)
PGBIN=$(ls -d /usr/lib/postgresql/*/bin | head -1)
su postgres -c "$PGBIN/initdb -D /tmp/pgdata -U postgres --auth=trust"
su postgres -c "$PGBIN/pg_ctl -D /tmp/pgdata -o '-p 5432 -k /tmp' -l /tmp/pglog.log start"
psql -h localhost -U postgres -c "create database vocabkids;"
psql -h localhost -U postgres -c "create database vocabkids_test;"

# Rodar a API localmente
cp .env.example .env                   # ajuste DATABASE_URL se preciso
uv run alembic upgrade head            # cria as tabelas
uv run python -m app.seed              # turma demo (código DEMO7A) — idempotente
uv run python -m app.seed_vocabulario  # banco base (palavras/questões) — idempotente
uv run python -m app.seed_trilha       # trilha (países/destinos/nós) + colecionáveis
uv run uvicorn app.main:app --reload   # curl localhost:8000/health

# Migrations — o schema vive em app/schema.py; o Alembic autogera a partir dele
uv run alembic revision --autogenerate -m "descrição"
uv run alembic upgrade head
```

### App (`app/`) — Flutter, dois entrypoints

```bash
cd app
flutter analyze && flutter test        # inclui o guard de arquitetura R1/R2

# Aluno (mobile)
flutter run -t lib/main.dart

# Professor (web) — entrypoint separado
flutter run -d chrome -t lib/main_professor.dart --dart-define=DEMO=true
flutter build web -t lib/main_professor.dart

# dart-defines (ver lib/core/config.dart):
#   API_BASE_URL=...   base da API sem /v1 (default http://10.0.2.2:8000)
#   DEMO=true          pula auth e usa dados *.sample em todas as telas
#   THEME=dark|light   força o tema (default: sistema)
```

## Arquitetura

### Backend — organização por domínio

Cada domínio é uma pasta-irmã em `backend/app/` com camadas
**rotas → serviço → repositório** (`routes.py` valida/serializa via Pydantic
`schemas.py`; `service.py` tem a lógica; `repository.py` concentra o SQL em
SQLAlchemy Core). Domínio novo = pasta nova + uma linha em `app/api/v1.py`.

- Domínios: `identidade`, `vocabulario`, `sessao`, `diagnostico`, `trilha`,
  `progressao` (regras puras de XP/combo), `adaptacao` (regra pura de nível),
  e os **mocks da fatia A**: `report`, `redacao`, `professor` (devolvem dados
  fixos; viram reais na fatia C sem mudar contratos — cada rota tem
  `TODO fatia C`).
- **Schema único** em `app/schema.py` (25 tabelas, SQLAlchemy Core) — fonte
  tanto das migrations quanto do `create_all` dos testes. Tabelas da fatia C
  já existem (vazias no apresentável). PK `BIGINT IDENTITY`; enums via
  `VARCHAR + CHECK`. Migrations Alembic **lineares** (uma cadeia única).
- **Auth provisório da fatia A**: entrada por `codigo_turma`, token
  `prov_<usuario_id>` sem assinatura (`app/identidade/auth.py`). As rotas são
  auth-agnósticas; a auth real é plugada depois sem mexer nelas.
- **Erro em formato único**:
  `{"error": {"code": snake_case, "message": ..., "details": {}}}`
  (`app/errors.py`).
- Testes sobem o app via ASGI (httpx, sem rede) contra Postgres real;
  `tests/conftest.py` fixa `DATABASE_URL` **antes** de importar o app e trunca
  as tabelas entre testes.

### App Flutter — feature-first, cliente fino

- `lib/core/`: `api_client.dart`, providers, `config.dart` (dart-defines),
  tema em `core/theme/` (tokens em `app_colors.dart`). `lib/features/<tela>/`
  por funcionalidade.
- **Dois entrypoints**: `main.dart` (aluno, mobile) e `main_professor.dart`
  (professor, web). Regras de isolamento, verificadas por
  `test/arquitetura_professor_test.dart`:
  - **R1:** nada fora de `features/professor/` (nem `main.dart`) importa
    `features/professor/` — o tree-shaking tira o professor do APK/IPA;
  - **R2:** `features/professor/` importa só `core/` e a própria subárvore.
- Padrão de dados: DTOs espelham os schemas do backend; um `*Mapper` traduz
  para modelos de apresentação; providers Riverpod (GETs em `FutureProvider`,
  mutações em `AsyncNotifier`). `AppConfig.demo` serve dados `*.sample` sem
  backend.
- Estado atual do wiring: **só Home + auth** do aluno consomem o backend real;
  o resto roda em mock/sample (pendências em `HANDOFF.md`).

## Mapa dos documentos

| Documento | Papel |
|---|---|
| `docs/rascunho_product.md` | Produto — fonte da verdade das decisões de produto |
| `docs/arquitetura.md` | Arquitetura — modelo de dados, pipelines, API, app |
| `design/telas.md` | **Contrato** de conteúdo/comportamento de cada tela |
| `design/brief-mockup-*.md` | **Contrato** visual por tela (sistema travado) |
| `design/notas-implementacao.md` | Registro vivo: feito, adiado, decisões revisadas |
| `HANDOFF.md` | Estado de trabalho entre sessões (histórico) |

## ⚠️ Regra das decisões revisadas (obrigatória)

**Uma decisão revisada só vale quando os documentos contratuais forem editados
junto, no mesmo commit/PR.** Ao mudar uma decisão de produto/design:

1. Registrar a decisão (com data) em `design/notas-implementacao.md`;
2. **No mesmo commit**, atualizar `design/telas.md` e os briefs afetados
   (`design/brief-mockup-*.md`) — e `docs/arquitetura.md` se tocar
   modelo/API;
3. Se o backend/app já implementa o comportamento antigo, a mudança de código
   (com testes) entra no mesmo PR ou vira pendência explícita nas notas.

Racional: já regredimos por docs "travados" e desatualizados (erro âmbar→
vermelho, selo "você está aqui", combo por dia→por sessão). Um documento que
se declara travado e está errado é pior que nenhum documento.

## Decisões de produto que NÃO mudam sem o dono

- Sem streak diário, meta diária, mascote, % de acerto ou tempo/velocidade.
- Erro de resposta = vermelho suavizado (tint + borda/texto), nunca punitivo.
- Combo é **por sessão** (zera ao abrir sessão). Meta é **semanal** (professor).
- Colecionáveis são puramente colecionáveis (sem bônus de gameplay);
  reveal nítido só no Passaporte; determinístico, sem loot box.
- O cliente nunca calcula pontuação nem recebe a resposta correta antecipada.

## Convenções de código

- **Flutter** (`app/`): feature-first; cores via `context.colors` (tokens em
  `core/theme/app_colors.dart`), **nunca** hardcoded. Dependências com
  **versão exata** no `pubspec.yaml` (sem `^`); `pubspec.lock` commitado —
  atualizar dep é PR deliberado (o `pub get` solto já quebrou o build; ver
  comentário no `pubspec.yaml`).
- **Backend** (`backend/`): rotas → serviços → repositórios, por domínio.
  Regras puras (XP, combo, adaptação) vivem em módulos sem I/O
  (`progressao/xp.py`, `adaptacao/regras.py`) para testar sem banco.
  Migrations Alembic lineares. Testes: `uv run pytest` (exige Postgres; ver
  `tests/conftest.py`).
- Idioma do projeto: código, docs e commits em **português**.
