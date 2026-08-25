# HANDOFF — estado de trabalho (VocabKids)

> Estado entre sessões. O **registro vivo** de decisões/feito está em
> `design/notas-implementacao.md`; este arquivo resume **onde paramos** e como
> retomar.

---

## Estado atual (24/08, pivô B2C — Fases 1–3 de `docs/plano_b2c.md` feitas)

**Pivô B2C em andamento.** Produto saiu de venda por escola pra assinatura
direto pra família — decisão e racional completos em
`design/notas-implementacao.md` § "Pivô B2C" e `docs/plano_b2c.md` (a fonte
da verdade do produto agora; os docs antigos ficaram com nota de pré-pivô no
topo, não foram reescritos por inteiro).

**Feito nesta rodada:**
1. **Fase 1 — Identidade familiar.** Conta do responsável + até 3 perfis de
   criança, sem senha própria pra criança. `POST /v1/conta`, `POST
   /v1/sessao` (login), `GET/POST /v1/conta/perfis`, `POST
   /v1/perfis/{id}/entrar`, `DELETE /v1/conta`. `/v1/acesso/turma` saiu da
   API pública (professor congelado segue com o próprio caminho). App:
   `SessaoState` selado guia o `_Gate` em `main.dart`.
2. **Fase 2 — Recalibração por faixa etária.** `progressao/faixa.py`
   substitui `ano_escolar` como eixo de calibração (nível inicial, meta
   semanal, nível máximo). Adaptação e seleção de palavras nunca passam do
   teto da faixa; orçamento de perguntas do diagnóstico também por faixa.
3. **Corte da trilha pro MVP.** `seed_trilha.py`: 2 países/4 destinos/16 nós
   (Rio, Foz, Amazônia, Paris) — só o que já tem arte pronta. Catálogo
   completo (3/20/80) documentado pra voltar depois, sem mexer em schema.
4. **Fase 3 — Assinatura (Apple IAP via RevenueCat).** `POST /v1/sessoes`
   gateado (livre até o 1º destino, depois exige assinatura ativa da
   *conta*). Webhook `POST /v1/assinatura/webhook` idempotente. App:
   `purchases_flutter` + paywall — **só alcançável pelo responsável**, nunca
   pela criança em meio ao jogo (decisão tomada nesta sessão, não estava no
   plano original: Apple 5.1.4 exige adulto na tela antes de qualquer
   compra).

**Verificado:** 147 testes de backend + 42 do app, `flutter analyze` limpo, e
o fluxo inteiro (cadastro → perfil → onboarding → diagnóstico → paywall →
webhook → sessão liberada) rodado ao vivo no **simulador iOS** — foi lá,
não em teste automatizado, que apareceu o único bug real da sessão: telas
empilhadas (`Navigator.push`) não se desempilhavam sozinhas quando o `_Gate`
trocava o estado por baixo. Corrigido.

**Pendente, explícito:**
- Fases 4–6 do plano B2C (redação real com IA, Área do Responsável,
  congelamento formal do professor) não começaram.
- Conta RevenueCat/Apple Developer real — sem ela, o paywall funciona
  estruturalmente mas mostra "configuração pendente" (`AppConfig.revenueCatApiKey`).
- `docs/rascunho_product.md`, `docs/arquitetura.md`, `design/telas.md` e os
  briefs não foram reescritos por inteiro pro B2C (só ganharam nota de
  pré-pivô no topo) — onde contradizem `docs/plano_b2c.md`, vale o plano.

---

## Estado anterior (13/07, noite)

**📚 Seed de vocabulário expandido FEITO** — 8 → **37 palavras** curadas,
distribuídas nos níveis 1–10 (3–4 por nível; antes faltavam por completo os
níveis 1, 8, 9 e 10). Resolve o "2ª sessão esgota o vocabulário novo" e dá ao
diagnóstico conteúdo para exercitar a escada inteira. As 4 palavras antigas
usadas por testes (`enorme`, `veloz`, `belo`, `relevante`) foram preservadas.
`pytest` **106/106** (1 teste novo — idempotência do seed; mais o ajuste do
teste de listagem para pedir `?limit=100`, já que o banco base passou do
default de 20). Nada muda de contrato: só `seed_vocabulario.py` cresceu.

> **Reprodutibilidade entre as duas máquinas (notebook/desktop):** garantida
> porque o banco base **vive no arquivo versionado** `seed_vocabulario.py` e o
> seed é **idempotente por `lema`**. Em cada máquina: `git pull` + `uv run
> python -m app.seed_vocabulario` produz o mesmo vocabulário; rodar de novo não
> duplica. ⚠️ O **progresso do aluno** (XP, sessões, palavras dominadas) é por
> banco local e **não** sincroniza entre máquinas — isso é esperado no setup
> atual (Postgres local em cada uma); um banco compartilhado/hospedado seria
> outra decisão, se um dia quiser progresso contínuo entre as máquinas.

**🛡️ Integridade do gameplay FEITA** — as duas guardas que faltavam no
`responder` (`app/sessao/service.py`): questão precisa ter sido apresentada
(fila **ou** tentativa anterior — o retry legítimo de uma errada sai da fila
na intercalação) → 409 `questao_fora_da_sessao`; e N4 só conta com o
agendamento vencido → 409 `nivel4_nao_vencido` (fecha o farm do bônus de
+500). Só o serviço mudou — sem mudança de contrato nem de app. `pytest`
**105/105** (2 testes novos). Detalhe em `design/notas-implementacao.md`
(seção "🛡️ Integridade do gameplay").

---

## Estado anterior (13/07, tarde)

**🧑‍🏫 Fatia C do professor FEITA** (branch `security`, na sequência do trio) —
os mocks de `app/professor/` viraram **queries reais com escopo por
associação**, sem mudar contratos nem o app do professor. `pytest` **103/103**,
`flutter analyze` limpo, `flutter test` **39/39**, smoke em runtime ok.
Decisões datadas em `design/notas-implementacao.md` (seção "🧑‍🏫 Fatia C").

1. **Painéis reais**: turmas/painel/escola/detalhe do aluno saem de
   `associacao_turma`, `aluno_palavra` (dominadas na semana), `aluno_progresso`
   (acumulado) e `sessao` (ativos). Agregados por turma (sem N+1). Sinal de
   turma lê `sinal_turma` (vazia até o pipeline de redação rodar).
2. **Persistência**: `PUT meta` → upsert em `turma_config`; `POST redacoes` →
   `redacao_atribuicao` com o professor autor; o detalhe do aluno lista as
   atribuições com status traduzido (`pendente`/`em_analise`/`analisada`).
3. **Escopo (§3.11)**: professor só nas próprias turmas (403 fora);
   coordenador escola inteira, só leitura. Papel já vinha do trio.
4. **Meta na Home do aluno**: `/v1/me` ganhou `meta_semanal {atual, alvo}`
   (semana = segunda 00:00 America/Sao_Paulo; default por ano 6º=4…9º=7,
   **provisório** — calibração pedagógica pendente). O app trocou o "6/10"
   fixo pelo dado real (`HomeMapper`).
5. **Fora desta fatia (decisão do dono, 13/07)**: login do professor — o site
   segue em `DEMO`/token do seed até o fluxo definitivo (SSO/magic link) ser
   decidido com a escola cliente.

---

## Estado anterior (13/07, manhã)

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

**~~1. Trio de segurança pré-piloto~~ ✅ feito (13/07)** — ver "Estado anterior".

**~~2. Fatia C do professor~~ ✅ feita (13/07)** — ver "Estado atual". Ficaram
de fora, de propósito: **login do professor** (decisão de produto com a escola
cliente — até lá o site roda em `DEMO` e o token real sai do seed) e o job do
**sinal de turma** (é do pipeline de redação, fatia C de redação).

**~~1. Integridade do gameplay~~ ✅ feita (13/07, noite)** — ver "Estado
atual". Com isso, **não há mais pendência de código mapeada** antes das
tarefas do dono e das decisões de produto abaixo.

**Dever do dono (adiado de propósito, não é código):**
- **Revisão pedagógica do diagnóstico** — **só será feita quando estivermos em
  contato com as escolas** (decisão do dono, 13/07). Até lá a escada e os
  limiares atuais ficam como estão; a calibração (limiares de subir/descer,
  níveis default por ano, dificuldade das palavras) sai com o retorno
  pedagógico do 1º cliente, não antes.
- ~~**Expansão do seed de palavras**~~ ✅ feita (13/07, noite) — 37 palavras,
  níveis 1–10. Ver "Estado atual". Segue reduzida frente às 500–800 de
  produção (banco gerado+revisado offline, Bloco 3), mas sem o gargalo da 2ª
  sessão.

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
uv run python -m app.seed_demo       # alunos vitrine p/ apresentação (re-rodar = reset)
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
