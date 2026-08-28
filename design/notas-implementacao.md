# Notas de implementação — Flutter

Registro vivo do que **já foi feito**, do que ficou **adiado** (animações por
último, como combinado) e das **decisões/pendências de backend**. Atualizar a
cada tela implementada.

---

## ✅ Feito

### Home-hub (`features/home/`)
- Tela completa nos dois temas (claro "Azul Brilhante" / escuro "Capa do
  Passaporte") a partir do design system (`core/theme`).
- Componentes reutilizáveis: `SurfaceCard`, `ProgressBar`, `AppBottomNav`,
  `AppIcons`, tipografia `AppType`, tokens `AppColors`.
- Dados reais de `/me` + `/trilha` via `HomeMapper`; loading/erro/pull-to-refresh.

### Sessão (`features/sessao/`)
- 5 frames do design implementados como **uma tela com máquina de estados**
  (descoberta → questão → confirmar → feedback → continuar), claro e escuro.
- Componentes: `SessionTopBar` (progresso + combo + report), `DiscoveryCard`,
  `QuestionPanel`, `OptionTile` (neutro/selecionado/correto/erro), `FeedbackBar`,
  `ReportPopover`, `SessionCta`, `SessionBackground` (Fundo A + brilho radial).
- Tokens no `AppColors`: `error` (**vermelho** da resposta errada — ver decisão
  revisada abaixo), `warn` (âmbar de atenção gentil: prazos/validação/"em
  análise") e `accentInk` (texto sobre o chip de combo).
- Feedback de erro: a alternativa errada fica **vermelha com um "X"**; a faixa de
  feedback ("Quase! Vamos rever isso.") usa o ícone de **rever** (a questão volta
  ao fim da fila). A resposta certa **não** é revelada.
- Navegação: card "Continuar" e aba "Praticar" da Home abrem a Sessão.

### Onboarding (`features/onboarding/`)
- Fluxo em 5 passos (boas-vindas → como funciona → demonstração de acerto/erro →
  diagnóstico → primeira palavra), com progresso por pontos, "Pular" e CTA fixo.
- **Diagnóstico jogável (mock)** — `features/onboarding/diagnostico_data.dart`:
  o passo agora roda como mini-quiz (telas §2.3), percorrendo questões de
  exemplo uma a uma (barra de progresso fina, avança ao responder). Reaproveita
  `QuestionPanel`/`OptionTile` da Sessão; **não calcula nota nem revela a
  alternativa correta** (cliente fino) e fecha num cartão de "ponto de partida"
  sem nível numérico. As questões espelham o schema do backend
  (`QuestaoDiagnostico`) e cada uma carrega o `nivel` da escada grosso→fino,
  para o wiring futuro trocar só a fonte (`POST /v1/onboarding/diagnostico`).
  > ⚠️ **Conteúdo é exemplo, não validado.** A decisão do dono (12/06) foi
  > apresentá-lo **sem rótulo** na UI (parecer final) para a demo a escolas;
  > as perguntas ainda **precisam de revisão pedagógica** (professor) antes de
  > virarem conteúdo real. Esta nota é o registro honesto disso.
- Demo navegável: em `DEMO`, o app começa em **Entrada → Onboarding → Home**;
  "Embarcar" pula o backend e abre o onboarding com o nome digitado.

### Resumo de sessão (`features/resumo/`)
- Porte fiel do design `Resumo de sessão`, claro/escuro, com variante **com
  conquista** (teaser dourado "Novo no Passaporte!"). Card de XP em **vidro**.
- A Sessão aterrissa no Resumo ao fim (`pushReplacement`).

### Trilha (mapa) (`features/trilha/`)
- Porte da `Trilha v5 escuro · variação B` (carimbo champanhe). Profundidade por
  relevo (gradiente + sombras + aba inferior), taxonomia de nós
  (comum/medal/portão × done/atual/bloqueado), caminho percorrido vivo + futuro
  rebaixado, textura cartográfica, banhos de cor, fronteira única.
- Postal **embaçado** (reveal só no Passaporte). Decorativos em
  `widgets/trilha_tones.dart`.
- **Sem bob/flutuação contínua no nó atual** (decisão do dono, 11/06): nada
  fica quicando em loop; o destaque do nó atual é estático (maior + anel +
  halo). O que era "por ora" virou decisão.
- **Chegada ao nó (completar nó, 11/06)**: vindo do Resumo ("Ver trilha"), o
  último trecho verde **se desenha** (`PathMetric.extractPath`) com um
  marcador na ponta, o pin do nó atual **pipoca** (overshoot) com **confete**
  (`ConfettiBurst` compartilhado) e haptic leve, e o aside "Continuar" entra
  em fade — tudo **assenta estático** em ~1,5 s, não-bloqueante (o CTA já
  responde durante). Abrir a Trilha pela Home/nav fica 100% estático (a
  animação nem entra na árvore). Respeita reduce-motion. *Pendência de
  wiring*: com o backend, o gatilho real é "completou nó nesta sessão" — na
  demo, toda vinda do Resumo celebra.
- **Posições proporcionais** (10/06): o espaço lógico 340×540 virou referência —
  as posições dos nós escalam com a largura real (`LayoutBuilder`); rótulos e o
  aside "Continuar" clampam nas bordas em vez de recortar em telas estreitas.
- **Mapa vertical contínuo (decisão do dono, 13/07 — REVISA a "janela com
  template fixo" de 12/07)**: testando no aparelho, a navegação lateral
  (PageView + chevrons) pareceu errada — a progressão pedia um scroll
  **vertical, simples e contínuo**. A trilha inteira agora vive num canvas
  único (largura 340, altura calculada): a serpentina de 4 nós repete-se por
  destino de baixo para cima, com **portão + faixa de fronteira** entre
  países; a tela rola livremente (`SingleChildScrollView` reverso) e abre
  **centrada no nó atual**. Sem paginação nem chevrons; o carimbo do cabeçalho
  é o do **país atual do aluno** (fixo). `TrilhaMapper.janela` →
  `mapaCompleto`; `TrilhaMapData` ganhou `mapHeight` e `frontiers` (lista).
  Docs atualizados junto: `telas.md` §6 e `brief-mockup-trilha.md`.
- **Anel de progresso no nó atual (14/07)**: um nó leva 2–4 sessões (~4.500
  XP) e a aterrissagem pós-sessão é a Trilha — na maioria das sessões o mapa
  parecia idêntico, como se nada tivesse acontecido. O "anel" do nó atual
  (que era um halo sólido) agora é um **anel de progresso**: enche com o XP
  dentro do nó (`xp_inicio`→`xp_limiar` do `/v1/trilha`, que já existiam no
  contrato e o app ignorava). Anima 1× ao abrir (600 ms) e assenta estático
  (coerente com "sem flutuação contínua", 11/06); custo ~zero: um
  `CustomPainter` de dois arcos num único nó, `TweenAnimationBuilder` sem
  ticker residual. O limiar de 4.500 XP/nó **não muda** (cadência de
  colecionáveis calibrada para o ano letivo). `telas.md` §6 atualizado junto.
- **Saudação neutra no onboarding (13/07)**: "Bem-vindo(a)" tratava toda
  criança no masculino. Trocado por **"Olá, {nome}!"** (e "Olá! Todos a
  bordo!" sem nome) — neutro sem hífens nem "(a)".

### Perfil / Configurações (`features/identidade/`, `features/configuracoes/`)
- Perfil e Passaporte são **telas distintas** (produto §3.10): o Perfil é
  identidade/gerência; o Passaporte é coleção/celebração.
- **Cabeçalho do Perfil (decisão do dono, 14/06):** a engrenagem (⚙) no canto
  superior direito abre **Configurações**. Antes havia ali o livrinho do
  Passaporte **e** um botão "Configurações" no rodapé — redundante, porque o
  Passaporte já tem o atalho "Meu passaporte" no corpo (abaixo da carteira). O
  livro saiu do topo e o botão de rodapé foi **removido**; sobrou um caminho
  para cada coisa: engrenagem → Configurações, "Meu passaporte" → coleção.
  Ícone `AppIcons.ajustes` virou engrenagem (`settings_rounded`) — a mesma do
  cabeçalho das Configurações.

### Navegação da barra inferior — correções (14/06)
A barra (`AppBottomNav`) é compartilhada, mas Home/Trilha são **rotas
empilhadas** (cliente fino, Home é o hub). Dois bugs do dono, corrigidos:
- **Trilha → Perfil não abria:** a `onSelect` da Trilha só tratava Início e
  Praticar; a aba Perfil (índice 4) era ignorada. Agora empurra `PerfilScreen`,
  como na Home.
- **"Início" exigia dois toques após uma sessão:** o fluxo
  Home→Trilha→Sessão→Resumo→Trilha empilhava **duas** Trilhas, então o primeiro
  `pop` só revelava a Trilha de baixo (parecia "trocar e ficar na Trilha"). Duas
  defesas: (1) o Resumo agora vai à Trilha com `pushAndRemoveUntil` até a Home,
  removendo a Trilha intermediária (corrige também o "voltar" do sistema); (2) o
  "Início" da Trilha usa `popUntil` até a Home em vez de `pop` simples. A Home é
  **nomeada** (`HomeScreen.routeName`) porque no fluxo demo ela é empurrada após
  o onboarding e não é a rota raiz; em produção é a raiz (`isFirst`).

### Animações (10/06) — Sessão e Resumo
Todas curtas e **não-bloqueantes** (princípio 3.7), só com APIs nativas do
Flutter (nenhuma dependência nova; dados mockados como antes):
- **Acerto**: confete agora é um **burst animado** (~800 ms, `CustomPainter`
  em `OptionTile`, cores dos tokens) + pop do chip **+XP** na `FeedbackBar` +
  **pulso do combo** no `SessionTopBar` (e o chip entra/sai com scale+fade).
- **Erro**: **shake gentil** da alternativa errada (amplitude ~4 px, sem flash)
  + ícone X "pipocando" + transição suave da borda (`AnimatedContainer`) —
  mantém o vermelho suavizado, nada punitivo.
- **Sessão**: **slide/fade entre passos** (`AnimatedSwitcher`; responder a
  mesma questão não transiciona — o feedback entra deslizando de baixo) e
  **barra de progresso enchendo** animada (no `ProgressBar` compartilhado:
  anima só mudanças de valor, o primeiro build pinta direto).
- **Entrada do card de descoberta**: coberta pela mesma transição entre passos.
- **Resumo**: número-herói com **count-up** (0 → +480 XP), barra de nível
  **enchendo** com o contador `3.120 → 3.600` acompanhando, pop do chip de
  combo e **entrada escalonada** das seções (cabeçalho → XP → conquista →
  palavras). CTA "Ver trilha" responde desde o primeiro frame.
- Novo widget compartilhado `core/widgets/entrance.dart` (`Entrance`: fade +
  deslize + escala opcional, com `delay` para stagger; roda uma vez).
- Confete extraído para `core/widgets/confetti_burst.dart` (11/06) —
  compartilhado entre o acerto da Sessão e a chegada ao nó da Trilha.
- **Onboarding — demo roteirizada (10/06)**: o passo de demonstração deixou de
  ser estático e virou o roteiro do produto 3.5 (Demo A/B): seleciona e
  **acerta** (confete + faixa com +100 XP), depois seleciona e **erra** (shake
  + faixa gentil "a pergunta volta") — reusando `OptionTile` e `FeedbackBar`
  reais da Sessão, sem componente novo. Revisitar o passo refaz o filme.

### Passaporte — Modo Conquista (10/06) — `conquista_screen.dart`
Implementa o reveal de `telas.md` §7, fiel ao contrato e fora da tela
scrollável (decisão deliberada: animar dentro do `JournalView` repintaria os
vidros a cada frame e o item ficaria pequeno; a tela dedicada anima **um**
item com transforms sob `RepaintBoundary`, sem `BackdropFilter`):
- O passaporte **sobe** em tela cheia (rota custom deslizando de baixo) →
  **flip decorativo único** da capa (rotateY com perspectiva + mergulho de
  escala) → abre **direto na página do item**.
- **Cartão-postal**: polaroid grande **embaçada** ("toque para revelar"
  pulsando) → toque revela **nítido** (overlay de blur com sigma fixo, só a
  opacidade anima, e sai da árvore ao terminar) + brilhos dourados
  (`_Sparkles`) + **encaixa** com leve inclinação; legenda `? ? ?` → cidade.
- **Selo**: grid com os antigos estáticos; o novo **cai** (bounce) sobre a
  silhueta pontilhada, **pulsa e encaixa** (amostra `Conquista.sampleSelo`,
  ainda não wireada no fluxo).
- Fluxo: teaser do Resumo (CTA dourado, agora funcional) → Conquista →
  "Ver no Passaporte" aterrissa no **Modo Exploração** com a peça guardada;
  "Voltar ao resumo"/X nunca prendem o aluno (não-bloqueante).
- **Disparo + fila (decisão revisada 11/06, com o dono):** o reveal dispara
  pelo **teaser do Resumo** (atalho "Ver no Passaporte") **ou**, se o aluno não
  tocar, ao **abrir o Passaporte** — `ConquistaQueue` (singleton, em memória)
  guarda as pendências e o `PassaporteScreen` as drena no `initState`
  (post-frame), tocando **uma de cada vez** ("Próxima lembrança" entre elas).
  Cada item sai da fila ao ser revelado, então os dois caminhos não duplicam.
  `telas.md` §5/§7 atualizados no mesmo commit. *Não-automático após o resumo*
  de propósito (não atropelar a leitura). A fila em memória cobre "várias
  sessões na mesma execução"; a **fonte de verdade real é o servidor** (cliente
  fino) — `GET /v1/passaporte` traz os novos, `POST` marca vistos; o store só
  espelha. Custo: a fila não soma render (um item anima por vez).
- **Reduce-motion**: respeita `MediaQuery.disableAnimations` — mostra os itens
  já revelados, sem flip/blur/sparkle (acessibilidade e aparelho fraco).
- Demo: o fim de sessão agora usa `SessionSummary.sampleWithAchievement` e
  **enfileira** a conquista, exercitando os dois caminhos (teaser e fila).
- Modelo novo `Conquista` (`ConquistaPostal`/`ConquistaSelo`) em
  `passaporte/models.dart`; com o backend, virá em `POST /v1/sessoes/{id}/fim`.

### Design system
- Token **`glass`** (claro = vidro fosco; escuro = painel opaco): `SurfaceCard` e
  a bottom nav desfocam o fundo. `paper` segue opaco (menus/popovers/alternativas).
- `core/widgets/primary_button.dart` (`PrimaryButton`) — CTA primário compartilhado.
- `core/format.dart` (`milhar`).
- **Dependências com versão exata** no `pubspec.yaml` (10/06) — `pub get` em
  ambiente novo já quebrou o build resolvendo versões diferentes (caso
  `valueOrNull`/riverpod). Atualizar dep agora é PR deliberado (yaml + lock).
- **`CLAUDE.md`** na raiz (10/06): mapa dos documentos + regra das decisões
  revisadas (doc contratual atualiza no mesmo commit) + decisões que não mudam.

> ✅ **Bloqueio de build resolvido:** `home_providers.dart` usa `.value` (o
> `.valueOrNull` saiu no riverpod 3) e as dependências agora são exatas no
> `pubspec.yaml` (10/06) — o caso não se repete. Pendência que restou: telas de
> Resumo/Trilha ainda **não verificadas visualmente** (fazer no `flutter run`).

---

## 🧑‍🏫 Professor (web) — decisão de plataforma e plano (15/06)

Até aqui o desenvolvimento focou **só no aluno**. A superfície do
professor/coordenação (quem assina) ainda não existia. Decisões tomadas com o
dono (15/06):

### Plataforma: web-first, entrypoint separado (não pesa no app do aluno)
- O professor vira um **segundo entrypoint Flutter** (`app/lib/main_professor.dart`)
  no **mesmo projeto**, compilado pra **web** (`flutter build web -t
  lib/main_professor.dart`). Mesmo código, mesmo design system, build separado.
- **Por que web e não dentro do app do aluno:** o trabalho do professor é de tela
  grande (tabelas, dashboards, revisão de redação) e o comprador vê a demo no
  laptop. **Mobile do professor fica deferido até validar com as escolas** — a
  arquitetura compartilhada permite compilar pra mobile depois sem reescrever.
- **Garantia de "zero peso" no app do aluno** por duas regras de import, com
  **teste de guard** (`app/test/arquitetura_professor_test.dart`) que falha o
  `flutter test` se violadas:
  - **R1:** `main.dart`/`features/<aluno>` **nunca** importam `features/professor/`
    → tree-shaking do compilador Dart remove o professor do APK/IPA do aluno.
  - **R2:** `features/professor/` importa **só** `core/` + a própria subárvore.

### Escopo da demo: A + B + C + D (E/F deferidos)
- **A** Painel da turma (+ **toggle de escopo** turma↔escola: mostra a visão do
  coordenador e **esconde "configurar"** — ver≠configurar, produto §3.11).
- **B** Detalhe do aluno (drill-down).
- **C** Configurar meta semanal (produto §3.5).
- **D** Atribuir redação (tema+prazo, produto §4.6) — **fecha o loop** com a demo
  do aluno (redação→vocabulário).
- **Deferidos** (fast-follow pós-feedback): **E** (redações da turma agregadas por
  dimensão), **F** (preset de rigor §4.3).
- **Coordenador não é tela separada** (produto §3.11): mesmos dashboards, escopo
  escola, view-only → resolvido pelo toggle de escopo.

### Backend: domínio `professor` (mock fatia A)
- Criar `backend/app/professor/routes.py` (mock) e **mover** pra lá o
  `GET /v1/dashboard` hoje mal-alocado em `redacao/routes.py` (o app não consome
  ainda → migração segura; redação volta a tratar só de redação).
- Rotas (shapes espelham `arquitetura.md`: `associacao_turma`, `redacao_atribuicao`
  "C (mock em A)", `turma_config`): `GET /professor/turmas`,
  `/professor/turmas/{id}/alunos`, `/professor/alunos/{id}`, `/professor/escola`,
  `POST /professor/turmas/{id}/redacoes`, `PUT /professor/turmas/{id}/meta`.

### Fases (cada fase = commit; docs contratuais no mesmo commit)
- ✅ **0** Scaffolding + shell responsivo + teste de guard R1/R2 (roda em `*.sample`).
- ✅ **1** Backend mock (`app/professor/`, move o `/dashboard` de `redacao`) +
  DTOs/repositório/mapper; `apiClient`/`tokenStore` promovidos a `core/api_providers.dart`
  (re-exportados pela identidade); `painelDataProvider` busca o backend fora do `DEMO`.
  Testes: `tests/test_professor.py` (backend) + `professor_mapper_test.dart` (app).
- ✅ **2** Painel + **toggle de escopo** (turma↔escola): escola é só leitura e
  **esconde as ações de configurar**; clicar numa turma no escopo escola faz
  **drill** para o painel da turma. Seletor de turma no escopo professor.
  Endpoint `GET /v1/professor/escola` + `EscolaPainelData`/mapper/teste.
- ✅ **3** Detalhe do aluno (drill-down do painel, **só leitura** — §3.11): meta
  da semana, palavras dominadas/em progresso (counters), vocabulário recente
  (estado + **origem**, que evidencia o loop redação→vocabulário) e redações do
  aluno. Tocar num aluno no painel **empurra** a página (volta com "Voltar ao
  painel"); o nome chega pelo construtor (cabeçalho sem flash). Endpoint
  `GET /v1/professor/alunos/{id}` (base do painel = fonte única; só o extra é
  novo) + `AlunoDetalhe`/DTOs/mapper/provider `family`. Counters, não % de acerto
  nem tempo (decisões de produto). De passagem: `test_jornada` apontava para o
  `/dashboard` movido na fase 1 → corrigido para `/professor/turmas/{id}/painel`.
- ✅ **4** Atribuir redação (ação **só do professor** — §3.11/§4.6): tela
  empurrada com **tema** (obrigatório) + **prazo** (opcional, date picker);
  `POST /v1/professor/turmas/{id}/redacoes` (mock; 404 turma inexistente, 422
  tema vazio/prazo não-ISO — o backend valida e faz `strip`). Mutação via
  `AtribuirRedacaoController` (`AsyncNotifier`, mesmo padrão do `AuthController`;
  DEMO simula o sucesso sem backend). Volta com `Navigator.pop(atribuição)` e o
  painel confirma por SnackBar. `PainelData` ganhou `turma_id` (DTO já trazia)
  para a ação saber a turma; `ProfessorBackBar` extraído p/ reuso com a fase 3.
- ✅ **5** Meta semanal (ação **só do professor** — §3.11/§3.5): tela empurrada
  com stepper (1–30), pré-preenchida com a meta atual; `PUT /v1/professor/turmas/{id}/meta`
  (mock; 404 turma, 422 fora de 1–50). Mutação via `MetaController` (`AsyncNotifier`).
  Como a demo roda em `DEMO` (sem backend) e a meta **aparece no painel**, o sucesso
  registra um **override otimista** (`metaOverridesProvider`) e o `painelTurmaProvider`
  reaplica via `PainelData.comMeta` (KPI + meta de cada aluno; frações derivadas
  acompanham) — na fatia C o valor vem persistido do servidor. `ApiClient` ganhou
  `put`. Encerra as ações de configurar do painel.
- 🔶 **6** Higiene: HANDOFF atualizado + auditoria estática (zero cor hardcoded
  em `features/professor/`, R1/R2 ok, lints). **Falta a verificação visual
  claro/escuro** no Chrome (incl. `showDatePicker` e stepper) — não roda em
  ambiente headless/sem SDK Flutter; comandos no HANDOFF.

### Notas técnicas (web)
- Professor **não** usa haptics (no-op na web) nem `image_picker` (atribui, não
  envia) — confirma a separação de deps.
- Google Fonts busca fontes em runtime na web → **recomendado empacotar as 4
  famílias como assets** antes do pitch (wifi de escola instável); passo
  deliberado, beneficia o app do aluno também.

---

## ⏳ A fazer (adiado de propósito)

### Áudio
- [x] **TTS de pronúncia — FORA do MVP** (decisão do dono, 11/06; vale para o
      apresentável e o completo): exigiria áudio para cada palavra do banco
      (asset por palavra ou requisição de TTS a cada palavra nova). O botão de
      alto-falante foi **removido** do `DiscoveryCard` (sem botão morto na
      demo); `audio_url` segue nullable no modelo, reservado pós-MVP. Docs
      atualizados no mesmo commit (`telas.md` §4, brief da Sessão,
      `rascunho_product.md`, `arquitetura.md`).

### Interação
- [ ] **Tocar na palavra marcada** (enunciado/exemplo) reabrir o card de
      descoberta sem sair da questão. Hoje só o sublinhado pontilhado afoorda.
- [x] **Card reaberto no 2º erro da palavra** (10/06): a Sessão reapresenta o
      card de descoberta automaticamente após o 2º erro acumulado da mesma
      palavra, antes de seguir — sem revelar a resposta ("errar é aprender").
      Com o backend, o gatilho vem de `tentativas` da `RespostaOut`.
- [ ] **Selos pontilhados** do `QuestionPanel` são círculos sólidos translúcidos
      (aproximação). Dashed real exige `CustomPainter` — cosmético.

---

## 🔌 Wiring app ↔ backend — Sessão server-side (05/07)

A Sessão do aluno agora consome o backend de verdade (fora de `DEMO`), no
mesmo padrão da Home: **DTOs → `SessaoMapper` → `SessaoController`
(AsyncNotifier)**; a tela guarda só estado efêmero (seleção, popover).

- [x] `POST /v1/sessoes` — fila em lote na abertura; em paralelo, `GET
      /v1/trilha` captura o contexto do Resumo (cidade/lição/teto de XP do nó
      **jogado**, mesmo que um nó seja cruzado no meio).
- [x] `POST /v1/sessoes/{id}/respostas` — correção server-side; o app rende a
      `fila` devolvida (re-queue do erro incluído — **nada** da regra vive no
      Dart). Trava anti toque-duplo enquanto a resposta viaja.
- [x] `POST /v1/sessoes/{id}/fim` — fecha e monta o Resumo com números do
      servidor; progresso por palavra acumulado das respostas
      (`estado_palavra`/`dominou` — apresentação, não cálculo).
- [x] `POST /v1/questoes/{id}/report` — popover ligado (melhor esforço; os
      rótulos do brief mapeiam para o enum do contrato, "erro de digitação" cai
      em `outro`).
- [x] **Backend:** `QuestaoSlot` ganhou `lema` (aditivo) — o app destaca a
      palavra no enunciado, reabre o card no 2º erro e rotula o Resumo (palavra
      de revisão não tem card na fila).
- [x] Recompensas de `respostas` → `ConquistaQueue` (cartão-postal resolvido
      pelo snapshot da trilha) + teaser no Resumo.
- [x] Erros com recuperação: falha de rede mantém a seleção e deixa tentar de
      novo; `409` na resposta = sessão dessincronizada → abre sessão nova;
      `409 sessao_encerrada` no `/fim` = já fechou → volta à origem.
- [ ] **Card de revisão para palavra de revisão** (sem card na fila): buscar
      via `GET /v1/palavras/{id}` no 2º erro — hoje o interstício simplesmente
      não abre (paridade com a demo).
- [ ] **Resiliência offline fina** (re-sync via `GET /proximo` após resposta
      perdida) — hoje a saída é sessão nova via 409, sem perder progresso salvo.
- [ ] **Classe gramatical** no card de descoberta: o banco base não a expõe —
      a linha fica oculta (`partOfSpeech` nulo). Adicionar ao conteúdo depois.

## 🔌 Wiring app ↔ backend — Passaporte + Modo Conquista (06/07)

O Passaporte agora é a coleção real do aluno, e a fila de reveals é
**persistida no servidor** (fecha o app, volta amanhã, o reveal ainda toca).

- [x] **Backend:** `aluno_colecionavel.revelado_em` (migration linear) +
      `revelado` no `ItemPassaporteOut` + `POST /v1/passaporte/{id}/revelado`
      (idempotente). `RecompensaOut` ganhou `colecionavel_id` para o app
      persistir o reveal vindo do teaser do Resumo.
- [x] **Coleção real:** `PassaporteMapper` monta capa/países/selos de
      `/me` + `/trilha` + `/passaporte` (nomes de cidade/país da trilha;
      título/descrição/ícone dos selos são **catálogo do cliente**).
- [x] **Fila de conquistas espelhando o servidor:** pendente =
      `conquistado && !revelado`, em ordem de ganho; ao abrir o Passaporte a
      fila local é **substituída** pela do servidor (dedupe por definição).
      Cada reveal dispara `POST /revelado` (melhor esforço — reveal nunca
      trava por rede; falha rara = repete na próxima abertura).
- [x] **Reveal de carimbo** (decisão 06/07): variante nova no Modo Conquista
      **compondo peças travadas** (widget `Carimbo` da coleção + a mesma
      coreografia blur→brilhos→encaixe do postal). Selo já tinha grid; agora
      entra pela fila do Passaporte (o grid precisa da coleção).
- [x] **Celebração real na Trilha:** `SessionSummary.noCompletado` (XP da
      sessão cruzou o teto do nó) → o Resumo só passa `celebrarChegada`
      quando o nó de fato fechou (antes: sempre, por demo).
- [x] **Mapa da Trilha com dados reais — janela com template fixo (decisão
      do dono, 12/07).** Os 20 destinos/80 nós **não** ganham layout
      procedural: o template travado (340×540) é reutilizado **por destino**
      — a "câmera" enquadra uma janela e swipe/chevrons (ao lado do carimbo
      do país) trocam de destino; abre na janela do nó atual. Gramática da
      janela (de baixo p/ cima): âncora (início ou marco do destino
      anterior) → nós 1..3 (fichas comuns) → nó 4 = **marco** (medalhão do
      destino) → prévia do próximo destino, ou **portão + fronteira** quando
      o destino fecha o país. `TrilhaMapper` (puro, com testes) traduz
      `/v1/trilha`; `trilhaProvider` (autoDispose) refaz o GET a cada volta.
      Ajustes no widget: aside "Continuar" segue o flag `cta` (o nó atual
      real pode ser comum, não só medal) e muda de lado quando falta espaço;
      o painter aceita janelas sem nó atual (passado/futuro). O medidor do
      `CountryStamp` virou o `ProgressBar` do core (o artesanal colapsava a
      altura e nunca pintava). Docs atualizados juntos: `design/telas.md`
      §6 e `design/brief-mockup-trilha.md`.
- [x] **Diagnóstico do onboarding real (12/07).** Aluno **novo** (`novo` do
      `/acesso/turma`) entra pelo gate (`main.dart:_Gate`) no Onboarding antes
      da Home, via `onboardingPendenteProvider` (estado de sessão de app, não
      persiste — quem fecha o app no meio começa no nível padrão e a adaptação
      corrige). O passo 4 (`_DiagnosticoReal` em `onboarding_screen.dart`)
      dialoga com `POST /v1/onboarding/diagnostico` via `DiagnosticoController`
      (`AsyncNotifier` autoDispose): o `estado` da escada é **opaco** — o app
      reenvia verbatim; correção e nível são do servidor. DTOs em
      `onboarding/data/`. As questões de `diagnostico_data.dart` ficam só p/
      o `DEMO`. Verificado: escada subiu com acertos → `nivel=9` persistido.
- [ ] **Badge "novidades" no avatar** (Home) via `ConquistaQueue.listenable` —
      opcional, pós-feedback.

### Home — campos ainda não expostos pela API (ver `HomeMapper`)
- [ ] **Meta semanal** (palavras dominadas/semana) — placeholder 6/10. A meta
      real vem de `turma_config.meta_semanal` (professor configura; default por
      ano se nula). Ao definir os defaults, simular contra o ritmo real
      (2 palavras novas/sessão, domínio em ~3+ sessões) para ser batível.
- [ ] **Arte por destino** na `/v1/trilha` (asset_ref) — o app resolve por
      nome (`HomeMapper.assetParaCidade`); assets WebP empacotados para os
      5 destinos do Brasil + Paris (14/07); faltam os demais da França e o
      Japão.

---

## 🔐 Trio de segurança pré-piloto (13/07)

Fecha o bloqueante nº 1 do HANDOFF (auth provisória sem defesas). Nada de
produto/design mudou — é o plug da auth real previsto pela arquitetura
(auth-agnóstica, §3.11).

- **JWT assinado (HS256) com expiração** substitui o `prov_<id>`:
  `app/identidade/auth.py` (único módulo trocado, como desenhado). Claims
  `sub`/`papel`/`iat`/`exp`; algoritmo fixado na validação; papel de
  **autorização vem do banco**, não do token. Exige `JWT_SECRET` no ambiente
  (`openssl rand -hex 32`); TTL default 30 dias (`JWT_TTL_HORAS`). Tokens
  antigos caem no 401 e o app pede novo acesso.
- **Papel nas rotas do professor** (`require_papel`): leitura exige
  professor/coordenador; meta e atribuição de redação, só professor
  (coordenador é leitura, §3.11). Aluno leva 403 `sem_permissao`. O seed criou
  a "Professora Demo" e `python -m app.seed` imprime um token dela (login de
  professor de verdade é fatia C, junto com o escopo por associação).
- **Rate limiting** em memória (`app/seguranca/rate_limit.py`, regra pura):
  janela de 60s; login por IP (freia brute-force de código de turma e criação
  de contas), rotas autenticadas por token (não por IP — turma inteira atrás
  do NAT da escola), resto por IP. 429 no envelope único + `Retry-After`.
- **CORS explícito** (`CORS_ORIGINS`, nunca `*`): camada mais externa —
  preflight não toca banco. Sem origem configurada, nada liberado (mobile não
  precisa de CORS; o site do professor entra quando publicado).
- **App**: token migrou de `SharedPreferences` para `flutter_secure_storage`
  10.3.1 (keychain/keystore; resíduo antigo é limpo). `api_client.dart` não
  vaza mais `FormatException` em resposta não-JSON (502 de proxy →
  `ApiException` código `resposta_invalida`).
- **Envelope de erro**: mocks de professor/redação trocaram `HTTPException`
  por `ApiError` (códigos de domínio: `turma_nao_encontrada`,
  `aluno_nao_encontrado`, `redacao_nao_encontrada`).

Pendências que continuam mapeadas (não regridem): escopo por associação e
login do professor (fatia C), PIN por aluno (entrar na conta de outro pelo
nome continua possível — decisão de produto pendente), LGPD/consentimento.

---

## 🧑‍🏫 Fatia C do professor — dados reais + escopo (13/07)

Os mocks de `app/professor/` viraram queries reais, **sem mudar contrato nem
app** (o campo `mock` agora é sempre `false`). Estrutura padrão do domínio
(rotas → serviço → repositório). Decisões desta fatia (com data):

- **Semana da meta = segunda-feira 00:00 em America/Sao_Paulo**
  (`progressao/semana.py`, regra pura). Aluno (Home via `/me`) e professor
  (painel) leem o mesmo corte e o mesmo número.
- **Meta default por ano** quando `turma_config.meta_semanal` é nula
  (`progressao/meta.py`): 6º=4 · 7º=5 · 8º=6 · 9º=7 (fallback 5). Valores
  **provisórios** (rampa que espelha a demo) — calibração pedagógica pendente:
  simular contra o ritmo real (2 palavras novas/sessão, domínio em ~3+
  sessões) antes do piloto.
- **"Aluno ativo" = teve sessão iniciada na semana corrente** (KPI do painel).
- **Status de redação na visão do professor**: sem envio → `pendente`;
  `analisada` → `analisada`; o resto (`enviada`/`processando`/`erro_*`) →
  `em_analise` (erro de pipeline é reprocesso interno, não estado que o
  professor resolva).
- **Escopo por associação (§3.11)**: professor enxerga/configura só as turmas
  de `associacao_turma`; coordenador enxerga a escola inteira, só leitura;
  fora do alcance → 403 `sem_permissao`. `/professor/escola` é o agregado da
  própria escola (professor acessa pelo toggle turma↔escola).
- **Persistência real**: `PUT meta` faz upsert em `turma_config`; `POST
  redacoes` grava `redacao_atribuicao` com o professor autor. **Sinal de
  turma** lê a tabela `sinal_turma` de verdade — vazia até o pipeline de
  redação (fatia C de redação) rodar o job periódico.
- **`/v1/me` ganhou `meta_semanal` {atual, alvo}** (aditivo). No app, o
  `HomeMapper` trocou o placeholder fixo "6/10" pelo dado real (fallback 0/5
  só se o aluno não tiver turma).
- **Login do professor ficou de fora** (decisão do dono, 13/07): o fluxo
  definitivo (SSO/magic link, produto §11) é da janela do 1º cliente. O site
  do professor segue em `DEMO`; para exercitar o backend real, o token sai de
  `python -m app.seed`.

Deferidos desta superfície (sem mudança): redações agregadas por dimensão e
preset de rigor (§4.3) — fast-follow pós-feedback.

---

## 🛡️ Integridade do gameplay — guardas no `responder` (13/07)

Fecha os dois furos do princípio "servidor autoritativo" mapeados no HANDOFF
(um cliente adulterado podia responder qualquer questão ativa e dominar
palavras na hora, farmando o bônus de +500). Só `app/sessao/service.py`
mudou; nenhum contrato nem comportamento do app honesto foi alterado.

- **Questão tem que ter sido apresentada** → senão 409
  `questao_fora_da_sessao`. A regra **não** é "está na fila": quando o aluno
  erra, a intercalação troca o slot por outra variação, e o fluxo legítimo de
  acertar na 2ª tentativa responde uma questão que já saiu da fila. A regra é
  "está na fila **ou** já tem tentativa registrada em `aluno_questao`".
- **N4 só vale vencido** → senão 409 `nivel4_nao_vencido`
  (`nivel4_agendado_para` nulo ou > `sessoes_total`). A montagem já só põe N4
  vencido na fila; a guarda é a segunda camada, no ponto que concede o bônus.
- Ordem das checagens preservada: os erros existentes
  (`questao_nao_encontrada`, `opcao_invalida`, `palavra_nao_atribuida`,
  `questao_ja_respondida`) continuam saindo antes das guardas novas.

---

## 📱 Sensação de plataforma (camada adaptativa)

Decisão: **manter o design system da marca** (neutro) e adaptar só os "tells" de
plataforma — **não** migrar para Cupertino puro. Centralizado em
`core/platform/adaptive.dart`.

- [x] **Toque sem ripple no iOS** — `adaptiveSplashFactory` no tema (`AppTheme`):
      ripple no Android, realce/fade no iOS. Vale para toda a árvore de uma vez.
- [x] **Transição com swipe-back no iOS** — `adaptivePageRoute` (Cupertino no
      iOS/macOS, Material no resto). Usado ao abrir a Sessão.
- [x] **Spinner adaptativo** — `CircularProgressIndicator.adaptive` na Home.
- [x] **Haptics** — `selectionClick` (seleção de alternativa, navegação) e
      `lightImpact` (CTAs da Sessão).
- [ ] **Pull-to-refresh** ainda é o `RefreshIndicator` Material. iOS nativo
      (`CupertinoSliverRefreshControl`) exige migrar a Home para slivers — adiado.
- [ ] **Press estilo iOS exato** (fade de opacidade no controle inteiro, à la
      `CupertinoButton`): hoje usamos realce do InkWell. Se quiser idêntico,
      criar um `Pressable` custom — opcional.

---

## 🎨 Decisões de design fixadas
- Paleta: **escuro travado** (navy `#172A44`/dourado champanhe). O **claro**
  (`#1E7FD6`/areia) é a direção vigente, mas **admite ajustes finos** (dono,
  10/06) — tons ainda não totalmente definidos.
- **Contraste mínimo = critério de aceite** da paleta (10/06): texto de corpo
  ≥ 4.5:1 (AA), texto grande/display ≥ 3:1. Aplicado: `muted` do claro
  escurecido `#9C8C7D` → `#7A6B5C` (o anterior dava ~3:1 sobre o fundo areia).
  Ouro/`accent` não deve ser usado como texto pequeno sobre papel.
- **Erro de resposta = vermelho suavizado** (decisão revisada pelo dono;
  refinada 10/06 no padrão Duolingo): alternativa errada com **fundo em tint
  ~12% do vermelho + borda/texto/"X" no token `error`** (`#D23F34` claro /
  `#E8736A` escuro) — nunca vermelho puro nem flash de tela. O aluno enxerga
  com clareza que errou, sem tom punitivo. O âmbar (`warn`) vale só para
  **atenção gentil** (prazos de redação, validação de formulário, status "em
  análise") — não para o erro de resposta. (O `OptionTile` já implementa esse
  padrão.)
- **Combo é por sessão** (decidido 10/06): zera ao iniciar cada sessão (além de
  ao errar/2ª tentativa); não carrega entre sessões — `combo_data` removido do
  modelo (`docs/legado-b2b/arquitetura.md`).
- **Trilha sem selo "você está aqui"** (decisão revisada): o nó atual em
  destaque + caminho percorrido já comunicam a posição.
- Sem streak diário, meta diária, mascote, % de acerto ou tempo (produto).
- Fontes: Fredoka (display) · Nunito (corpo) · Caveat (só "Passaporte") ·
  Space Mono (micro-rótulos).

---

## ▶️ Próximo passo sugerido
**Wiring do aluno COMPLETO (12/07):** Sessão (05/07), Passaporte (06/07),
Trilha (12/07 — janela com template fixo) e **diagnóstico do onboarding
(12/07)**. O diagnóstico real: aluno **novo** (`novo` do `/acesso/turma`)
entra pelo gate no Onboarding; o passo 4 dialoga com
`POST /v1/onboarding/diagnostico` via `DiagnosticoController` (estado da
escada é **opaco** — o app reenvia verbatim; correção e nível são do
servidor). "Pular"/concluir desligam a pendência da sessão de app (não
persiste de propósito: fechar o app no meio deixa o nível padrão e a
adaptação corrige — filosofia "diagnóstico leve + adaptação forte").
Verificado em runtime: aluno novo → escada subiu com acertos →
`nivel_dificuldade_atual: 9` persistido → Home. Na sequência: **fatia C**
do professor (persistir meta/atribuição, exigir papel+escopo) e o trio de
segurança (auth real, rate limiting, CORS). TTS fora do MVP (11/06).

> **Diagnóstico (conteúdo) — decisão do dono (12/07, afinada 13/07):** a
> **revisão pedagógica** das questões e a **calibração** da escada (limiares de
> subir/descer, níveis default por ano, dificuldade das palavras) **só serão
> feitas quando estivermos em contato com as escolas** — não antes. As questões
> do seed seguem como conteúdo de exemplo válido para demo; a calibração sai
> com o retorno pedagógico do 1º cliente.

> **Seed de palavras — feito (13/07, noite):** expandido de 8 → **37 palavras**,
> níveis 1–10 (3–4 por nível; antes faltavam 1, 8, 9, 10). Resolve o gargalo da
> 2ª sessão e dá conteúdo para o diagnóstico exercitar a escada inteira.
> Reprodutível entre máquinas por construção (seed versionado + idempotente por
> `lema`). Segue reduzido frente às 500–800 de produção (Bloco 3).

---

## 🧭 Decisões de produto — pré-piloto (13/07, noite)

Três pendências destravadas em conversa com o dono. Duas mantêm o status quo
(sem mudança de contrato); a terceira é uma **direção**, ainda **não travada**
(spec pendente de resolver a tensão abaixo — por isso `telas.md`/briefs/
`arquitetura.md` **não** foram editados ainda; entram no commit que fechar a
spec, conforme a regra das decisões revisadas).

- **Login do aluno — manter SEM PIN no piloto.** Aceita-se o risco de
  impersonação (entrar na conta de um colega da mesma turma) para não adicionar
  atrito à criança; o foco do piloto é validar o produto, não a segurança da
  conta. Rate limiting só freia força bruta, não impersonação. Reavaliar com o
  feedback do piloto (PIN de 4 dígitos ou senha-imagem são os candidatos).
- **Login do professor — decidir só com a escola cliente.** Segue em `DEMO`/
  token do seed até conhecer a infra do 1º cliente (Google Workspace é comum →
  SSO seria natural; magic link é o plano B sem depender da escola). Sem
  trabalho de código até lá.
- **LGPD / nomes de crianças — DIREÇÃO: pseudonimizar por apelido/avatar (sem
  nome real).** Minimiza dado pessoal de menor (a melhor postura para o piloto).
  A tensão "como a professora liga o apelido à criança real" (o painel hoje
  identifica alunos por `nome`, `professor/repository.py`) resolve-se por
  **pré-cadastro da turma pela professora** (apelido ↔ nome real no painel; o
  mapa vive no app sob controle da escola). **Faseado (dono, 13/07):**
  - **Agora (fase de testes):** mantém o fluxo **self-service atual** — o aluno
    entra digitando **apelido + código da turma** (o "acha-ou-cria por nome" de
    `acesso/turma` continua, só que o campo é um apelido, não o nome real).
    Motivo: pré-cadastrar cada aluno agora tornaria cada teste um cadastro —
    péssimo para iterar. **Nenhuma mudança de código nesta fase.**
  - **Depois:** professora **pré-cadastra** a turma (apelido ↔ nome); o
    acesso deixa de criar aluno na hora e passa a casar com a lista. Aí sim
    entram as mudanças contratuais, num commit com docs juntos: `acesso/turma`,
    modelo (`usuario`), painel (identificação), `telas.md` e briefs.
  - Recomendação de baixo custo para a própria fase de testes ficar limpa de
    dado real: rotular o campo de acesso como **"apelido"** (não "nome") no app
    e nos textos — pendente da sua confirmação (é a única mudança pequena que
    valeria já; não fiz para não mexer no que você testa sem combinar).

---

## 🎬 Apresentação em 5–10 min — alunos "vitrine" no backend real (15/07)

**Problema:** demonstrando com o backend real (o caminho de produção), um
aluno novo não cruza XP suficiente em 5–10 min para mostrar cartão postal,
carimbo, dois países ou o Modo Conquista. E o modo `DEMO` do app do aluno
ficou defasado (mapa/movimentação atrás do backend real).

**Decisão (dono pediu "o que for melhor para apresentar"):**

- **Novo `backend/app/seed_demo.py`** cria dois alunos na turma DEMO7A com
  progresso rico, usando a **própria lógica de produção**
  (`trilha.service.processar_recompensas`) — o seed define o XP alvo e as
  recompensas saem das mesmas regras do jogo, então não há estado inventado
  que possa divergir quando as regras mudarem:
  - **"Ana Viajante"** — Brasil concluído + 2 destinos da França (XP 128.600):
    5 cartões BR + carimbo BR + 2 cartões FR + selos `combo_10` e
    `dominadas_25`; 3 palavras dominadas na semana corrente (Home mostra 3/5
    da meta); o cartão de Mont-Saint-Michel fica **ganho e não revelado** —
    o Modo Conquista dispara ao vivo ao abrir o Passaporte.
  - **"Beto Explorador"** — meio da jornada (Rio + Foz, XP 37.800), 2 cartões.
  - Ambos jogam **sessão real** na hora (palavras em nivel_2/3 alimentam a
    revisão; sobram palavras do banco base para as novas).
- **Idempotente e restaurador:** re-rodar (`uv run python -m app.seed_demo`)
  devolve as personas ao estado alvo — rearmar a vitrine entre apresentações
  leva segundos. Testes em `tests/test_seed_demo.py` (suíte 110/110).
- **Roteiro sugerido:** entrar em DEMO7A com um **nome novo** (onboarding +
  diagnóstico + sessão ao vivo) → sair e entrar como **"Ana Viajante"**
  (Home com meta parcial, Trilha avançada, Passaporte cheio + reveal ao vivo).
- **Modo `DEMO` do app do aluno: despriorizado.** Com a vitrine no backend
  real, não vale ressincronizar os `*.sample` do aluno a cada evolução; o
  `DEMO` segue **necessário só para o site do professor** (até o login do
  professor existir). Não é mudança de contrato de tela — nenhum brief muda.

---

## 🖼️ Cartão-postal com arte real no Passaporte (16/07)

**Problema (achado no teste da vitrine "Ana Viajante"):** o reveal do Modo
Conquista e a coleção do Passaporte mostravam a **cena estilizada** (degradê +
sol + colina) mesmo para destinos **com arte empacotada** (ex.: Mont Blanc).
O `PostcardFace` nasceu quando "a arte real ainda não existia" e não foi
atualizado quando as 11 artes entraram no repo — Home, Trilha e Resumo já as
usavam. Resultado: o aluno via o Mont Blanc real no teaser do Resumo e uma
figura genérica ao tocar para revelar.

**Correção:** o `PostcardFace` resolve a arte pelo mesmo caminho das outras
telas (`HomeMapper.assetParaCidade`) e usa `Image.asset` quando ela existe;
sem arte (Versalhes, Japão), continua caindo na cena estilizada. **Não é
decisão revisada** — `telas.md` §7 sempre previu "animação genérica 'abrir
com toque', reutilizada nos 28; só o asset muda". De passagem, a nota
defasada do `brief-mockup-trilha.md` ("arte real só de Rio e Paris") foi
atualizada para o estado atual (11 destinos ilustrados).

**Pendências relacionadas (registradas em 16/07):**
- [ ] Arte de **Versalhes** e dos **8 destinos do Japão** (hoje: cena
      estilizada em todas as telas).
- [ ] Arte dos **3 carimbos** de país (o reveal usa o widget `Carimbo`, anel
      com iniciais) e dos **5 selos** (ícones do catálogo do cliente).
- [ ] Backend servir `asset_ref` por destino na `/v1/trilha` e aposentar o
      matching por substring do nome (`TODO(backend)` em `home_mapper.dart`
      — renomear destino no seed hoje derruba a arte em silêncio).

---

## 🔄 Pivô B2C — de venda por escola pra assinatura direto pra família (24/08)

**Decisão revisada** — a mais profunda do projeto até aqui. Rotatividade B2B
baixa (nenhuma escola fechada) levou o dono a decidir tentar B2C: assinatura
mensal/anual via Apple IAP, venda direto pra família (7–12 anos), sem
professor no meio. Análise completa, regras de negócio e o plano de execução
fase a fase estão em **`docs/produto/plano_b2c.md`** (documento novo — é ele que
passa a ser a fonte da verdade do produto daqui pra frente, não este arquivo
nem `docs/legado-b2b/rascunho_product.md`/`docs/legado-b2b/arquitetura.md`, que continuam
descrevendo o produto B2B pré-pivô e não foram reescritos por inteiro: o custo
de reescrever ~2000 linhas de prosa B2B não se pagava frente a ter
`docs/produto/plano_b2c.md` como spec B2C paralela e completa. `CLAUDE.md` foi
atualizado para apontar pra ela).

**O que muda de raiz:** identidade por turma/código → conta do responsável +
até 3 perfis de criança, sem senha própria pra criança; faixa etária
(7-8/9-10/11-12) substitui `ano_escolar` como eixo de calibração; assinatura
via RevenueCat/Apple IAP com free tier até o 1º destino; professor
**congelado, não deletado** (`app/professor/` seguem no repo, funcionando,
fora do caminho crítico). MVP de conteúdo: 100 palavras (não 600+) e trilha
reduzida a 2 países/4 destinos/16 nós — só os destinos com arte já pronta
(Rio, Foz do Iguaçu, Amazônia, Paris); o catálogo completo (3 países/20/80)
volta depois, sem mudar schema nem lógica.

**Executado nesta sessão (Fases 1–3 de `docs/produto/plano_b2c.md`):**

- **Fase 1 — Identidade familiar.** Tabelas `conta`/`perfil_crianca`; domínio
  `identidade` reescrito (`POST /v1/conta`, `POST /v1/sessao`, `GET/POST
  /v1/conta/perfis`, `POST /v1/perfis/{id}/entrar`, `DELETE /v1/conta`); token
  de responsável e de criança nunca coexistem, e cada um só abre as rotas do
  próprio escopo (`require_papel`). App: `SessaoState` selado
  (`Deslogado`/`AguardandoPerfil`/`Autenticado`), telas de cadastro/seletor de
  perfil/criar criança. **Bug real achado só no simulador iOS** (não em
  testes automatizados nem via curl): telas empilhadas via `Navigator.push`
  não se desempilhavam sozinhas quando o `_Gate` trocava o estado por baixo —
  corrigido com auto-pop condicional.
- **Fase 2 — Recalibração por faixa etária.** `progressao/faixa.py` (nível
  inicial, meta semanal, nível máximo, tudo por faixa). R-FX-1: a adaptação e
  a seleção de palavras novas nunca passam do teto da faixa. R-FX-2: banco
  esgotado dentro da faixa completa com revisão em vez de encolher a sessão.
  Orçamento de perguntas do diagnóstico também por faixa (10/12/15).
- **Fase 3 — Assinatura (Apple IAP via RevenueCat).** Tabelas
  `assinatura`/`evento_loja`; domínio `assinatura` (entitlement puro +
  webhook idempotente por `event.id`); `POST /v1/sessoes` gateado (livre até
  18.000 XP — lido do catálogo semeado, não hardcoded — depois exige
  assinatura ativa da conta, nunca do perfil). App: `purchases_flutter`,
  paywall **só alcançável pelo responsável** (Seletor de Perfil), nunca pela
  criança em meio ao jogo — ela só vê "peça pra um adulto continuar" (Apple
  5.1.4 + R-RS-1, decisão de produto tomada nesta sessão, não estava
  detalhada no plano original).

**Também no meio do caminho:** `seed_trilha.py` cortado pro catálogo do MVP;
`seed_demo.py` reescrito pra conta B2C com assinatura ativa (as personas
"vitrine" mostram progresso além do free tier, então precisam ser
assinantes); `seed.py` (turma/professor) preservado intocado.

**Verificação:** 147 testes de backend, 42 do app, `flutter analyze` limpo, e
o fluxo completo (cadastro → criar perfil → onboarding → diagnóstico →
paywall → webhook → sessão liberada) rodado ao vivo no simulador iOS e via
curl contra o backend real — não só nos testes automatizados.

**Pendências explícitas, fora do escopo desta sessão:**
- `docs/legado-b2b/rascunho_product.md`, `docs/legado-b2b/arquitetura.md`, `design/telas.md` e os
  briefs **não foram reescritos por inteiro** pro B2C (só ganharam uma nota
  no topo apontando pra `docs/produto/plano_b2c.md` — ver `CLAUDE.md` "Mapa dos
  documentos"). Se algo nesses arquivos contradisser `docs/produto/plano_b2c.md`,
  vale o plano B2C.
- Fases 4–6 do plano (redação real com IA, Área do Responsável, congelamento
  formal do professor) não começaram.
- RevenueCat/Apple Developer: sem conta/API key/product IDs reais — paywall
  funciona estruturalmente mas mostra "configuração pendente" até o dono
  configurar (`AppConfig.revenueCatApiKey`).

## 🖋️ Fase 4 — Redação real (backend), parcial (25/08)

Implementado nesta sessão, a partir de `docs/produto/plano_b2c.md` §07: domínio
`backend/app/redacao/` deixou de ser mock. Rotas reais (`GET /redacoes`,
`POST /redacoes/{id}/enviar`, `GET /redacoes/{id}/analise`, `POST
/redacoes/tema-extra`), rubrica pura por faixa (`redacao/rubrica.py`, no
padrão de `progressao/xp.py`), pipeline de triagem de risco (R-RD-7) + análise
pedagógica numa chamada só ao Claude (`redacao/analisador.py`, `Analisador`
como Protocol para os testes usarem um fake — nenhum teste faz chamada de
rede). 13 testes novos, 160 no total (backend).

**Decisão revisada registrada aqui** (`CLAUDE.md` "regra das decisões
revisadas" — já editado em `docs/produto/plano_b2c.md` §7.4 no mesmo commit): o desenho
original do plano mandava REMOVER `turma_id`/`professor_associacao_id` de
`redacao_atribuicao` na migration da Fase 4. Isso quebraria
`app/professor/repository.py` (`criar_atribuicao`/`redacoes_do_aluno`), que o
professor congelado ainda usa de verdade em produção — indo contra a regra
"congelado, não deletado, sem reescrever" do próprio `CLAUDE.md`. Resolvido
tornando as duas colunas **nullable** e a tabela um XOR entre `turma_id`
(B2B) e o novo `usuario_id` (B2C), via `CHECK (turma_id IS NOT NULL) <>
(usuario_id IS NOT NULL)`. Os 8 testes de `test_professor.py` continuam
verdes sem tocar uma linha do domínio congelado — a coexistência funciona.

**Pendências explícitas desta sessão** (não são bugs — são escopo cortado por
falta de infra ou de conteúdo que não existiam antes desta sessão):

- **Sem fila assíncrona.** O plano original citava `procrastinate`; não há
  worker configurado no repo. `enviar_redacao` roda a chamada ao Claude
  *síncrona*, dentro do request — funciona para validar o MVP, mas a criança
  fica com a tela presa por alguns segundos, e não escala sob carga real.
  Trocar por fila de verdade é a próxima dívida técnica óbvia aqui.
- **Atribuição automática é "preguiçosa"**, não um cron. R-RD-1 pede "a cada
  15 dias"; sem scheduler no repo, `garantir_atribuicao_atual` só roda quando
  o app chama `GET /redacoes` e checa se a última atribuição já passou de 15
  dias. Na prática é equivalente pra um usuário ativo (só importa quando a
  criança abre o app), mas diverge da leitura literal da regra pra quem fica
  muito tempo sem abrir.
- **`AnalisadorClaude` nunca rodou contra a API de verdade.** Sem
  `ANTHROPIC_API_KEY` no ambiente do agente nesta sessão — o prompt, o
  schema de tool-use e o parsing estão implementados por inteiro, mas o
  contrato (o modelo respeitar o schema, a qualidade da triagem de risco,
  a qualidade pedagógica das anotações) não foi validado ao vivo. Isto é
  crítico de verificar antes de qualquer envio real de criança — R-RD-7 é a
  parte que menos pode falhar.
- **R-RD-5 (notificar o responsável) não implementado.** Não existe canal de
  push/e-mail no repo. `redacao.risco_motivo` fica gravado para a Fase 5
  (Área do Responsável) mostrar, mas ninguém é avisado ativamente até lá —
  hoje uma redação em `revisao_humana` fica silenciosa.
- **§7.3 passo 4 (palavra extraída → vira `palavra` real → entra na fila de
  revisão do aluno) não implementado, de propósito.** `redacao_palavra` grava
  as palavras fracas/superutilizadas que o Claude aponta, mas nada as
  transforma em conteúdo de vocabulário de verdade. O próprio plano (§10.1
  passo 5) exige revisão humana por amostragem antes de qualquer palavra
  gerada por LLM entrar em produção — automatizar esse passo sem essa
  salvaguarda pularia a única proteção de qualidade que o plano pede. Isto é
  trabalho de pipeline de conteúdo (parecido com `seed_vocabulario.py`), não
  um bug a corrigir.
- **Catálogo de temas incompleto.** `backend/app/seed_temas.py` tem 18 temas
  (6 por faixa) — o plano (§10.4) pede 120 (40 por faixa) para cobrir um ano
  sem repetir. Suficiente pra dev/teste rodar, insuficiente pra produção;
  quando o catálogo de uma faixa esgota, `tema_disponivel` simplesmente não
  atribui nada (sem erro, mas a criança para de receber tema novo).
- **R-RD-8/R-RD-9 (opt-out contratual de treino do provedor de LLM; retenção
  de 24 meses do texto) não endereçados.** São decisão contratual/legal
  (revisar o DPA da Anthropic, política de retenção) e um job de expurgo
  agendado — nenhum dos dois é código desta sessão nem depende só de código.
- **OCR on-device não é trabalho de backend.** O app já manda só
  `texto_extraido` pro backend (a rota nunca fez OCR) — mas o app Flutter
  ainda não tem a integração de ML Kit que produz esse texto a partir de uma
  foto de caderno. Isso só pode ser feito na máquina do dono (Flutter SDK não
  está disponível no container do agente, ver `CLAUDE.md` "Ambiente").

### Fase 4, app (25/08 — mesmo dia, sessão seguinte)

`app/lib/features/redacao/` trocou `Redacao.sample()` local por
`GET/POST /v1/redacoes*` reais (`data/redacao_models.dart` +
`data/redacao_repository.dart` + `redacao_mapper.dart` +
`redacao_controller.dart`, no mesmo padrão DTO→Mapper→provider Riverpod de
`features/sessao/`). **Decisão do dono (25/08): só o caminho digitado**
(`formato: 'digital'`) nesta rodada — a captura de foto (`image_picker`,
já no `pubspec.yaml`) fica visível mas desabilitada ("em breve"), sem tocar
em OCR/ML Kit, que segue como pendência separada (ver item acima). O
`RedacaoStatus` da apresentação cresceu de 3 para 6 valores (`aberta`,
`processando`, `erroIngestao`, `erroAnalise`, `revisaoHumana`, `analisada`)
para cobrir o `status` real do backend; a tela de resultado renderiza a
análise de verdade (`pontos_fortes` + texto grifado por âncora + anotações
por dimensão, com cor fixa por uma das 5 dimensões da rubrica) em vez do
placeholder honesto anterior, e trata `revisao_humana`/`erro_ingestao`/
`erro_analise` com mensagens específicas (nunca como erro técnico genérico,
R-RD-7). Copy órfã do professor em `widgets/empty_open.dart` corrigida (não
é mais "seu professor" quem abre o tema). `POST .../enviar` é síncrono
(alguns segundos por causa da chamada ao Claude) — a tela de envio mostra
loading real ("Lendo sua redação com carinho…"), sem o delay fake antigo.
Verificado ao vivo: `flutter analyze` limpo, `flutter test` 26/26, e os 4
desfechos (aberta → enviar digitado → analisada / erro_ingestao) rodados no
navegador via `flutter build web --dart-define=DEMO=true`. Pendência notada
durante a verificação: o provider da lista (`redacaoListaProvider`) não tem
estado próprio em `AppConfig.demo` — como `Redacao.sample()` é uma função
pura sem memória, enviar uma redação em modo demo não persiste o "enviado"
entre invalidações da lista (a redação aberta reaparece aberta). Inofensivo
(é só o modo demo, sem usuário real por trás) e não afeta o caminho real
contra o backend, mas fica registrado caso vire confusão numa demo ao vivo.

## 👪 Fase 5 — Área do Responsável, backend só (25/08)

Implementado na mesma sessão da Fase 4, a partir de `docs/produto/plano_b2c.md` §08:
domínio novo `backend/app/responsavel/`. Portão PIN (`GET/POST /conta/pin`,
`POST /conta/pin/verificar` — hash argon2 em `conta.pin_hash`, coluna que já
existia no schema desde a Fase 1 mas nunca tinha sido usada) e resumo semanal
por perfil (`GET /responsavel/perfis/{id}/resumo`): meta/minutos/sessões da
semana, 5 palavras dominadas com definição, evolução da redação por
dimensão. 9 testes novos (169 no total do backend).

**Retrofit na Fase 4 pra viabilizar o item 2 (evolução por dimensão,
R-RD-6):** o pipeline de análise da redação (`redacao/analisador.py`) só
produzia anotações qualitativas — sem uma nota por dimensão não dava pra
montar um gráfico de evolução. Adicionado `niveis_dimensao` (4 níveis
nomeados: começando/avançando/consolidando/dominando) na mesma chamada ao
Claude, guardado dentro de `redacao_analise.anotacoes` (sem migration — é
JSONB) e **nunca exposto pela rota do aluno** (`GET
/redacoes/{id}/analise`), só pela do responsável — reforça R-RD-5 (a criança
nunca vê nota) na própria modelagem, não só por convenção de UI.

**Decisão de leitura de R-RS-2, registrada aqui por ser um ponto onde o
próprio texto do plano é ambíguo:** §08 pede mostrar "minutos" no resumo
(item 1), mas R-RS-2 diz "não mostrar tempo/velocidade — vale também para o
pai". Interpretação adotada: R-RS-2 mira métrica de DESEMPENHO por questão
(tempo de resposta, velocidade), que o produto trata como pressão
competitiva; "minutos" do item 1 é tempo total investido na semana, uma
métrica de ENGAJAMENTO, não de performance — mais parecida com "quantas
sessões" do que com "quão rápido ele respondeu". Se o dono achar que isso
ainda fere o espírito da R-RS-2, é fácil tirar (`minutos_na_semana` sai da
resposta e do schema sem tocar em mais nada).

**Achado de segurança corrigido na hora, não só documentado:**
`/conta/pin/verificar` é uma rota autenticada comum — sem tratamento
especial, cairia no teto genérico de rate limit por token
(`rl_autenticado_por_minuto`, default 240/min), e um PIN de 4 dígitos
(10.000 combinações) seria força-bruteável por completo em ~42min por
qualquer coisa/pessoa que já tivesse o token do responsável (ex.: token
vazado, ou a própria criança pegando o celular destravado). Movido pro
mesmo teto apertado do login (`rl_login_por_minuto`, default 5/min) em
`app/main.py`, chaveado por token (não por IP, pra não punir todo mundo
atrás do mesmo NAT). Teste dedicado em `test_seguranca.py`.

**Pendências explícitas** (nenhuma delas é código de backend faltando — são
trabalho de app ou decisão do dono):

- **Nenhuma tela Flutter existe** para a Área do Responsável
  (`app/lib/features/responsavel/` não foi criado) nem pro fluxo de PIN —
  esta sessão foi só backend. A tela de redação do app (`redacao_screen.dart`)
  também segue 100% em `Redacao.sample()`, sem chamar `/v1/redacoes` de
  verdade ainda (confirmado lendo o arquivo antes de mudar o contrato da API
  — **não há breaking change no app hoje**, mas alguém vai precisar ligar os
  dois lados nas Fases 4 e 5 do app).
- **R-RS-1 ("portão ANTES de qualquer dado") só é imposto de verdade pelo
  app**, não pelo backend. O backend valida o PIN e devolve 204/401; quem
  decide SE mostra a tela de resumo antes ou depois dessa checagem é o
  Flutter — hoje nada impede (a nível de backend) alguém com o token do
  responsável chamar `GET /responsavel/perfis/{id}/resumo` sem nunca ter
  passado pelo PIN. Isto é aceitável (a app real seria a única a expor esse
  token) mas vale registrar que o "portão" de fato é uma decisão de UX ainda
  não implementada.
- **Gerenciar assinatura/perfis/exclusão (item 4 de §08) não ganhou rota
  nova** — reaproveita `GET /v1/assinatura`, `GET/POST /v1/conta/perfis`,
  `DELETE /v1/conta`, que já existiam. Fica registrado que isto foi decisão
  deliberada (evitar duplicar contrato), não esquecimento.

### Fase 5, app (25/08 — mesmo dia, sessão seguinte à do app da Fase 4)

`app/lib/features/responsavel/` criado: `pin_gate_screen.dart` (portão —
"criar PIN" quando `GET /conta/pin` devolve `definido: false`, senão "digite
o PIN"; link "Esqueci o PIN" cai no mesmo fluxo de criação, já que
`POST /conta/pin` não exige o PIN antigo — o token do responsável já é a
autenticação forte por trás dele), `responsavel_home_screen.dart` (conta +
lista de filhos + atalhos de assinatura/adicionar criança/excluir conta),
`resumo_screen.dart` (meta semanal, minutos/sessões, as 5 palavras
aprendidas, evolução da redação em chips coloridos por dimensão — mesmo
padrão DTO→Mapper→provider Riverpod das outras features) e
`excluir_conta_screen.dart` (senha + checkbox de confirmação — pede a senha
de novo mesmo já tendo passado o PIN, porque excluir é irreversível e um PIN
de 4 dígitos é gate leve demais pra isso).

**Achado arquitetural que mudou o ponto de entrada** (a pendência do backend
"R-RS-1 só é imposto pelo app" acima cobra essa decisão): o `TokenStore`
guarda **um único token** por vez (R-ID-2/R-ID-3), e não existe endpoint pra
trocar o token de criança de volta pro de responsável — só
`POST /perfis/{id}/entrar` (responsável → criança), nunca o caminho inverso.
Ou seja: a Área do Responsável só é alcançável enquanto o token do
responsável ainda está ativo, isto é, **na tela de Seletor de Perfil**
(`AguardandoPerfil`, entre o login e a escolha do filho) — exatamente onde o
Paywall já vive (o próprio comentário em `assinatura_controller.dart` já
antecipava isso: "relido a cada vez que a Área do Responsável ou o paywall
abrem"). Por isso o atalho novo entrou no header do
`SeletorPerfilScreen` (`AppIcons.familia`, ao lado do de assinatura), **não**
dentro do jogo da criança. Como no dia a dia o app abre direto na Home da
criança (o `AuthController` resolve o token salvo sem passar pelo Seletor de
novo), foi adicionado um atalho em `ConfiguracoesScreen` ("Área do
Responsável") que explica isso e oferece sair + entrar de novo com o e-mail
do responsável — sem inventar endpoint novo de troca de token, que seria
mudança de backend fora do escopo desta sessão. Se algum dia isso incomodar
na prática, a correção é de backend (um endpoint tipo
`POST /perfis/sair-para-responsavel`), não de app.

Também corrigido de passagem: `AssinaturaRepository.status()` nunca tinha
sido chamado com `AppConfig.demo` ligado antes desta sessão (só
`ofertaAtual()`/paywall eram exercitados em demo) — a `_AssinaturaCard` nova
expôs que ele sempre batia na rede de verdade, travando em modo demo sem
backend. Adicionado o mesmo branch de demo que todo o resto do app já usa.

Verificado: `flutter analyze` limpo, `flutter test` 26/26, e as 4 telas
navegadas ao vivo no navegador (build web com `DEMO=true`, apontando
`main.dart` temporariamente pro `PinGateScreen` só pra QA — revertido antes
de terminar, `git diff` em `main.dart` ficou vazio).

### Verificação em Simulador iOS — Redação + Área do Responsável (25/08, sessão seguinte)

Fechada a pendência "nenhuma verificação em simulador iOS/dispositivo real"
das duas seções acima. `flutter build ios --simulator` (iPhone 17 Pro, iOS
26.5) + `--dart-define=DEMO=true`, com o mesmo truque temporário de apontar
`main.dart` pro `PinGateScreen` só durante a sessão de QA (revertido depois,
`git diff` em `main.dart` ficou vazio de novo). Confirmado ao vivo, em
renderização nativa real (não navegador): Home → Redação (lista, chips de
status, envio digitado com contador de palavras ao vivo) → Resultado
analisado (texto grifado por âncora + cartões de anotação por dimensão,
idêntico ao navegador) → Resultado `erro_ingestao` (placeholder acolhedor) →
Área do Responsável: portão de PIN (máscara `••••`, título/subtítulo,
"Esqueci o PIN"). Fontes (Fredoka/Nunito/Caveat/mono), cores e Cupertino
touches (linha customizada do PassportField etc.) todos corretos no
dispositivo real.

**Limitação de ferramenta encontrada, não bug de app:** neste simulador, com
um `TextField` focado, o teclado de software cobre a faixa inferior da tela
(~291pt) mas **não aparece no screenshot** desta ferramenta de automação — as
coordenadas de toque continuam sendo despachadas pro teclado (invisível na
imagem), então qualquer botão nessa faixa (`Enviar` da redação, `Entrar` do
PIN) fica intocável via automação enquanto o campo está focado, mesmo com
coordenadas corretas. Testado exaustivamente (varredura de coordenadas,
gestos de arrastar pra fechar o teclado, relançar o app) sem solução
confiável dentro da ferramenta. Isso **não é um defeito do app** — o mesmo
fluxo de envio (digitar → enviar → ver análise) já foi validado de ponta a
ponta no navegador (ver nota da Fase 4, app) e a única diferença aqui é a
ferramenta de automação não conseguir "furar" o teclado nativo para tocar o
botão. Um humano tocando a tela normalmente não teria esse problema. Fica
registrado para quem for automatizar testes de UI reais (ex.: `integration_test`)
nesse tipo de tela — soluções mais robustas usariam `flutter_driver`/
`integration_test` (que conhece o `MediaQuery.viewInsets` de verdade) em vez
de coordenadas de tela fixas.

## 🗑️ Fase 6 — Professor removido (decisão revisada 25/08, mesma sessão)

`docs/produto/plano_b2c.md` §09 original mandava **congelar** o professor/B2B (código
parado no repo, fora da API pública, deletar de verdade só depois de 3 meses
de B2C validado). Ao propor executar esse passo, encontrei uma contradição
real entre o próprio texto do plano — passo 1 ("remover `professor_router` da
API pública") quebraria os 8 testes de `test_professor.py`, que fazem
requisição HTTP de verdade contra `/v1/professor/*`, contradizendo o passo 3
do mesmo parágrafo ("manter os testes do professor rodando"). Levei a
contradição pro dono em vez de escolher um lado sozinho; a resposta foi
**deletar tudo**, não só resolver a contradição.

**Executado nesta sessão** — primeira vez que este ambiente (worktree local
do dono, não o container cloud) teve acesso a Flutter, então deu pra tocar
os dois lados:

- **Backend removido:** `backend/app/professor/` inteiro (rotas, serviço,
  repositório, schemas), `backend/app/seed.py` (só existia pra semear
  escola/turma/professor), `tests/test_professor.py`, as fixtures
  `professor`/`coordenador` de `tests/conftest.py` (e o `await seed()` morto
  em `test_jornada.py`, que não usava o retorno). De quebra, achado e
  removido código morto que só o professor consumia:
  `app/progressao/meta.py` inteiro (`meta_efetiva`/`META_DEFAULT_POR_ANO`) —
  nada além dos próprios testes do módulo o chamava; a Home/`/v1/me` sempre
  usaram `progressao/faixa.meta_semanal_default` diretamente.
- **Schema removido** (migration `2353552372bd`, testada
  upgrade→downgrade→upgrade sem drift): tabelas `turma`, `escola`,
  `associacao_turma`, `turma_config`, `sinal_turma`; coluna
  `associacao.escola_id`; `associacao.papel` restrito a
  `'aluno'`/`'responsavel'` (tirou `'professor'`/`'coordenador'`/`'admin'`,
  nenhum código usava esses valores fora do professor); `aluno_palavra.origem`
  perde `'sinal_turma'`. **`redacao_atribuicao` volta ao desenho original do
  plano** (só `usuario_id`+`origem`+`tema_catalogo_id`, sem `turma_id`) — a
  decisão da Fase 4 de fazer a tabela coexistir com o professor
  (`turma_id` XOR `usuario_id`) só existia por causa do professor; sem ele, a
  coexistência não tem mais razão de ser. Registrado em `docs/produto/plano_b2c.md`
  §7.4.
- **App Flutter removido:** `app/lib/features/professor/` (8 arquivos:
  telas, DTOs, mapper, providers, shell), `app/lib/main_professor.dart`,
  `app/test/professor_mapper_test.dart`,
  `app/test/arquitetura_professor_test.dart` (o guard R1/R2 que garantia o
  isolamento — sem professor pra isolar, o teste não tem mais o que
  verificar). Dois comentários em `core/api_providers.dart` e
  `features/identidade/auth_controller.dart` que explicavam a partilha de
  providers com a superfície do professor foram ajustados.

**Verificado:** 155 testes de backend passam (removidos os 12 de
`test_professor.py` e os 2 de `meta_efetiva`; 1 novo cobrindo
`meta_efetiva_b2c`), `flutter analyze` limpo, 26 testes de app passam
(removidos os 2 do professor). Migration ida e volta sem drift (`alembic
check`).

**Não é pendência, é decisão registrada:** os documentos B2B pré-pivô
(`docs/legado-b2b/rascunho_product.md`, `docs/legado-b2b/arquitetura.md`, `design/telas.md`,
`design/brief-mockup-*.md`) agora descrevem código que **não existe mais no
repo** (antes descreviam código congelado, ainda presente). Não foram
reescritos — o custo de reescrever ~2000 linhas de prosa B2B segue não se
pagando — mas `CLAUDE.md` "Mapa dos documentos" foi atualizado pra deixar
isso explícito.

---

## 🔀 Troca de provedor de LLM: Anthropic (Claude) → OpenAI (26/08)

**Decisão do dono (26/08):** a análise de redação (`app/redacao/analisador.py`,
Fase 4) vai usar a API da **OpenAI (GPT-4o-mini ou similar)** em vez da
Anthropic. Motivo: a tarefa (rubrica + triagem de risco por faixa etária, com
prompt estruturado) não exige o modelo mais caro/inteligente da Anthropic —
custo por redação analisada importa mais numa assinatura B2C de baixo ticket
do que a última milha de qualidade do modelo.

**Atualização (26/08, mesma sessão): a troca de código foi feita.**
`backend/app/redacao/analisador.py` — `AnalisadorClaude` virou
`AnalisadorOpenAI`: `AsyncAnthropic`/tool-use → `AsyncOpenAI`/function-calling
(`chat.completions.create` com `tools=[...]`, `tool_choice={"type":
"function", ...}`; resposta vem em `choices[0].message.tool_calls[0]
.function.arguments`, uma string JSON — precisa de `json.loads`, diferente do
`bloco.input` já-parseado da Anthropic). `backend/app/config.py`:
`anthropic_api_key`/`anthropic_modelo_redacao` → `openai_api_key`
(`OPENAI_API_KEY`)/`openai_modelo_redacao` (default `"gpt-4o-mini"`).
`backend/pyproject.toml`: dependência `anthropic` → `openai`, `uv lock` +
`uv sync` rodados. `.env.example` não tinha a chave documentada, nada a
mudar lá.

**Verificado:** `uv run pytest` segue 155/155 (o fake em `test_redacao.py`
nunca dependeu do formato de resposta da Anthropic, só da interface
`Analisador`). Import do módulo novo funciona (`AnalisadorOpenAI`,
`get_analisador()` retorna a classe certa). A estrutura do tool-schema em
formato OpenAI (`type: function`, `function.parameters`) foi conferida
isoladamente (chaves e `required` batendo com o schema original).

**Segue pendência, não mudou com a troca de SDK:** nunca rodou contra a API
de verdade em nenhum provedor (nem Anthropic, nem OpenAI agora) — falta
`OPENAI_API_KEY` real pra validar ao vivo, principalmente a triagem de risco
(R-RD-7).

---

## 📚 Vocabulário — 37 → 100 palavras (26/08)

**Feito:** [seed_vocabulario.py](../backend/app/seed_vocabulario.py) ganhou
as 63 palavras que faltavam pro MVP (10 por nível de dificuldade 1–10, antes
eram 3–4). Cada uma com definição, 2–3 sinônimos, frase de exemplo e as 8
questões (4 níveis × 2 variações), no mesmo formato de autoria manual das 37
originais — sem passar pelo pipeline de LLM+QA automático descrito em
`docs/produto/plano_b2c.md` §10.1 (esse pipeline ainda não existe como
código, é só o plano de como escalar pro pós-MVP).

**Processo:** lista de 63 lemas + definição + sinônimos + exemplo foi
rascunhada primeiro (sem as questões) e revisada pelo dono antes de escrever
as 504 questões novas (63×8). `_validar()` (já existente no arquivo) mais uma
checagem ad-hoc confirmam: 100 palavras, exatamente 10 por nível, nenhum lema
duplicado, nenhuma opção repetida dentro de uma questão, resposta correta
sempre presente nas opções.

**Pendência explícita:** as 504 questões novas em si (os enunciados e
distratores, não a lista de palavras) ainda não passaram por revisão humana
por amostragem — o plano exige mínimo 20% revisado, 100% na faixa 7–8 (níveis
1–4). A lista de palavras/definições foi revisada; as questões, não. Ver
`docs/produto/plano_b2c.md` R1 (riscos) e checklist §15, ambos atualizados
pra refletir esse estado intermediário.

## ✍️ Temas de redação — 18 → 120 (26/08)

**Feito:** os 102 temas que faltavam (34 por faixa etária, completando os 40
de cada uma) estão em [seed_temas.py](../backend/app/seed_temas.py) por
inteiro — título, gênero e enunciado revisados pelo dono antes do `apoio`
(2 perguntas-gancho por tema) ser escrito e migrado pra lá. O rascunho
intermediário (`docs/produto/rascunho_vocabulario_temas.md`) foi apagado —
conteúdo final vive só no seed agora, sem duplicar em dois lugares.

**Verificado:** `uv run python -m app.seed_temas` insere os 102 novos
(`temas_inseridos: 102`), idempotente na segunda chamada
(`temas_inseridos: 0`). Checagem ad-hoc: 120 temas no total, exatamente 40
por faixa, nenhum título duplicado, todo `apoio` com ≥2 perguntas, todo
`genero` dentro do enum válido.

**Pendência explícita, igual à do vocabulário:** o `apoio` dos 102 temas
novos (conteúdo gerado, não só revisado pelo dono como título/enunciado) não
passou por revisão humana por amostragem — mesma lacuna do risco R1 do plano
B2C, só que pro conteúdo de redação em vez de vocabulário.

---

## ⚖️ Documentação legal — rascunhos LGPD/App Store (26/08)

**Feito:** os 9 documentos do checklist §15 "Legal" do plano B2C (`docs/produto/plano_b2c.md`
§11.1) foram rascunhados em `docs/legal/` — Política de Privacidade, Termos
de Uso, Termo de Consentimento Parental, ROPA, Política de Retenção e
Exclusão, Plano de Resposta a Incidente, Lista de Suboperadores, pesquisa de
opt-out de treinamento com a OpenAI, e mapeamento de Privacy Nutrition
Labels. Índice em `docs/legal/README.md`.

**Como foi feito, pra não virar "genérico de internet":** cada documento foi
escrito a partir do schema real (`backend/app/schema.py` — `conta.pin_hash`,
`conta.consentimento_lgpd_em`/`consentimento_versao`, `perfil_crianca.apelido`/
`ano_nascimento`, o fluxo de triagem de risco de `redacao/analisador.py`) e
das regras R-LG-1 a R-LG-5 já descritas no plano, não de um template
genérico de política de privacidade.

**Decisões que o dono tomou nesta sessão pra viabilizar os rascunhos:**
pessoa física por enquanto (sem CNPJ ainda — documentos ficam com
placeholder até abrir empresa), DPO é o próprio fundador provisoriamente,
escopo só LGPD/Brasil por enquanto (sem cláusulas de COPPA/GDPR, mais simples
pro MVP).

**Pendência explícita — nada disto está pronto pra publicar:**
- Todos os 9 documentos precisam de **revisão por advogado** antes de valer
  como documento legal de verdade — são rascunhos técnicos competentes, não
  aconselhamento jurídico.
- `termo_consentimento_parental.md` é o mais crítico (art. 14 §1 exige
  "consentimento específico e em destaque") — a tela de consentimento em si
  e o gate no backend antes de `POST /v1/conta/perfis` **ainda não foram
  implementados no código**, só o texto e a nota de onde plugar
  (`conta.consentimento_lgpd_em`/`consentimento_versao`, que já existem no
  schema desde a Fase 1, nunca usados até agora).
- `opt_out_llm.md` precisa de ação humana fora do repo (acessar o painel da
  conta OpenAI, avaliar Zero Data Retention, assinar o DPA deles) — nenhum
  agente consegue fazer isso sozinho.
- Job de expurgo automático de redação aos 24 meses (política de retenção)
  não existe no código ainda — não é urgente, ninguém tem 24 meses de uso.
- Decisão D9 (categoria Kids vs. Educação/4+) continua em aberto, referenciada
  mas não decidida por estes documentos.

---

## 🔎 Pesquisa jurídica de fonte primária — sem advogado, por decisão do dono (26/08)

**Decisão do dono, explícita:** não contratar advogado. Pediu pra pesquisar
leis de verdade (Google/fontes públicas) e deixar os documentos legais o
mais sólidos possível com isso, em vez de deixar tudo marcado como
"pendente de revisão jurídica". Passo seguinte da sessão de documentação
legal (mesmo dia, ver seção acima).

**O que a pesquisa mudou de fato** (proveniência completa em
`docs/legal/fontes_pesquisa.md`):

1. **ECA Digital (Lei 15.211/2025)** — lei nova, em vigor desde 17/03/2026,
   que não existia quando o `plano_b2c.md` original foi escrito (nem quando
   os rascunhos legais da rodada anterior desta sessão foram feitos, horas
   antes). Achado real, não só formalidade: a lei exige canal de reporte às
   autoridades pra sinal de risco grave, e o produto só tinha "revisão
   humana interna" pra isso. Endereçado em `docs/legal/eca_digital.md` +
   novo §6 em `plano_resposta_incidente.md` (Disque 100/Conselho
   Tutelar/SaferNet) + R9 na tabela de riscos do plano.
2. **Decisão D9 resolvida** (categoria da App Store) — Educação/4+, não Kids
   Category. Motivo concreto encontrado na pesquisa: a Kids Category usa
   faixas etárias fechadas (5-, 6–8, 9–11) que não cobrem os 7–12 do
   VocabKids por inteiro, e proíbe qualquer transmissão de dado a terceiro
   mesmo pseudonimizado — conflitaria com o envio à OpenAI.
3. **DPO não é obrigatório** pro estágio atual — Resolução CD/ANPD nº 2/2022
   dispensa agente de tratamento pessoa física (que é o caso, sem CNPJ) da
   exigência formal do art. 41. Mantido mesmo assim por transparência, mas
   deixou de ser "pendência legal" e virou "escolha".
4. **Prazo de notificação de incidente não é "prazo razoável" vago** —
   Resolução CD/ANPD nº 15/2024 define 3 dias úteis (6 pra pequeno porte).
   Documento antigo tinha um placeholder pedindo confirmação com advogado;
   agora tem o número exato, com fonte.
5. **OpenAI já não usa dado de API pra treino por padrão** — não era uma
   pendência de configuração, era desconhecimento: a garantia mais
   importante (não treinar com o texto da redação) já existe sem nenhuma
   ação nossa. O que resta (Zero Data Retention, DPA) é real, mas
   reconhecidamente inacessível a uma operação solo hoje (passa por canal
   de vendas empresarial) — documentado como tal, não escondido.
6. **Prazos de retenção genéricos preenchidos** com base em prazos gerais do
   direito brasileiro (5 anos fiscal/civil, referência CTN art. 173 e CC
   art. 206) em vez de ficarem como placeholder "confirmar com advogado".
7. **Texto-modelo de comunicação de incidente** escrito (antes só descrevia
   o conteúdo esperado, não tinha um rascunho pronto).

**O que a pesquisa não resolve, por natureza** (fica registrado, não
escondido): nenhuma pesquisa por IA substitui uma revisão jurídica
individualizada de verdade — o que está em `docs/legal/` é o melhor esforço
possível a partir de fonte pública nesta data (26/08/2026), com duas fontes
primárias que não puderam ser acessadas diretamente por erro de rede
(planalto.gov.br, guidelines completas da Apple — contornado com fontes
secundárias confiáveis que citam o texto original). A regulamentação
complementar do ECA Digital (decreto) ainda não existe — o que ela vai
exigir em detalhe técnico é, por definição, desconhecido até ser publicada.

---

## ✅ Tela de consentimento parental — implementada (27/08)

**Achado ao investigar antes de codar:** o gate no **backend** já existia
desde a Fase 1 (`_exigir_consentimento` em `app/identidade/routes.py`,
testado) — não era pendência de código nova. A pendência real era só a
**UI**: `cadastro_screen.dart` tinha uma única caixa de marcação (texto
parafraseado, sem link pro conteúdo de verdade) e `repository.dart` mandava
`aceite_termos: true, consentimento_lgpd: true` **fixos**, independente do
que a caixa dissesse — funcionava porque a UI bloqueava o envio sem marcar,
mas não representava de verdade dois consentimentos distintos.

**Descoberta que mudou o desenho do `termo_consentimento_parental.md`:** o
consentimento é pedido na **criação da conta** (`POST /v1/conta`), **antes
de qualquer perfil de criança existir** (perfis são criados depois, um a
um, até 3 por conta). A primeira versão do documento (rascunho de 26/08)
assumia incorretamente uma tela por criança, template com `{apelido}`,
gatilhada em `POST /v1/conta/perfis` — teria exigido schema novo
(consentimento por perfil, não por conta) e um segundo gate. Reescrito pra
descrever a arquitetura real: um consentimento por conta, texto genérico
("a(s) criança(s) que você cadastrar"), com a alternativa por-criança
registrada em "Decisões que ficaram de fora" como evolução futura, não
bloqueador.

**Feito:**
- `app/lib/features/identidade/legal_texts.dart` — texto condensado (versão
  mobile) dos Termos de Uso e do consentimento LGPD, mais
  `kVersaoConsentimentoLgpd` em sincronia manual com
  `CONSENTIMENTO_VERSAO_ATUAL` do backend.
- `app/lib/features/identidade/widgets/legal_text_screen.dart` — tela
  genérica reutilizável pra exibir esses textos (sem dependência nova:
  texto puro, sem webview/markdown).
- `cadastro_screen.dart` — duas caixas de marcação **separadas**: aceite dos
  Termos de Uso (simples) e consentimento LGPD (cartão destacado, borda e
  fundo próprios, texto "Ver o que isso significa" abrindo a tela
  completa). Nenhuma pré-marcada; erro visual (borda âmbar) em qualquer uma
  não marcada ao tentar submeter.
- `repository.dart`/`auth_controller.dart` — `cadastrar()` agora recebe
  `aceiteTermos`/`consentimentoLgpd` como parâmetros de verdade e manda o
  valor real ao backend, não mais `true` fixo.

**Bug pego durante a implementação:** tentei usar `\` no fim de linha
dentro das strings triple-quoted do Dart pra continuar a frase na linha de
baixo (hábito de Python) — `flutter analyze` acusou `unnecessary_string_escapes`.
Testei com `dart run` isolado: o `\` é descartado mas a quebra de linha
**permanece** (Dart não tem continuação de linha assim), o que teria
quebrado as frases no meio silenciosamente se eu não tivesse verificado.
Corrigido escrevendo cada parágrafo numa linha só no arquivo fonte.

**Verificado ao vivo, não só testes:** subi o backend real
(`uvicorn`) + o app Flutter web (`flutter run -d web-server`) contra ele,
com um `.claude/launch.json` novo pro preview. No navegador: (1) botão
"Criar conta" sem marcar nada → as duas caixas ficam com borda de erro; (2)
link "Ver o que isso significa" abre o texto completo, sem escape/quebra
estranha; (3) as duas marcadas → conta criada de verdade. Conferi no
Postgres: `conta.consentimento_lgpd_em` com timestamp real e
`consentimento_versao = '1.0'`, batendo com `CONSENTIMENTO_VERSAO_ATUAL`.
Conta de teste apagada depois. `flutter analyze` limpo, `flutter test`
26/26 (nenhum teste de widget cobria cadastro antes; não adicionei um novo
porque a verificação ao vivo já cobriu o caminho crítico e não há padrão de
teste de widget nesta base — ver se vale adicionar depois).

**Pendência que sobrou, registrada em `docs/legal/termo_consentimento_parental.md`:**
não existe hoje um mecanismo de "pedir consentimento de novo" pra uma conta
já existente quando `CONSENTIMENTO_VERSAO_ATUAL` sobe — o gate atual só
vale pra contas novas. Não é urgente (a versão nunca mudou desde que existe
o campo), mas fica registrado antes que vire problema silencioso.

---

## 🗑️ Canal de reporte às autoridades (ECA Digital) — descartado por decisão do dono (27/08)

**O que era:** na rodada de pesquisa jurídica de 26/08, identifiquei que o
ECA Digital (Lei 15.211/2025) exige um "mecanismo eficaz de reporte
imediato às autoridades" quando a triagem de risco da redação confirma algo
grave (abuso, violência, exploração) — e documentei um processo manual pra
isso em `docs/legal/plano_resposta_incidente.md` §6 (Conselho
Tutelar/Disque 100/SaferNet Brasil), registrado como R9 na tabela de riscos
do plano.

**Decisão do dono (27/08):** não vamos ter esse canal — a operação (uma
pessoa) não tem capacidade de manter esse processo. Pedido explícito: tirar
o conteúdo relacionado, não só marcar como pendência.

**O que foi removido/ajustado:**
- `docs/legal/plano_resposta_incidente.md` — §6 (o passo a passo inteiro)
  removido; virou um §8 curto "Fora de escopo, por decisão do dono",
  nomeando a decisão sem manter o processo detalhado.
- `docs/legal/politica_privacidade.md` §2 e §6.1 — reescritas pra não
  afirmar mais que o VocabKids aciona esses canais.
- `docs/legal/eca_digital.md` — a linha da tabela sobre esse requisito
  mudou de "gap identificado e endereçado" pra "gap conhecido, aceito por
  decisão do dono — não vai ser construído".
- `docs/produto/plano_b2c.md` — risco R9 reescrito (mitigação: "nenhuma",
  risco aceito conscientemente); checklist §15 ajustado.
- `docs/legal/README.md` — nova seção "Escopo descartado por decisão do
  dono".

**O que isso significa de verdade, sem eufemismo:** a exigência legal do
ECA Digital não desaparece por não estar documentada — só significa que,
se `redacao.risco_sinalizado = true` confirmar um caso real algum dia,
não há processo escrito de o que fazer. É um risco assumido
conscientemente pelo dono, não um problema resolvido. Registrado aqui e em
`docs/legal/eca_digital.md`/`plano_resposta_incidente.md` §8 exatamente
pra não virar um "esquecimento" — é uma decisão, com dono e data.

**Também esclarecido nesta conversa:** a "checagem de 10min na conta
OpenAI" (`opt_out_llm.md`) listada como pendência não faz sentido cobrar
agora — não existe conta/chave OpenAI configurada ainda
(`OPENAI_API_KEY` nunca foi setada). Isso não foi removido do documento
(ao contrário do canal de reporte, é um passo real que ainda vai ser
necessário), só recontextualizado: é ação pra quando a conta existir, não
pendência ativa hoje.
