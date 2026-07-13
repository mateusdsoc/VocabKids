# HANDOFF — estado de trabalho (VocabKids)

> Estado entre sessões. O **registro vivo** de decisões/feito está em
> `design/notas-implementacao.md`; este arquivo resume **onde paramos** e como
> retomar.

---

## Estado atual (13/07)

**🔐 Trio de segurança pré-piloto FEITO** (branch `security`) — o bloqueante
nº 1 saiu da frente. `pytest` **103/103**, `flutter analyze` limpo,
`flutter test` **39/39**. Detalhe em `design/notas-implementacao.md`
(seção "🔐 Trio de segurança"). Resumo:

1. **JWT HS256 com expiração** no lugar do `prov_<id>` — só
   `app/identidade/auth.py` mudou, como desenhado. Exige `JWT_SECRET` no
   ambiente (`openssl rand -hex 32`); TTL default 30 dias. Papel de
   autorização vem do **banco**, não do claim.
2. **Papel nas rotas do professor** (`require_papel`): aluno → 403; leitura
   professor/coordenador; meta e redação só professor. Seed cria a
   "Professora Demo" e `python -m app.seed` imprime um token dela (login real
   de professor = fatia C, junto com escopo por associação).
3. **Rate limiting** (janela 60s em memória; login por IP, autenticado por
   token — não pune a turma no NAT da escola) + **CORS explícito** por env
   `CORS_ORIGINS` (nunca `*`; preflight não toca o banco). Com isso o site do
   professor fala com o backend real **sem proxy** (basta pôr a origem no env).
4. **Fixes mapeados**: token do app em `flutter_secure_storage` (era
   SharedPreferences); `api_client.dart` sem `FormatException` crua em
   resposta não-JSON; mocks professor/redação em `ApiError` (envelope único).

⚠️ Operacional: o backend agora **não emite token sem `JWT_SECRET`** — em
máquina nova, `echo "JWT_SECRET=$(openssl rand -hex 32)" >> backend/.env`.
Tokens antigos (`prov_*`) caem em 401 e o app pede novo acesso — esperado.

---

## Estado anterior (12/07)

**🎉 Wiring do app do ALUNO completo — todas as telas consomem o backend
real (fora de `DEMO`).** Auth, Home, Sessão→Resumo, Passaporte (coleção +
Modo Conquista), **mapa da Trilha** e **diagnóstico do onboarding**. Padrão
em todas: DTOs (`features/<x>/data/`) → `*Mapper` → providers Riverpod.
Verificado em runtime (backend local + app web sem `DEMO`, via proxy
same-origin — ver "Como verificar"). `flutter analyze` limpo, `flutter test`
**39/39**, `pytest` **90/90**.

**O que esta sessão (11–12/07) entregou** — branch `claude/claude-md-docs-85mxpx`,
4 commits novos sobre `d444fcd`:
1. `6926d94` **fix build** — o wiring da Sessão (91c40a1) foi autorado sem SDK
   no container e **nunca compilava**: `AutoDisposeAsyncNotifier` não existe
   no Riverpod 3, e o `ReportPopover.onSelect` passava texto onde o handler
   esperava índice. Backend: `sqlalchemy[asyncio]` (o `greenlet` não instalava
   em macOS arm64).
2. `3fe0a14` **fix visual/UX** — `ProgressBar` nunca pintava (faltava
   `heightFactor`); datepicker em inglês (faltava `flutter_localizations` +
   locale pt-BR); Home não recarregava ao voltar da Sessão.
3. `89ac5e9` **Trilha real** — decisão do dono **"janela com template fixo"**:
   um destino por vez sobre o desenho travado (340×540), swipe/chevrons trocam
   de destino, abre no nó atual. `TrilhaMapper` (puro, com testes).
4. `8ca3b32` **Diagnóstico real** — aluno novo entra pelo gate no Onboarding;
   o passo 4 dialoga com `POST /v1/onboarding/diagnostico` (escada grosso→fino
   do servidor; estado opaco reenviado verbatim). Verificado: nível persistido
   subiu para 9 com acertos.

Residuais (não bloqueiam, registrados para não se perderem):
- Teaser de **cartão-postal** no Resumo não exercitado (exige fechar um
  destino; o mecanismo recompensa→fila→reveal foi coberto pelo selo).
- SnackBars de confirmação não conferidos visualmente (timing do headless).
- **CORS ausente** confirmado na prática: app web contra backend real só rodou
  atrás de proxy same-origin — entra com o trio de segurança abaixo.

---

## ▶️ Próximos passos (ordem sugerida)

**~~1. Trio de segurança pré-piloto~~ ✅ feito (13/07)** — ver "Estado atual".

**1. Fatia C do professor** — trocar os mocks de `app/professor/` por queries
reais (`associacao_turma`/`turma_config`/`redacao_atribuicao` já existem no
schema, vazias). Os contratos e o app **não mudam** — só o miolo das rotas.
Inclui persistir a meta semanal (hoje a Home do aluno mostra "6/10" fixo — ver
`HomeMapper._metaSemanalPlaceholder`), a atribuição de redação, o **login do
professor** (hoje o token sai do seed) e o **escopo por associação** (professor
só nas turmas de `associacao_turma` — o papel já é exigido desde 13/07).

**2. Integridade do gameplay (endurecer, quando sobrar)** — em
`app/sessao/service.py:responder`: validar que a `questao_id` pertence à fila
da sessão, e respeitar `nivel4_agendado_para` ao responder N4 (hoje um cliente
adulterado poderia dominar palavras na hora e farmar o bônus de +500).

**Dever do dono (adiado de propósito, não é código):**
- **Revisão pedagógica do diagnóstico** — adiada até a preparação do piloto.
- **Expansão do seed de palavras** (hoje 8; a 2ª sessão esgota o vocabulário
  novo) — postergada por alguns dias; retomar antes de demo a escolas.

**Riscos remanescentes (mapeados, não regridem):** login por turma+nome **sem
PIN** — dá para entrar na conta de outro aluno da mesma turma (decisão de
produto pendente; o rate limiting só freia a força bruta). Nomes de crianças
sem fluxo de consentimento (LGPD — item de produto da fatia C).

---

## Como verificar (runtime, sem device físico)

Desde 13/07 o backend tem CORS explícito — o app **web** fala direto com a API
local, **sem proxy**. Receita, tudo na máquina do dono:

```bash
# 1. Backend + banco (uma vez): Postgres local, migrations, seeds
cd backend
echo "JWT_SECRET=$(openssl rand -hex 32)" >> .env       # se ainda não tiver
echo "CORS_ORIGINS=http://localhost:8080" >> .env       # origem do app web local
uv run alembic upgrade head
uv run python -m app.seed            # turma DEMO7A + Professora Demo (imprime token)
uv run python -m app.seed_vocabulario
uv run python -m app.seed_trilha
uv run uvicorn app.main:app --port 8000   # deixa rodando

# 2. App web apontando direto para a API (NÃO usar --dart-define=DEMO)
cd app
flutter build web -t lib/main.dart --dart-define=API_BASE_URL=http://localhost:8000
cd build/web && python3 -m http.server 8080   # qualquer servidor estático na origem liberada
```

No dispositivo/emulador real não há CORS — aí basta
`flutter run -t lib/main.dart --dart-define=API_BASE_URL=<host>`.

---

## Estado anterior (06/07)

**App do aluno (Flutter, mobile) — fatia A completa + Sessão e Passaporte
integrados.** Todas as telas portadas, claro+escuro, com animações. **Home +
auth + Sessão → Resumo + Passaporte (coleção e Modo Conquista)** consomem o
backend real (fora de `DEMO`); o mapa da Trilha e o diagnóstico seguem em
mock/sample. Padrão em todas: DTOs (`features/<x>/data/`) → `*Mapper` →
providers Riverpod. A fila de reveals é persistida no servidor
(`revelado_em`); correção, XP/combo, re-queue e recompensas são server-side.
Detalhes e pendências nas seções "🔌 Wiring" de
`design/notas-implementacao.md`.

> ~~⚠️ Pendência de verificação (sem SDK no container)~~ **feita (11/07)** —
> ver "Estado atual" acima; só o teaser de fechar um destino ficou de fora.

**Superfície do Professor (web, Flutter) — fatia A completa (telas A–D).**
Entrypoint separado, mesmo design system, **sem pesar** o app do aluno. Painel
da turma (+ toggle de escopo turma↔escola), Detalhe do aluno, Atribuir redação
e Meta semanal. Tudo mock na fatia A; ver a seção abaixo.

**Backend (FastAPI).** Domínios: identidade, vocabulário, sessão, diagnóstico,
trilha, report (mock), redação (mock), **professor (mock)**. Testes:
`uv run pytest` (exige Postgres; ver `tests/conftest.py`) — **85 passam**.

---

## Superfície do Professor (web) — telas A–D completas

Decisão e plano completos em `design/notas-implementacao.md`
(seção "🧑‍🏫 Professor (web)"). Resumo:

- **Segundo entrypoint** `app/lib/main_professor.dart`, compilado pra **web** —
  **sem pesar** o app do aluno (regras de import R1/R2 + teste de guard em
  `app/test/arquitetura_professor_test.dart`).
- **Backend:** domínio mock `app/professor/` (moveu o antigo `/dashboard` de
  `redacao/` para `/professor/turmas/{id}/painel`). Rotas (todas mock fatia A):
  `GET /turmas`, `/turmas/{id}/painel`, `/escola`, `/alunos/{id}`;
  `POST /turmas/{id}/redacoes`; `PUT /turmas/{id}/meta`.
- **App:** cliente fino — DTOs espelham os schemas; `ProfessorMapper` traduz para
  modelos de apresentação; providers Riverpod (GETs em `FutureProvider`, mutações
  em `AsyncNotifier`); `AppConfig.demo` serve `*.sample` sem backend.

### Fases (cada uma = 1 commit, com docs contratuais juntos)
- ✅0 scaffolding+guard · ✅1 backend mock+wiring · ✅2 painel+toggle de escopo ·
  ✅3 detalhe do aluno (drill-down) · ✅4 atribuir redação (tema+prazo) ·
  ✅5 meta semanal (stepper + reflexão otimista no painel).
- 🔶 **6 higiene** (este HANDOFF feito; **falta a verificação visual
  claro/escuro** — ver pendências).
- **Deferidos** (E/F, fast-follow pós-feedback): redações da turma agregadas por
  dimensão; preset de rigor de redação (§4.3).

### Notas de arquitetura úteis para retomar
- **Tudo mock na fatia A:** GETs devolvem dados fixos em memória; `POST redacoes`
  e `PUT meta` **validam mas não persistem** (ecoam). Os *shapes* já espelham
  `associacao_turma`/`redacao_atribuicao`/`turma_config` → fatia C troca o miolo
  por queries reais **sem reescrever** app nem contratos (cada rota tem `TODO
  fatia C`: exigir papel+escopo por associação).
- **Meta no painel:** como a demo roda em `DEMO` (sem backend) e a meta aparece
  no painel, a `MetaSemanalScreen` registra um **override otimista**
  (`metaOverridesProvider`) que o `painelTurmaProvider` reaplica via
  `PainelData.comMeta`. Na fatia C isso vem persistido do servidor.
- **Drill-down/ações** são páginas empurradas (`Navigator.push`) com
  `ProfessorBackBar`; voltam com o resultado e o painel confirma por SnackBar.

### ~~🔶 Pendência da fase 6 — verificação visual claro/escuro~~ ✅ feita (11/07)
As 4 telas conferidas em claro+escuro (Chromium headless + screenshots),
incluindo o `showDatePicker` (agora em pt-BR) e o stepper de "Meta" com
reflexão otimista no painel. `flutter analyze` e `flutter test` verdes.

### Como rodar
```bash
# Aluno (mobile)
cd app && flutter run -t lib/main.dart

# Professor (web, demo) — abre direto no painel com dados de exemplo
cd app && flutter run -d chrome -t lib/main_professor.dart --dart-define=DEMO=true

# Build do site do professor
cd app && flutter build web -t lib/main_professor.dart
```

---

## Histórico do wiring do aluno (tudo feito)

- ~~Sessão server-side~~ **05/07** · ~~Passaporte + Modo Conquista~~ **06/07**
  · ~~mapa da Trilha (janela com template fixo)~~ **12/07** · ~~diagnóstico do
  onboarding~~ **12/07**. Detalhe de cada um nas seções "🔌 Wiring" de
  `design/notas-implementacao.md`.
- **Opcional pré-pitch (fora do wiring):** empacotar as fontes da marca como
  assets (confiabilidade da web em wifi instável).

> Próximos passos e itens adiados pelo dono: ver "▶️ Próximos passos" no topo.
