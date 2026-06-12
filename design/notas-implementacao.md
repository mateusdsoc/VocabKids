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
**Dashboard escola/professor** (`telas.md` §8.2 — única tela da fatia A ainda
não implementada; mock estático, fala com quem assina) ou **wiring com o
backend** (`/v1/sessoes` na Sessão; fila de conquistas via `/v1/passaporte`;
gatilho real do "completar nó" na Trilha). As animações do contrato estão
todas implementadas; TTS saiu do MVP (11/06).

> **Diagnóstico (conteúdo):** a etapa já roda como mini-quiz com **questões de
> exemplo** (`diagnostico_data.dart`); falta a **revisão pedagógica** com um
> professor para virar conteúdo real, e o wiring com a escada do backend
> (`POST /v1/onboarding/diagnostico`).
