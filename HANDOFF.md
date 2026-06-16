# HANDOFF — estado de trabalho (VocabKids)

> Estado entre sessões. O **registro vivo** de decisões/feito está em
> `design/notas-implementacao.md`; este arquivo resume **onde paramos** e como
> retomar.

---

## Estado atual (15/06)

**App do aluno (Flutter, mobile) — fatia A praticamente completa.** Todas as
telas portadas, claro+escuro, com animações: Home, Sessão, Resumo, Trilha,
Passaporte (Modo Conquista), Onboarding (diagnóstico jogável mock), Perfil,
Configurações, Redação. Build OK — o antigo bloqueio do riverpod (`valueOrNull`)
foi resolvido e as deps são exatas no `pubspec.yaml`. As telas rodam em
`*.sample`/mock; **só Home + auth** consomem o backend de verdade.

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

### 🔶 Pendência da fase 6 — verificação visual claro/escuro
Falta abrir as 4 telas no Chrome e conferir claro+escuro (incl. o `showDatePicker`
de "Atribuir redação" e o stepper de "Meta"). **Não foi possível na sessão atual**
(ambiente headless, sem SDK Flutter). Garantias estáticas já feitas: **zero cores
hardcoded** em `features/professor/` (tudo via `context.colors`), R1/R2 verificados
e `flutter_lints` respeitado nas convenções. Falta só a conferência de olho:
```bash
cd app && flutter run -d chrome -t lib/main_professor.dart --dart-define=DEMO=true --dart-define=THEME=dark
cd app && flutter run -d chrome -t lib/main_professor.dart --dart-define=DEMO=true --dart-define=THEME=light
```
Rodar também `flutter analyze` e `flutter test` (inclui o guard de isolamento e os
testes de mapper do professor) — não rodaram aqui por falta de SDK.

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

- **Wiring app↔backend** do aluno: Sessão server-side (`/v1/sessoes`,
  `/respostas`), fila de conquistas via `/v1/passaporte`, gatilho real do
  "completar nó" na Trilha.
- **Revisão pedagógica do diagnóstico** (professor — não é tarefa de código).
- **Opcional pré-pitch:** empacotar as fontes da marca como assets
  (confiabilidade da web em wifi instável).
