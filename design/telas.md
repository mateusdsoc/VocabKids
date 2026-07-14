# Telas do app — especificação de conteúdo e comportamento

> **Para que serve:** brief preciso de **o que existe em cada tela**, a
> hierarquia, as ações, os estados e de onde vêm os dados. É o input para gerar
> mockups de UI (claude design / Artifacts / etc.) com precisão, e o contrato
> para implementar em Flutter.
>
> **Princípio (decidido com o dono):** este documento é **style-agnostic** —
> descreve **conteúdo, prioridade e comportamento**, NÃO cor/tipografia/estilo.
> A **paleta e o visual** são uma decisão de marca **própria e neutra**, definida
> **depois** e separada da arte (os cartões-postais são multicoloridos; o chrome
> da UI tem que emoldurá-los sem competir — ver `imagens/PROMPT-ESTILO.md`).
>
> Escopo: telas da **fatia A (apresentável)**. Fontes: `docs/rascunho_product.md`
> (seções citadas) e a API `/v1` já implementada no backend.

---

## Convenções

- **Cliente fino:** toda regra (XP, combo, estado da palavra, adaptação) vem do
  servidor. A tela **renderiza e captura** — nunca calcula pontuação.
- **Animação:** curta e **não-bloqueante** — nunca trava o aluno antes de seguir
  (princípio do produto 3.7).
- Cada tela lista: **Objetivo · Conteúdo · Hierarquia/CTA · Estados · Dados (API)
  · Navegação · Notas de produto**.

---

## Mapa de navegação (fatia A)

```
ENTRADA (código de turma)
   └─► ONBOARDING (1ª vez): boas-vindas → 2 demos → diagnóstico → 1ª palavra
            └─► HOME-HUB ◄─────────────────────────────┐
                  │  "Continuar"                        │
                  ▼                                     │
               SESSÃO ──► RESUMO DE SESSÃO ──► TRILHA (mapa) ─┘
                                  │ (se há item novo)
                                  ▼
                            PASSAPORTE (Modo Conquista)

  Atalhos da Home: TRILHA · PASSAPORTE (perfil) · REDAÇÃO* · EVENTOS/LEADERBOARD*
  (* mockados/estáticos na fatia A)
```

> Regra de aterrissagem (3.7): ao **abrir o app** cai na **Home**; ao **sair de
> uma sessão** aterrissa na **Trilha** (mapa), não na Home.

---

## 1. Entrada (código de turma)

- **Objetivo:** acesso provisório da fatia A — aluno entra pelo código da turma.
- **Conteúdo:** campo *código da turma*; campo *apelido* (rótulo "Seu apelido",
  hint "Como quer ser chamado?"); botão **Entrar**.
- **Hierarquia/CTA:** botão Entrar é o único CTA; tela mínima.
- **Estados:** carregando (entrando); erro (código inexistente / sem conexão —
  mensagem legível vinda do `error.message`); sucesso → roteia.
- **Dados:** `POST /v1/acesso/turma {codigo_turma, nome}` → token + `novo`.
  Se `novo == true` → Onboarding; senão → Home. (O campo do body ainda se chama
  `nome` no backend — só o rótulo virou "apelido"; o rename do contrato entra
  na fase de pré-cadastro.)
- **Navegação:** raiz quando deslogado.
- **Notas:** acesso é **provisório** (token JWT); auth real entra depois sem
  mexer na tela (produto 3.11 / 10). **Apelido em vez de nome real** (decisão
  LGPD faseada, 13/07 — ver `notas-implementacao.md`): já nesta fase o campo
  pede um **apelido**, para o piloto não coletar nome de menor; o self-service
  (aluno digita apelido + turma) segue como está. Na fase seguinte a professora
  **pré-cadastra** a turma e o acesso casa com a lista.

---

## 2. Onboarding (primeira vez) — produto 3.5

Costura entrada → diagnóstico → 1ª vitória. Sub-telas em sequência:

### 2.1 Boas-vindas temáticas
- **Objetivo:** apresentar a "viagem pelos países" (Brasil→França→Japão).
- **Conteúdo:** tela curta, ilustrada, 1 frase de convite; botão **Começar**.
- **Notas:** enquadra como jogo/viagem, não como prova.

### 2.2 Duas demos roteirizadas
- **Objetivo:** ensinar a mecânica e **normalizar o erro** antes de cobrar.
- **Conteúdo:** Demo A = como é **acertar** (mostra XP + confete). Demo B = como
  é **errar** (feedback gentil, recuperação, **sem punição**).
- **Notas:** vêm **antes** do diagnóstico de propósito (3.5). A ferramenta de
  **report** é apresentada uma vez aqui/nas primeiras questões.

### 2.3 Diagnóstico
- **Objetivo:** posicionar o aluno na trilha (nível de dificuldade), sem ser prova.
- **Conteúdo:** 10–15 questões de níveis variados; barra de progresso fina;
  enquadramento de jogo.
- **Estados:** por questão (responder); fim → define `nivel_dificuldade_atual`.
- **Dados:** `POST /v1/onboarding/diagnostico` (roda/avança a escada grosso→fino).
- **Notas:** escada grosso→fino com desconto de chute (produto 3.5 / Bloco 2a).

### 2.4 Primeira palavra
- **Objetivo:** fechar o onboarding com uma vitória.
- **Conteúdo:** card de descoberta → questão nível 1 → primeiro XP.
- **Navegação:** ao fim → Home-hub.

---

## 3. Home-hub — produto 3.7

- **Objetivo:** hub ao **abrir** o app; dá acesso a tudo, com a prática a um toque.
- **Conteúdo:**
  - **Status do aluno:** XP/nível; bolha do **nó atual**; **nº de palavras
    dominadas** (o contador, não a lista); métricas básicas.
  - **Progresso da meta semanal:** mostra o **avanço** rumo à meta (ex.: "6 de 10
    palavras dominadas esta semana"), não só um estado binário; quando batida,
    vira selo "meta cumprida". Unidade = palavras dominadas/semana (3.5);
    visibilidade própria, sem virar colecionável. A meta é **configurada pelo
    professor** (`turma_config.meta_semanal`), com default por ano escolar se
    nula — o "6 de 10" dos mockups é placeholder; ao definir os defaults,
    simular contra o ritmo real (2 palavras novas/sessão, domínio em ~3+
    sessões) para a meta ser batível.
  - **CTA primário:** botão **"Continuar"** → abre/retoma a próxima sessão.
  - **Ação secundária:** acesso ao **mapa da trilha**.
  - **Atalho de redação** → área de redação (mock na fatia A).
  - **Acesso a eventos / leaderboards** (mock/placeholder na fatia A).
  - **Perfil/avatar** → abre o **Passaporte**.
- **Hierarquia/CTA:** "Continuar" é o elemento dominante (menor fricção pra
  praticar); mapa é claramente secundário.
- **Dados:** `GET /v1/me` (perfil + `aluno_progresso`: xp_total, no_atual_id,
  palavras_dominadas, nivel_dificuldade_atual).
- **Navegação:** Continuar→Sessão; mapa→Trilha; avatar→Passaporte.
- **Notas:** Home ≠ Trilha de propósito (3.7) — o app orquestra mais que a trilha.
- **NÃO incluir (decisões de produto — resistir ao reflexo dos apps de referência):**
  - **streak diário / contador de dias** (chama do Duolingo): produto seção 09
    decidiu **não usar**. Nossa mecânica é o **combo por sessão** (3.7) +
    **meta semanal** — não há sequência de dias.
  - **meta diária:** a meta é **semanal** (palavras dominadas/semana), não diária.
  - **mascote / personagem guia:** não há mascote (seção 09); o tema é
    **viagem/passaporte**, carregado pela arte dos colecionáveis, não por um bicho.

---

## 4. Sessão — produto 3.2 / 3.4

- **Objetivo:** a prática: cards de descoberta + questões, com feedback contínuo.
- **Conteúdo (slots em fila, ~12 por sessão, 2 palavras novas):**
  - **Card de descoberta** (1ª vez de cada palavra nova): palavra em destaque;
    definição curta e conversacional; exemplo em frase. **Sem áudio de
    pronúncia** (decisão revisada 11/06: TTS **fora do MVP** — apresentável e
    completo; exigiria áudio por palavra ou requisição de TTS a cada palavra
    nova; reavaliar pós-MVP). **Gancho contextual** só quando a palavra é de
    origem pessoal (redação) — ex.: "Você usou 'importante' várias vezes. Conheça
    uma alternativa:" (na fatia A não há redação, então sem gancho).
  - **Questões** (4 tipos fixos, progressão por nível): 1 significado, 2 sinônimo,
    3 completar frase, 4 julgar uso. Múltipla escolha.
  - **Destaque inline:** a palavra nova fica marcada nas questões dela; **tocar
    reabre o card** (definição/exemplo) sem sair da questão.
  - **Barra de progresso fina** no topo, enche a cada questão respondida.
  - **Ferramenta de report:** ícone discreto; abre caixa com **motivo
    predefinido** (ex.: "a resposta parece errada", "não entendi a palavra").
    Reportar **não** pula a questão, **não** dá XP (mock na fatia A).
- **Estados por questão:**
  - **Acerto:** feedback positivo + **XP** (100/70/50 conforme tentativa) +
    confete; combo quando 1ª tentativa em sequência.
  - **Erro:** a alternativa errada fica **vermelha suavizada com "X"** (tint
    leve no fundo + borda/texto no vermelho `error`; decisão revisada — o aluno
    precisa enxergar com clareza que errou, sem tom punitivo). A resposta certa
    **não** é revelada. Feedback **gentil**, sem punição; o retry vai pro **fim
    da fila** (intercalação — a ordem é mantida e devolvida pelo **servidor** a
    cada resposta); a questão é refeita mais à frente (3.4). **No 2º erro da
    mesma palavra na sessão**, o **card de descoberta reabre** automaticamente
    antes de seguir (dá material para acertar de verdade, sem revelar a
    resposta — "errar é aprender").
  - **Última pendente:** entra em loop fixo até acertar.
- **Dados:** `POST /v1/sessoes` (monta a fila — entrega **híbrida**: lote
  planejado + prefetch, sem vazar resposta); `GET /v1/sessoes/{id}/proximo`;
  `POST /v1/sessoes/{id}/respostas` (correção **server-side** → XP/combo/estado);
  `POST /v1/questoes/{id}/report` (mock).
- **Navegação:** ao fim → Resumo de sessão.
- **Notas:** o servidor é autoritativo; o app **nunca** recebe a resposta correta
  antecipada. Animações não-bloqueantes.

---

## 5. Resumo de sessão — produto 3.7

- **Objetivo:** feedback leve de fim de sessão (não é boletim).
- **Conteúdo:** **XP ganho** na sessão; **progressão das palavras** trabalhadas
  (ex.: "relevante" subiu de nível; "vasto" foi **dominada** ✅).
- **NÃO exibir:** percentual de acerto (vira boletim, contra "errar é aprender");
  tempo/velocidade (incentivaria chute).
- **Dados:** retorno de `POST /v1/sessoes/{id}/fim` (resumo + roda adaptação).
- **Navegação:** → Trilha (mapa). **Se há item novo** (cartão/carimbo/selo) →
  o Resumo mostra um **teaser dourado** com CTA "Ver no Passaporte" que abre o
  **Modo Conquista** na hora. **O reveal não é automático** (decisão revisada
  11/06 — não atropelar a leitura do resumo): se o aluno não tocar e seguir
  pra Trilha, o item fica **enfileirado** e o reveal toca ao abrir o
  Passaporte (ver §7). Assim ninguém perde a animação.
- **Notas:** separado da trilha; é o feedback frequente e leve.

---

## 6. Trilha (mapa) — produto 3.7

- **Objetivo:** **aterrissagem pós-sessão**; senso de progresso e próximo passo.
- **Conteúdo:** mapa visual da trilha; **nó atual em destaque** (maior, anel,
  caminho percorrido vivo — **sem selo "você está aqui"**, decisão revisada: a
  própria trilha já comunica a posição pelo progresso); nós do destino;
  agrupamento por **destino** e **país**; próximo nó/destino.
  Estrutura: **País → Destino → Nó** (3 países, 20 destinos, 80 nós).
- **Layout (decisão 13/07 — revisa a janela paginada de 12/07): mapa
  vertical contínuo.** A trilha inteira vive num canvas único de largura 340
  (altura cresce com a trilha): a serpentina de 4 nós por destino (3 comuns +
  o **marco**, medalhão que rende o postal) repete-se de baixo para cima, com
  **portão + faixa de fronteira** entre países. **Scroll vertical livre**
  (progressão simples e contínua — sem paginação, swipe lateral ou chevrons);
  a tela abre **centrada no nó atual**. O carimbo do cabeçalho é o do país
  atual do aluno. Todos os nós ficam no canvas, mas só a viewport é pintada
  pelo scroll.
- **Estados:** **completar nó** → animação (marcador avança + confete), sem item.
  **Completar destino** → cartão-postal (revelado no Passaporte). **Completar
  país** → carimbo (idem). **Modo livre** ao terminar os 3 países (mapa fica no
  último nó; prática continua).
- **Dados:** `GET /v1/trilha` (nó atual, destinos).
- **Navegação:** continuar sessão a partir daqui; abrir Passaporte.
- **Notas:** progressão é por **XP** (não por nº de palavras) — ~4.500 XP/nó,
  1 nó a cada 2–4 sessões.

---

## 7. Passaporte — produto 3.10 + `referencia_arte.md`

É **perfil + coleção** num só lugar (não há tela separada de "achievements").

- **Objetivo:** guardar e exibir a coleção (até 28 peças) e o status do aluno.
- **Dois modos:**
  - **Modo Conquista (animado, dispara 1×):** quando há item novo. Disparo
    (decisão revisada 11/06): pelo **teaser do Resumo** (atalho "Ver no
    Passaporte") **ou**, se o aluno não tocou, ao **abrir o Passaporte** —
    onde uma **fila** de pendências (acúmulo de várias sessões) toca **uma de
    cada vez**. Passaporte sobe em tela cheia, **flip decorativo único**, abre
    **direto na página do item** (não folheia histórico). Cartão = 1 por
    página (página vazia, só o novo anima). Selo = **grid** com os antigos
    estáticos e **só o novo anima** (cai/pulsa/encaixa). Aluno toca → item
    revela e encaixa. Várias pendências → "Próxima lembrança" entre elas.
    Cliente fino: a fila de itens não revelados é, no fim, **autoritativa do
    servidor** (`GET /v1/passaporte` traz os novos; `POST` marca vistos).
  - **Modo Exploração (estático, scroll):** capa (nome + nível) → carimbos de
    países → cartões-postais por país → selos de feitos. Itens não conquistados
    aparecem como **silhueta/cadeado** (mostra o que falta). **Sem animação** ao
    tocar item já ganho.
- **Conteúdo da coleção:** 20 cartões-postais (por destino) + 3 carimbos (por
  país) + 5 selos (feitos: 1ª redação, combo de 10, 25/100/250 palavras).
- **Dados:** `GET /v1/passaporte` (coleção; modos Conquista/Exploração).
- **Navegação:** aberto pelo avatar (Home) ou disparado pelo Resumo.
- **Notas:** itens são **puramente colecionáveis** (sem bônus de gameplay).
  Revelação = animação genérica "abrir com toque", reutilizada nos 28; só o asset
  muda. **Determinístico, sem loot box.**

---

## 8. Telas mockadas/estáticas (fatia A) — produto 08

Presentes na demo, **sem backend real** (rotas mock devolvem dados fixos):

### 8.1 Redação (estática) — produto 4.4
- **Objetivo:** mostrar o **diferencial pedagógico** (redação → vocabulário).
- **Conteúdo:** o texto do aluno **anotado** com marcações coloridas por dimensão
  (vocabulário repetido/fraco, acentuação, vírgula/pontuação, estrutura/coesão);
  área de envio (foto/PDF) **desenhada**, sem OCR/LLM rodando; dashboards de
  correção (da última redação e do ano) com dados fictícios.
- **Dados:** `GET /v1/redacoes` (mock estático).

### 8.2 Superfície do Professor (web) — produto 07 + §3.11
- **Plataforma:** app **web** separado (entrypoint `app/lib/main_professor.dart`),
  reusando o design system; **não entra no bundle do aluno** (regras de isolamento
  em `notas-implementacao.md` → "Professor (web)"). "Professor mobile" é deferido
  até validar com as escolas.
- **Objetivo:** falar com a **coordenação/escola** (quem assina), não só o aluno.
- **Quem vê o quê (§3.11):** professor vê *e configura* as próprias turmas;
  coordenador vê a escola inteira, **só leitura** — **mesmas telas**, via **toggle
  de escopo** (turma↔escola); não há telas separadas de coordenador.
- **Telas:**
  - **Painel da turma** — KPIs (alunos ativos, palavras dominadas na semana, meta
    semanal), **sinal de turma** (palavras fracas recorrentes, §3.5) e lista de
    alunos com o progresso da meta. Inclui o toggle de escopo turma↔escola.
  - **Detalhe do aluno** — drill-down a partir do painel (progresso, palavras
    dominadas, redações do aluno).
  - **Atribuir redação** — tema + prazo à turma (§4.6); é o gatilho da fonte
    pessoal do aluno (fecha o loop redação→vocabulário).
  - **Meta semanal** — configurar a meta da turma (§3.5; só professor configura).
- **Dados (reais desde 13/07 — fatia C):** `GET /v1/professor/turmas`,
  `GET /v1/professor/turmas/{id}/painel`, `GET /v1/professor/escola`,
  `GET /v1/professor/alunos/{id}`, `POST /v1/professor/turmas/{id}/redacoes`
  (persiste `redacao_atribuicao`) e `PUT /v1/professor/turmas/{id}/meta`
  (persiste `turma_config`). Escopo por associação (§3.11); meta com default
  por ano quando não configurada; "semana" = segunda 00:00 (America/Sao_Paulo).
  O **sinal de turma** lê a tabela real, populada só quando o pipeline de
  redação (fatia C de redação) rodar. **Login do professor segue pendente**
  (decisão com a escola cliente, produto §11) — o site roda em `DEMO`/token
  gerado; por isso a seção continua sob "telas mockadas" só neste aspecto.
- **Deferidos** (fast-follow pós-feedback das escolas): redações da turma
  agregadas por dimensão; preset de rigor de redação (§4.3).

### 8.3 Report (mock)
- Já vive **dentro da Sessão** (item 4): caixa de motivo predefinido, sem
  tratamento real na fatia A.

---

## Ordem sugerida de design/implementação

1. **Entrada + Onboarding** (fluxo de entrada; já temos os dados de identidade).
2. **Home-hub** (centro de tudo; consome `/v1/me`).
3. **Sessão + Resumo** (núcleo da prática).
4. **Trilha (mapa)** (aterrissagem; depende de arte de fundo do mapa).
5. **Passaporte** (consome a arte dos colecionáveis — **por último**, quando a
   coleção de imagens estiver mais madura).
6. **Mockadas** (redação/dashboard) — em paralelo, baixo risco.

> Próximos passos depois deste doc: **(1)** definir a **paleta de marca** (própria
> e neutra); **(2)** kit de componentes (botões, cards, tipografia); **(3)** gerar
> mockops por tela; **(4)** portar a direção vencedora para Flutter.
