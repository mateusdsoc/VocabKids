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

### Redação — correção viva no apresentável (`features/redacao/`)
- **Decisão do dono (19/06):** trazer a **correção** da redação para o
  apresentável. Motivo: é **o diferencial** do produto (redação→vocabulário) e
  não dava para apresentar a escolas com a tela em placeholder ("entra com o
  motor de correção"). O que entrou é **dado mockado na tela real** — a
  **ingestão** (OCR de foto / extração de PDF) continua **desenhada** (fatia C).
  Docs contratuais atualizados no mesmo commit (`design/telas.md §8.1`).
- **Como ficou (`ResultadoScreen`, agora `ConsumerWidget`):**
  - Texto do aluno com **sublinhado colorido por dimensão** (escolha do dono em
    19/06: sublinhado inline, e não marca-texto nem lista lateral). Tocar num
    trecho abre uma **folha de dica** (comentário + sugestões).
  - **Resumo da correção** por dimensão (contagem) — **sem nota/%/tempo** (regras
    travadas); coesão positiva vira **nota geral**; **pontos fortes**; e
    **“palavras que você ganhou”** (gatilho→palavra), o payoff visível do loop.
- **Arquitetura (cliente fino, sem reescrita na fatia C):**
  - `analise.dart` espelha `AnaliseOut` do backend; `AnaliseRedacao.demo(id)`
    serve a redação "Um herói brasileiro" (id 2) no modo `DEMO`, **resolvendo as
    âncoras (trecho, ocorrência)→offsets igual ao servidor** — sem offset mágico.
  - `redacao_providers.dart`: `analiseRedacaoProvider` (`FutureProvider.family`,
    mesmo padrão do `alunoDetalheProvider` do professor) → em `DEMO` usa a
    amostra; ligado, lê `GET /v1/redacoes/{id}/analise`.
  - Tokens de cor por dimensão no `AppColors` (`dimVocabulario/Acentuacao/`
    `Pontuacao/Coesao`), distintos do vermelho de resposta (aqui não há erro
    punitivo). Nada hardcoded.
  - Teste `test/redacao_analise_test.dart`: trava a resolução de âncoras e o
    `fromJson` (contrato do backend).
- **Pendente (fatia C):** ingestão real (OCR/PDF→`texto_extraido`), análise por
  LLM e atribuição das palavras na trilha. As telas e o contrato já estão prontos.

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

## 🔌 Pendências de backend (cliente fino)

A Sessão hoje roda com `sampleSession` (dados de exemplo). O backend já expõe
tudo o que a tela precisa — falta o **wiring no app**:
- [ ] `POST /v1/sessoes` (montar a fila — entrega híbrida, sem vazar resposta).
- [ ] `GET /v1/sessoes/{id}/proximo` (**implementado no backend em 10/06**).
- [ ] `POST /v1/sessoes/{id}/respostas` (correção **server-side** → XP/combo/estado).
      Hoje a correção é local (demo); o servidor será autoritativo.
- [ ] `POST /v1/questoes/{id}/report` (mock na fatia A).
- [ ] **Re-queue do erro** (decisão #3 **revisada em 10/06**): a intercalação é
      **server-side** — a fila persiste em `sessao.fila` e volta reordenada em
      cada `POST /respostas` (`fila`/`proximo`). O app só renderiza a ordem
      recebida (nada de reimplementar a regra no Dart). No wiring, trocar o
      "só avança" da demo por consumir `fila`.

### Home — campos ainda não expostos pela API (ver `HomeMapper`)
- [ ] **Meta semanal** (palavras dominadas/semana) — placeholder 6/10. A meta
      real vem de `turma_config.meta_semanal` (professor configura; default por
      ano se nula). Ao definir os defaults, simular contra o ritmo real
      (2 palavras novas/sessão, domínio em ~3+ sessões) para ser batível.
- [ ] **Arte por destino** na `/v1/trilha` (asset_ref) — hoje só Rio/Paris.

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
  modelo (`docs/arquitetura.md`).
- **Trilha sem selo "você está aqui"** (decisão revisada): o nó atual em
  destaque + caminho percorrido já comunicam a posição.
- Sem streak diário, meta diária, mascote, % de acerto ou tempo (produto).
- Fontes: Fredoka (display) · Nunito (corpo) · Caveat (só "Passaporte") ·
  Space Mono (micro-rótulos).

---

## ▶️ Próximo passo sugerido
**Superfície do Professor (web)** — telas A–D **completas** (fases 0–5); resta a
**verificação visual claro/escuro** da fase 6 (precisa de Chrome/SDK; comandos no
HANDOFF). Depois dela, **wiring com o backend** (`/v1/sessoes` na Sessão; fila de
conquistas via `/v1/passaporte`; gatilho real do "completar nó" na Trilha) e a
**fatia C** do professor (persistir meta/atribuição, exigir papel+escopo). As
animações do contrato estão todas implementadas; TTS saiu do MVP (11/06).

> **Diagnóstico (conteúdo):** a etapa já roda como mini-quiz com **questões de
> exemplo** (`diagnostico_data.dart`); falta a **revisão pedagógica** com um
> professor para virar conteúdo real, e o wiring com a escada do backend
> (`POST /v1/onboarding/diagnostico`).
