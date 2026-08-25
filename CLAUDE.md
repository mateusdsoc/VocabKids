# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with
code in this repository.

# VocabKids — guia para agentes e devs

App de vocabulário (Flutter) + backend FastAPI, assinatura B2C direto pra
família (7–12 anos) — pivô de B2B/escola em 24/08/2026, ver
`docs/plano_b2c.md` e a decisão datada em `design/notas-implementacao.md`.
Tema: viagem/passaporte. Catálogo do **MVP**: 2 países, 4 destinos, 16 nós
(Rio, Foz do Iguaçu, Amazônia, Paris) — o catálogo completo (3 países / 20
destinos / 80 nós) fica pra depois do MVP, já semeado em `seed_trilha.py` como
referência comentada. **Cliente fino, servidor autoritativo**: o cliente nunca
calcula pontuação nem recebe a resposta correta antecipada, e nunca decide
sozinho se a assinatura está ativa (`docs/plano_b2c.md` R-AS-1).

O **professor/B2B está congelado, não deletado** (`docs/plano_b2c.md` Fase 6):
o backend (`app/professor/`) e o site (`app/lib/features/professor/`)
continuam no repo e funcionando, mas fora do caminho crítico do produto atual
— não espere novidade ali a menos que o dono reabra essa frente.

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
echo "JWT_SECRET=$(openssl rand -hex 32)" >> .env          # obrigatório (auth JWT)
echo "REVENUECAT_WEBHOOK_SECRET=troque-isto" >> .env       # obrigatório p/ POST /v1/assinatura/webhook
uv run alembic upgrade head            # cria as tabelas
uv run python -m app.seed_vocabulario  # banco base (palavras/questões) — idempotente
uv run python -m app.seed_trilha       # trilha MVP (2 países/4 destinos/16 nós) + colecionáveis
uv run python -m app.seed_demo         # conta+perfis "vitrine" (com assinatura ativa) p/ demo — reset a cada rodada
uv run python -m app.seed              # só se for mexer no professor/B2B congelado — turma DEMO7A + professora
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
#   API_BASE_URL=...        base da API sem /v1 (default http://10.0.2.2:8000)
#   DEMO=true               pula auth e usa dados *.sample em todas as telas
#   THEME=dark|light        força o tema (default: sistema)
#   REVENUECAT_API_KEY=...  paywall sem isso mostra "configuração pendente" (Fase 3)
```

## Arquitetura

### Backend — organização por domínio

Cada domínio é uma pasta-irmã em `backend/app/` com camadas
**rotas → serviço → repositório** (`routes.py` valida/serializa via Pydantic
`schemas.py`; `service.py` tem a lógica; `repository.py` concentra o SQL em
SQLAlchemy Core). Domínio novo = pasta nova + uma linha em `app/api/v1.py`.

- Domínios: `identidade` (conta do responsável + perfis de criança, B2C),
  `assinatura` (gate de entitlement + webhook do RevenueCat, B2C),
  `vocabulario`, `sessao`, `diagnostico`, `trilha`, `progressao` (regras puras
  de XP/combo, semana letiva, meta por faixa etária e faixa→parâmetros —
  `progressao/faixa.py`), `adaptacao` (regra pura de nível, respeita o teto da
  faixa), `professor` (**congelado, B2B** — queries reais + escopo por
  associação seguem funcionando, mas fora do produto atual) e os **mocks
  restantes da fatia A**: `report`, `redacao` (viram reais na Fase 4 do B2C).
- **Schema único** em `app/schema.py` (29 tabelas, SQLAlchemy Core) — fonte
  tanto das migrations quanto do `create_all` dos testes. PK `BIGINT
  IDENTITY`; enums via `VARCHAR + CHECK`. Migrations Alembic **lineares** (uma
  cadeia única) — `turma`/`escola`/`associacao_turma`/`turma_config` e
  `sinal_turma` seguem no schema (usados pelo professor congelado), mas fora
  do caminho de identidade do B2C.
- **Auth B2C**: cadastro por e-mail/senha do responsável (`POST /v1/conta`) →
  cria até 3 perfis de criança (`POST /v1/conta/perfis`, sem senha própria) →
  troca o token do responsável pelo de gameplay (`POST
  /v1/perfis/{id}/entrar`). Um token nunca serve os dois escopos: rotas de
  gameplay exigem papel `aluno`, rotas de conta exigem papel `responsavel`
  (`require_papel`, `app/identidade/auth.py`). Sessão em **JWT HS256 com
  expiração** (exige `JWT_SECRET` no ambiente, gere com `openssl rand -hex
  32`; TTL via `JWT_TTL_HORAS`). O professor congelado mantém seu próprio
  login-por-seed e escopo por associação (turma/escola), sem se misturar com
  o fluxo do responsável. **Rate limiting** em memória
  (`app/seguranca/rate_limit.py`) e **CORS explícito** via `CORS_ORIGINS`
  (nunca `*`) em `app/main.py`. No app, o token vive em
  `flutter_secure_storage` (`core/token_store.dart`) — só **um** por vez (ver
  `docs/plano_b2c.md` R-ID-2/R-ID-3).
- **Assinatura**: `POST /v1/sessoes` é o único endpoint gateado — livre até o
  1º destino (limiar lido do catálogo semeado, não hardcoded), depois exige
  assinatura ativa da conta (402 `assinatura_necessaria`). O backend nunca
  fala StoreKit/JWS diretamente: o RevenueCat resolve a compra e manda um
  webhook normalizado (`POST /v1/assinatura/webhook`, autenticado por segredo
  compartilhado — `REVENUECAT_WEBHOOK_SECRET`).
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
- **Estado de sessão B2C** (`features/identidade/auth_controller.dart`):
  `SessaoState` selado — `Deslogado` → `AguardandoPerfil` (token de
  responsável, escolhendo/criando perfil) → `Autenticado` (token de
  gameplay). `main.dart#_Gate` troca de tela conforme o estado; telas
  empilhadas via `Navigator.push` (cadastro, criar criança) se
  auto-desempilham no sucesso, porque o `_Gate` só troca o que está *por
  baixo* da pilha.
- Estado atual do wiring: **o app do aluno consome o backend real de ponta a
  ponta** — cadastro/login do responsável, seletor de perfil, Home (meta
  semanal por faixa etária), Sessão→Resumo (gateada por assinatura além do 1º
  destino), Passaporte (coleção e Modo Conquista), mapa da Trilha e
  diagnóstico do onboarding (orçamento de perguntas por faixa). Paywall
  (`features/assinatura/`) funciona estruturalmente mas precisa da API key
  real do RevenueCat (`AppConfig.revenueCatApiKey`) pra listar oferta de
  verdade — sem ela mostra "configuração de pagamento pendente". O
  **professor** (backend real, site em `DEMO`) está **congelado** — fora do
  produto atual, não é onde investir esforço agora. Estado e próximos passos
  em `HANDOFF.md` e `docs/plano_b2c.md`.

## Mapa dos documentos

| Documento | Papel |
|---|---|
| `docs/plano_b2c.md` | **Plano B2C — fonte da verdade atual**: fases, regras de negócio (R-ID/R-FX/R-AS/...), schema, ferramentas, checklist |
| `docs/rascunho_product.md` | Produto **B2B original** (pré-pivô) — banco de vocabulário/XP/trilha/diagnóstico ainda valem; identidade, público e monetização, não (ver plano B2C) |
| `docs/arquitetura.md` | Arquitetura **B2B original** (pré-pivô) — pipelines de redação e princípios gerais (cliente fino/servidor autoritativo) ainda valem; Bloco 1 (identidade por turma) e Bloco 3 (domínios), não |
| `design/telas.md` | **Contrato** de conteúdo/comportamento de cada tela — telas B2B pré-pivô; as novas telas B2C (cadastro, seletor de perfil, paywall) ainda não têm contrato formal aqui |
| `design/brief-mockup-*.md` | **Contrato** visual por tela (sistema travado) — mesma ressalva: pré-pivô |
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
- Combo é **por sessão** (zera ao abrir sessão). Meta é **semanal**, default
  por faixa etária da criança (`progressao/faixa.py`) — não há mais professor
  configurando (fatia B2B congelada).
- Colecionáveis são puramente colecionáveis (sem bônus de gameplay);
  reveal nítido só no Passaporte; determinístico, sem loot box.
- O cliente nunca calcula pontuação nem recebe a resposta correta antecipada.
- O cliente nunca decide sozinho se a assinatura está ativa — sempre o backend
  (`docs/plano_b2c.md` R-AS-1).
- Nenhuma compra acontece sem um adulto na tela (Apple 5.1.4) — o paywall só é
  alcançável a partir do contexto do responsável, nunca durante o gameplay da
  criança (que só vê "peça pra um adulto continuar").

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
