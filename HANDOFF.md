# HANDOFF — estado de trabalho (VocabKids)

> Estado entre sessões. O **registro vivo** de decisões/feito está em
> `design/notas-implementacao.md`; este arquivo resume **onde paramos** e como
> retomar.

---

## Estado atual (31/08 — deploy do backend em produção, em andamento)

**Banco de produção provisionado e semeado.** Neon (projeto `vocabkids-prod`,
região `us-west-2`), schema criado via `alembic upgrade head` e os 3 seeds de
conteúdo do MVP rodados: 100 palavras/800 questões, 2 países/4 destinos/16 nós,
120 temas de redação. Detalhe da escolha (Neon + Vercel, por que não
Fly/Railway/Render) e da pegadinha de SSL na connection string em
`design/notas-implementacao.md` § "Deploy do backend em produção".

**API ainda não está no ar** — próximo passo é criar o projeto Vercel linkado
ao repo (`backend/vercel.json` e `backend/requirements.txt` já commitados) e
configurar `DATABASE_URL`/`JWT_SECRET` lá. **Pendências explícitas de config**
que não dá pra automatizar: `OPENAI_API_KEY` (conta OpenAI real) e
`REVENUECAT_WEBHOOK_SECRET`/API key do RevenueCat — sem eles a análise de
redação e a assinatura falham com erro claro, o resto da API funciona.

**Risco aceito, registrado:** rate limiting é em memória por processo
(`app/seguranca/rate_limit.py`); sob Vercel serverless o limite passa a valer
por instância, não globalmente — aceitável no volume de MVP, mover pra Redis
quando o tráfego justificar.

---

## Estado anterior (25/08 — Fases 4, 5 e 6 do B2C)

**Professor/B2B deletado, não só congelado** — `docs/produto/plano_b2c.md` §09
(revisado na hora: o plano original mandava congelar; o dono decidiu deletar
de verdade). Saiu backend (`app/professor/`, `app/seed.py`,
`test_professor.py`), schema (`turma`/`escola`/`associacao_turma`/
`turma_config`/`sinal_turma`, `associacao.escola_id`) e app Flutter
(`features/professor/`, `main_professor.dart`, os 2 testes que verificavam o
isolamento R1/R2). Foi a primeira vez nesta sessão que o Flutter local do
dono ficou acessível pro agente (worktree, não o container cloud) — deu pra
rodar `flutter analyze`/`flutter test` de verdade, não só registrar
pendência. Detalhe completo em `design/notas-implementacao.md` § "Fase 6"
(25/08/2026).

**Redação real substituiu o mock** (`backend/app/redacao/`) —
`docs/produto/plano_b2c.md` §07, detalhe completo e todas as pendências em
`design/notas-implementacao.md` § "Fase 4" (25/08/2026). Rubrica pura por
faixa, triagem de risco + análise pedagógica numa chamada ao Claude,
atribuição de tema automática (a cada 15 dias, best-effort) e sob demanda
(máx. 2/mês, pedida pelo responsável). Schema: `tema_catalogo` nova;
`redacao_atribuicao` chegou a coexistir com o professor congelado
(`turma_id` XOR `usuario_id`) — mas isso durou só até a Fase 6, no mesmo dia:
com o professor deletado, a tabela voltou ao desenho original do plano (só
`usuario_id`).

**Área do Responsável, backend só** (`backend/app/responsavel/`) —
`docs/produto/plano_b2c.md` §08, notas em § "Fase 5" (25/08/2026). Portão PIN
(`conta.pin_hash`, já existia no schema desde a Fase 1, nunca usado até
agora) e resumo semanal por perfil (meta/minutos/sessões, 5 palavras
aprendidas, evolução da redação por dimensão — exigiu um retrofit pequeno na
Fase 4: o analisador agora também classifica cada dimensão em 4 níveis
nomeados, R-RD-6). De quebra, achado e corrigido um rate limit frouxo demais
no PIN (caía no teto genérico de 240/min — um PIN de 4 dígitos seria
força-bruteável em ~42min; movido pro teto de login, 5/min).

**Estado final da sessão original (backend):** 155 testes de backend, 26 de
app, `flutter analyze` limpo — todos verdes. Redação/Área do Responsável:
app Flutter não tocado nesta rodada (só o backend); Professor: app e backend
deletados juntos, sem defasagem entre os dois lados.

> ✅ **Atualização (25/08, sessão seguinte):** as duas telas de app que
> faltavam foram feitas — ver "▶️ Próximos passos" abaixo. `redacao_screen.dart`
> e `app/lib/features/responsavel/` consomem o backend real de ponta a ponta
> agora; os parágrafos acima descrevem o estado logo após a sessão de
> backend, não o estado atual.

**Pendente, explícito (backend roda, mas não está pronto pra produção):**
sem fila assíncrona (chamada ao Claude é síncrona no request), sem cron real
pra atribuição, `AnalisadorClaude` nunca chamou a API de verdade em nenhuma
sessão (sem `ANTHROPIC_API_KEY` no ambiente do agente — validar isso é o
próximo passo óbvio), sem notificação ao responsável quando cai em revisão
humana, sem o passo palavra-extraída→vira-conteúdo-de-vocabulário (de
propósito — precisa da mesma revisão humana que o plano exige pro vocabulário
base), e retenção/opt-out
contratual do provedor de LLM (R-RD-8/R-RD-9) não endereçados. Revisão do
dono ainda recomendada antes de qualquer envio real de criança passar pela
triagem de risco (R-RD-7) — `AnalisadorClaude` nunca rodou contra a API de
verdade.

---

## ▶️ Próximos passos (ordem sugerida)

**~~1. Redação real (Fase 4, app)~~ ✅ feita (25/08, sessão seguinte)** —
`app/lib/features/redacao/` consome `GET /v1/redacoes` + `POST
/v1/redacoes/{id}/enviar` + `GET /v1/redacoes/{id}/analise` de verdade.
**Só o caminho digitado** (decisão do dono): foto/manuscrita fica visível
mas desabilitada ("em breve") até o app integrar OCR on-device (ML Kit) —
ver "Antes de expor pra qualquer criança de verdade" abaixo, que segue
pendente. `flutter analyze` limpo, `flutter test` 26/26, 4 desfechos
verificados ao vivo no navegador (DEMO). Detalhe completo em
`design/notas-implementacao.md` § "Fase 4, app".

**~~1. Área do Responsável (Fase 5, app)~~ ✅ feita (25/08, sessão seguinte)**
— `app/lib/features/responsavel/` criado: portão PIN (`pin_gate_screen.dart`,
com "criar PIN"/"esqueci o PIN"), home com filhos + atalhos
(`responsavel_home_screen.dart`), resumo semanal por filho
(`resumo_screen.dart`) e exclusão de conta (`excluir_conta_screen.dart`).
**Achado importante:** como o `TokenStore` guarda só um token e não existe
endpoint pra trocar o token de criança de volta pro de responsável, a Área do
Responsável só é alcançável no Seletor de Perfil (mesmo lugar do Paywall) —
não "dentro do jogo" como o texto original do plano sugeria. Um atalho em
Configurações explica isso pro caso comum (app abrindo direto na Home da
criança). `flutter analyze` limpo, `flutter test` 26/26, 4 telas verificadas
ao vivo no navegador (DEMO). Detalhe completo em
`design/notas-implementacao.md` § "Fase 5, app".

**~~Verificação em Simulador iOS~~ ✅ feita (25/08, sessão seguinte)** —
Home, Redação (lista, envio digitado, resultado analisado com texto grifado,
resultado `erro_ingestao`) e o portão de PIN da Área do Responsável
navegados ao vivo em renderização nativa (iPhone 17 Pro, iOS 26.5), tudo
correto. Uma limitação da ferramenta de automação (não do app) impediu tocar
botões que ficam sob o teclado de software quando um campo de texto está
focado — o mesmo fluxo já tinha sido validado de ponta a ponta no navegador.
Detalhe em `design/notas-implementacao.md` § "Verificação em Simulador iOS".

**Trabalho de app pendente:** nenhum mapeado — Fases 4 e 5 do app estão
feitas, com verificação visual em navegador e simulador iOS.

**Antes de expor pra qualquer criança de verdade:** validar
`AnalisadorClaude` contra a API real (`ANTHROPIC_API_KEY`) — nunca rodou
nesta sessão, e a parte mais crítica de acertar (triagem de risco R-RD-7)
não foi verificada ao vivo.

**Sem código pendente, mas fora do escopo de app/backend:** retenção/opt-out
contratual do provedor de LLM (R-RD-8/R-RD-9), fila assíncrona real pro
pipeline de análise (pendência mantida em aberto por decisão do dono,
31/08/2026 — ver `design/notas-implementacao.md`).

---

## Estado anterior (24/08, pivô B2C — Fases 1–3 de `docs/produto/plano_b2c.md` feitas)

**Pivô B2C em andamento.** Produto saiu de venda por escola pra assinatura
direto pra família — decisão e racional completos em
`design/notas-implementacao.md` § "Pivô B2C" e `docs/produto/plano_b2c.md` (a fonte
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
- `docs/legado-b2b/rascunho_product.md`, `docs/legado-b2b/arquitetura.md`, `design/telas.md` e os
  briefs não foram reescritos por inteiro pro B2C (só ganharam nota de
  pré-pivô no topo) — onde contradizem `docs/produto/plano_b2c.md`, vale o plano.

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

## Próximos passos — histórico (pré-pivô B2C, 13/07)

> Obsoleto: turma+nome/PIN e a "fatia C do professor" descrevem o produto
> B2B, cujo código saiu do repo na Fase 6 (25/08) — ver "▶️ Próximos passos"
> no topo do arquivo para o que vale hoje.

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

## Superfície do Professor (web) — telas A–D completas [histórico — código removido na Fase 6, 25/08]

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
