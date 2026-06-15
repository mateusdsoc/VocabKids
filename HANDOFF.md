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

**Backend (FastAPI).** Domínios: identidade, vocabulário, sessão, diagnóstico,
trilha, report (mock), redação (mock). Testes: `uv run pytest` (exige Postgres;
ver `tests/conftest.py`).

---

## 🚧 Trabalho ativo: superfície do Professor (web)

Decisão e plano completos em `design/notas-implementacao.md`
(seção "🧑‍🏫 Professor (web)"). Resumo:

- **Segundo entrypoint** `app/lib/main_professor.dart`, compilado pra **web** —
  **sem pesar** o app do aluno (regras de import R1/R2 + teste de guard em
  `app/test/arquitetura_professor_test.dart`).
- **Escopo da demo:** Painel da turma (+ toggle de escopo turma↔escola), Detalhe
  do aluno, Atribuir redação, Meta semanal. E/F deferidos.
- **Backend:** novo domínio mock `app/professor/` (move o `/dashboard` de
  `redacao/`).
- **Fases:** 0 scaffolding+guard · 1 backend mock+wiring · 2 painel+toggle ·
  3 detalhe do aluno · 4 atribuir redação · 5 meta semanal · 6 higiene.

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
