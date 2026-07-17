# 🎬 Como apresentar o VocabKids

Guia rápido para mostrar o app funcionando (progressão, animações, Modo
Conquista) numa demo de 5–10 min. **Sem decorar nada.**

---

## O que são os "alunos vitrine"

Um aluno novo não junta XP suficiente em 5–10 min para mostrar as partes legais
(cartão postal, carimbo, selos, dois países, Modo Conquista). Por isso existem
**dois alunos já com progresso pronto** na turma **`DEMO7A`**:

| Nome de entrada | Onde está | O que mostra |
|---|---|---|
| **Ana Viajante** | Brasil inteiro + 2 destinos da França | Passaporte cheio (5 cartões BR + carimbo + 2 cartões FR + 2 selos), meta parcial da semana na Home, e o **Modo Conquista dispara ao vivo** ao abrir o Passaporte (tem um cartão ganho e não revelado). |
| **Beto Explorador** | Meio da jornada (Rio + Foz) | Trilha "em andamento", 2 cartões. |

> São os **apelidos** de entrada na turma. Digite exatamente `Ana Viajante` ou
> `Beto Explorador`. A turma é sempre a `DEMO7A`.

---

## Passo 0 — Ligar o Postgres (sempre que reiniciar o Mac)

O banco não sobe sozinho no boot. Antes de qualquer comando abaixo, ligue:

```bash
brew services run postgresql@16
```

> ⚠️ Tem que ser **`postgresql@16`** (com o `@16`). Sem a versão, o `brew`
> tenta o `postgresql@18`, que não é o nosso e falha com um erro de
> `launchctl bootstrap ... exited with 5`. Roda de qualquer pasta.
>
> Se um comando de banco der **"Connection refused"** na porta 5432, é só o
> Postgres parado — rode a linha acima. Para desligar: `brew services stop
> postgresql@16`.

---

## Passo 1 — Preparar o banco (só na PRIMEIRA vez)

No terminal, dentro do repositório:

```bash
cd backend
uv run alembic upgrade head            # cria as tabelas
uv run python -m app.seed              # turma DEMO7A + professora
uv run python -m app.seed_vocabulario  # palavras
uv run python -m app.seed_trilha       # países/destinos/nós + colecionáveis
uv run python -m app.seed_demo         # <-- Ana e Beto (os alunos vitrine)
```

> Se der erro de banco/token na primeira vez, veja o `CLAUDE.md` (seção
> Backend): precisa de um Postgres rodando (Passo 0), um `.env` e a variável
> `JWT_SECRET`.

---

## Passo 2 — Antes de CADA apresentação: rearmar a vitrine

Durante a demo o progresso da Ana e do Beto muda (eles jogam sessão ao vivo).
Este comando **devolve tudo ao estado certo** em segundos — inclusive o cartão
não revelado do Modo Conquista:

```bash
cd backend
uv run python -m app.seed_demo
```

**Rode isso toda vez antes de apresentar.** Pode rodar quantas vezes quiser.

---

## Passo 3 — Subir a API e o app

Deixe a API rodando num terminal:

```bash
cd backend
uv run uvicorn app.main:app --port 8000
```

Em outro terminal, abra o app do aluno:

```bash
cd app
flutter run -t lib/main.dart
```

> ⚠️ **NÃO** use `--dart-define=DEMO=true` no app do aluno. O modo DEMO ficou
> defasado de propósito — a vitrine vive no backend real. (O modo DEMO só serve
> pro site do professor por enquanto.)

---

## Passo 4 — Roteiro da demo (5–10 min)

1. **Entre com um nome NOVO** na turma `DEMO7A`.
   → Mostra onboarding + diagnóstico + uma **sessão ao vivo** (XP subindo,
   combo, erro suavizado em vermelho).

2. **Saia e entre como `Ana Viajante`** (turma `DEMO7A`).
   → Home com meta parcial da semana, Trilha com o Brasil concluído e a França
   em andamento, Passaporte cheio. Ao abrir o Passaporte, o **Modo Conquista
   dispara na hora**.

3. **(Opcional) Entre como `Beto Explorador`** para mostrar o meio da jornada.

---

## Resumo de bolso

- **Ligar o banco (após reiniciar o Mac):** `brew services run postgresql@16`
- **Toda apresentação:** `cd backend && uv run python -m app.seed_demo`
- **Turma:** `DEMO7A`
- **Alunos:** `Ana Viajante` (avançado + Modo Conquista) e `Beto Explorador` (meio)
- **App:** `cd app && flutter run -t lib/main.dart` (sem `DEMO=true`)
