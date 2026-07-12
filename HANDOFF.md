# HANDOFF — estado de trabalho (VocabKids)

> Estado entre sessões. O **registro vivo** de decisões/feito está em
> `design/notas-implementacao.md`; este arquivo resume **onde paramos** e como
> retomar.

---

## Estado atual (11/07)

**✅ Verificação pendente CUMPRIDA (11/07, máquina local com SDK + Postgres).**
`flutter analyze` limpo, `flutter test` 33/33, `pytest` 90/90. Verificação
manual em runtime (backend real + app web sem `DEMO`, via proxy same-origin):
sessão inteira (16 slots, XP/combo server-side conferidos no papel), erro
suavizado + re-fila com outra variação, Resumo real, Passaporte com coleção
e **Modo Conquista** (reveal persistido em `revelado_em`), e as 4 telas do
professor em claro+escuro (incl. datepicker e stepper). Consertados no
processo: compilação pós-Riverpod 3, bug de tipo do report popover,
`greenlet` (macOS arm64), `ProgressBar` que nunca pintava o preenchimento,
datepicker em inglês (faltava `flutter_localizations`) e Home que não
recarregava ao voltar da sessão.

Residuais da verificação (não bloqueiam):
- Teaser de **cartão-postal** no Resumo não exercitado (exige fechar um
  destino; o mecanismo recompensa→fila→reveal foi coberto pelo selo).
- SnackBars de confirmação não conferidos visualmente (timing do headless).
- CORS ausente confirmado na prática: app web contra backend real só rodou
  atrás de proxy same-origin — entra com o trio de segurança da fatia C.
- Seed tem só 8 palavras: a 2ª sessão já esgota vocabulário novo — expandir
  o banco base antes de demo a escolas.

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

## Pendências conhecidas (fora do professor)

- ~~Sessão server-side~~ **feita (05/07)**; ~~Passaporte + Modo Conquista~~
  **feitos (06/07)** — ver "🔌 Wiring" nas notas.
- **Wiring restante do aluno:** mapa da Trilha com dados reais (**bloqueado em
  decisão de design** — janela/posições para 20 destinos; ver notas) e
  diagnóstico do onboarding (`POST /v1/onboarding/diagnostico`).
- **Revisão pedagógica do diagnóstico** (professor — não é tarefa de código).
- **Opcional pré-pitch:** empacotar as fontes da marca como assets
  (confiabilidade da web em wifi instável).
