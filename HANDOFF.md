# HANDOFF — estado de trabalho (VocabKids)

> Estado entre sessões. O **registro vivo** de decisões/feito está em
> `design/notas-implementacao.md`; este arquivo resume **onde paramos** e como
> retomar.

---

## Estado atual (12/07)

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

**1. Trio de segurança pré-piloto (bloqueante antes de qualquer aluno real).**
Hoje a auth é provisória e sem defesas — detalhes na análise de vulnerabilidades
(abaixo). Antes de expor a alunos de verdade:
- **Auth real:** trocar o token `prov_<id>` por JWT assinado com expiração. O
  módulo `backend/app/identidade/auth.py` foi desenhado para trocar **só ele**
  (a dependency `get_usuario_atual` continua igual). No app, migrar o token de
  `SharedPreferences` para `flutter_secure_storage`.
- **Papel/escopo nas rotas do professor:** cada rota de `app/professor/` já tem
  `TODO fatia C: exigir papel professor/coordenador + escopo por associação`.
  Hoje qualquer token de aluno acessa (inócuo com dados mock; vira exposição
  quando a fatia C ligar dados reais).
- **Rate limiting + CORS explícito** no FastAPI (`app/main.py`). Sem CORS o
  site do professor não fala com o backend real pelo browser (confirmado nesta
  sessão). Origens explícitas, nunca `*` com credenciais.

**2. Fatia C do professor** — trocar os mocks de `app/professor/` por queries
reais (`associacao_turma`/`turma_config`/`redacao_atribuicao` já existem no
schema, vazias). Os contratos e o app **não mudam** — só o miolo das rotas.
Inclui persistir a meta semanal (hoje a Home do aluno mostra "6/10" fixo — ver
`HomeMapper._metaSemanalPlaceholder`) e a atribuição de redação.

**3. Integridade do gameplay (endurecer, quando sobrar)** — em
`app/sessao/service.py:responder`: validar que a `questao_id` pertence à fila
da sessão, e respeitar `nivel4_agendado_para` ao responder N4 (hoje um cliente
adulterado poderia dominar palavras na hora e farmar o bônus de +500).

**Dever do dono (adiado de propósito, não é código):**
- **Revisão pedagógica do diagnóstico** — adiada até a preparação do piloto.
- **Expansão do seed de palavras** (hoje 8; a 2ª sessão esgota o vocabulário
  novo) — postergada por alguns dias; retomar antes de demo a escolas.

**Vulnerabilidades já mapeadas (para o passo 1):** token forjável (itera IDs
inteiros), login por turma+nome sem PIN (entra na conta de outro), criação de
contas ilimitada, zero rate limiting. O `api_client.dart:_send` faz `jsonDecode`
fora do try (um 502 com HTML vira `FormatException` crua). Rotas do professor
usam `HTTPException` em vez de `ApiError` (envelope de erro inconsistente).
Nomes de crianças sem fluxo de consentimento (LGPD — item de produto da fatia C).

---

## Como verificar (runtime, sem device físico)

Esta sessão validou o app **web** contra o backend local por um proxy
same-origin (o backend não tem CORS). Receita, tudo na máquina do dono:

```bash
# 1. Backend + banco (uma vez): Postgres local, migrations, seeds
cd backend
uv run alembic upgrade head
uv run python -m app.seed            # turma DEMO7A
uv run python -m app.seed_vocabulario
uv run python -m app.seed_trilha
uv run uvicorn app.main:app --port 8000   # deixa rodando

# 2. App web apontando para o proxy (NÃO usar --dart-define=DEMO)
cd app
flutter build web -t lib/main.dart --dart-define=API_BASE_URL=http://localhost:8080

# 3. Proxy same-origin serve os estáticos + repassa /v1 e /health ao :8000.
#    (nesta sessão usei um Starlette de ~30 linhas; qualquer reverse-proxy serve)
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
