# 🎬 Como apresentar o VocabKids

Guia rápido para mostrar o app funcionando (progressão, animações, Modo
Conquista) numa demo de 5–10 min. **Sem decorar nada.**

---

## O que são os perfis "vitrine"

Uma criança nova não junta XP suficiente em 5–10 min para mostrar as partes
legais (cartão postal, carimbo, selos, dois destinos, Modo Conquista). Por
isso existe uma **conta de responsável "vitrine"**, com **assinatura ativa**
e **dois perfis de criança já com progresso pronto**:

- **E-mail:** `vitrine@vocabkids.demo`
- **Senha:** `vitrine-demo-2026`

| Perfil (apelido) | Onde está | O que mostra |
|---|---|---|
| **Ana Viajante** | Brasil concluído + 2 destinos da França | Passaporte avançado (cartões + carimbo do Brasil + cartões da França + selos), meta parcial da semana na Home, e o **Modo Conquista dispara ao vivo** ao abrir o Passaporte (tem um item ganho e não revelado). |
| **Beto Explorador** | Meio da jornada (2 destinos do Brasil) | Trilha "em andamento". |

> São os **apelidos** dos perfis de criança dentro da conta vitrine — não há
> mais turma nem código de acesso (isso saiu do produto no pivô B2C).

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
uv run python -m app.seed_vocabulario  # banco base de palavras
uv run python -m app.seed_trilha       # trilha MVP (2 países/4 destinos/16 nós) + colecionáveis
uv run python -m app.seed_temas        # catálogo de temas de redação
uv run python -m app.seed_demo         # <-- conta vitrine + Ana e Beto
```

> Se der erro de banco/variável de ambiente na primeira vez, veja o
> `CLAUDE.md` (seção Backend): precisa de um Postgres rodando (Passo 0), um
> `.env` com `JWT_SECRET`, `REVENUECAT_WEBHOOK_SECRET` e `ANTHROPIC_API_KEY`.

---

## Passo 2 — Antes de CADA apresentação: rearmar a vitrine

Durante a demo o progresso da Ana e do Beto muda (eles jogam sessão ao vivo).
Este comando **devolve tudo ao estado alvo** em segundos — inclusive o item
não revelado do Modo Conquista:

```bash
cd backend
uv run python -m app.seed_demo
```

**Rode isso toda vez antes de apresentar.** Pode rodar quantas vezes quiser
(idempotente e restaurador).

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

> ⚠️ **NÃO** use `--dart-define=DEMO=true`. O modo `DEMO` serve só para
> exercitar telas sem backend (dados `*.sample`) — a vitrine da apresentação
> vive no backend real, com a conta acima.

---

## Passo 4 — Roteiro da demo (5–10 min)

1. **Cadastre-se com um e-mail novo** (ou entre com a conta vitrine e crie um
   perfil de criança novo).
   → Mostra cadastro do responsável → criar perfil da criança → onboarding →
   diagnóstico → uma **sessão ao vivo** (XP subindo, combo, erro suavizado em
   vermelho).

2. **Entre com a conta vitrine** (`vitrine@vocabkids.demo` /
   `vitrine-demo-2026`) **e selecione "Ana Viajante"**.
   → Home com meta parcial da semana, Trilha com o Brasil concluído e a
   França em andamento, Passaporte avançado. Ao abrir o Passaporte, o **Modo
   Conquista dispara na hora**.

3. **(Opcional) Selecione "Beto Explorador"** para mostrar o meio da jornada.

4. **(Opcional) Área do Responsável:** no Seletor de Perfil, o atalho da
   Área do Responsável pede o PIN (crie um na primeira vez) e mostra o
   resumo semanal por filho.

---

## Resumo de bolso

- **Ligar o banco (após reiniciar o Mac):** `brew services run postgresql@16`
- **Toda apresentação:** `cd backend && uv run python -m app.seed_demo`
- **Conta vitrine:** `vitrine@vocabkids.demo` / `vitrine-demo-2026`
- **Perfis:** `Ana Viajante` (avançado + Modo Conquista) e `Beto Explorador` (meio)
- **App:** `cd app && flutter run -t lib/main.dart` (sem `DEMO=true`)
