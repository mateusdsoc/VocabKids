# Análise de Riscos e Gaps — VocabBR Kids

> Análise crítica do estado atual do projeto: o que falta decidir, como está a
> arquitetura, pontos a melhorar e riscos (arquiteturais e de cronograma).
>
> Base: `rascunho_product.md` (rev. 12) e `pesquisa_ferramentas.md`.
> Data: 29 de maio de 2026.
>
> Este documento é uma análise, não uma decisão de produto. As decisões
> continuam em `rascunho_product.md`.

---

## 00 - Enquadramento

O repositório hoje é **só documentação de produto** — não há código, schema,
stack definida nem cronograma. O documento de produto é forte (12 revisões,
internamente coerente, com tabela de decisões fechadas que evita rediscussão).
A análise abaixo é deliberadamente crítica: foca no que falta e no que pode dar
errado, não no que já está bom.

---

## 01 - O que ainda falta decidir

### Decisões explicitamente em aberto (seções 09 e 10), por impacto

- **Stack técnica (seção 09).** Maior decisão pendente — trava tudo. O MVP exige
  mobile (iOS+Android) **e** web. Sem decidir framework e backend não há como
  estimar esforço, contratar ou dimensionar cronograma. **Resolvida** na discussão
  de 29/05 — ver seção 07 deste documento.
- **Cronograma — não existe.** Não há milestones, tamanho de equipe nem datas de
  build. A única referência temporal é o ciclo de venda (out/nov → fev) e
  "2 semanas folgado" entre a escola aceitar e implementar — mas isso é prazo de
  *deploy para uma escola nova*, não de *construir o MVP*.
- **Modelo de IA para redação/geração (decisão 1).** Bem encaminhada — plano de
  testar 3 modelos com redações reais é o certo. Baixo risco.
- **Auth e privacidade (decisão 2).** Adiar até o primeiro cliente é defensável
  *porque* a arquitetura é auth-agnóstica (identidade + associações). Aceitável,
  com ressalva (ver riscos).

### Gaps não listados como "em aberto" (e que deveriam estar)

- **Algoritmo do diagnóstico inicial.** "10–15 questões posicionam o aluno na
  escala 1–10", mas a lógica de mapeamento não existe.
- **Comportamento offline.** App para crianças em escola, conectividade variável.
  Geração assíncrona no "miss" (3.3), download de conteúdo de evento (06) e envio
  de redação assumem rede. Sessão sem internet não é tratada.
- **Telemetria/analytics.** O documento repete "ajustável com dados reais"
  (limiar de 30% do sinal de turma, XP, dimensionamento da trilha, adaptação
  contínua) sem nenhum plano de instrumentação para *coletar* esses dados.
- **Quem faz a lematização.** A seção 3.3 chama normalização de "crítico" e cita
  "Hunspell ou um lematizador". Hunspell é corretor ortográfico, não lematizador;
  a ferramenta que de fato lematiza (spaCy) está marcada como "não necessária no
  MVP". Algo crítico depende de uma ferramenta classificada como pós-MVP.

---

## 02 - Como está a arquitetura

**Forte conceitualmente, inexistente concretamente.** Não há schema, contrato de
API, diagrama ou stack — apenas decisões arquiteturais embutidas no texto. Como
*direção*, as escolhas são boas:

- **Identidade + associações (3.11)** — resolve professor em duas escolas e
  coordenador-que-leciona sem papel híbrido, e desacopla de auth.
- **Banco compartilhado, dados de aluno isolados (3.5)** — boa decisão de custo e
  escala.
- **Geração lazy (3.3)** — padrão correto, sem replicação nem expiração.
- **Extensibilidade para sintaxe (3.8/4.2)** — requisito de design, não de prazo.
- **XP adaptativo nunca zera vs XP visível reseta para a média (3.9)** — distinção
  madura.

O salto que falta é do *spec de produto* para o *design técnico*. O próximo
artefato necessário é um modelo de dados + desenho dos pipelines
(redação → OCR → análise → extração → geração → atribuição).

---

## 03 - Pontos a melhorar / inconsistências concretas

- **Inconsistência "regressão controlada".** A seção 08 (linha 785) lista o MVP
  com "sequência fixa e **regressão controlada**", mas a seção 3.4 e a tabela de
  decisões dizem o oposto: "**Não há regressão**". O resumo do escopo contradiz a
  mecânica detalhada.
- **Acoplamento geração lazy × estrutura rígida da sessão.** A sessão é
  determinística (2 palavras novas, arranjo fixo). No "miss" a palavra é gerada
  assincronamente e "aparece depois". Falta a regra de fallback (provavelmente:
  puxar do banco base enquanto a personalizada não fica pronta — não está dito).
- **Limiar de 10 reports é alto.** Para palavras pouco atribuídas, uma questão
  ruim pode nunca atingir 10 reports. Considerar limiar relativo (% de quem
  respondeu) ou sinal mais barato (ex.: alta taxa de erro na 1ª tentativa).
- **Garantia de distrator é suposição, não garantia.** "A IA garante que nenhum
  distrator é secretamente correto" é frágil para sinônimos, dependentes de
  contexto. Vale verificação automática leve na geração, não só confiar no prompt.

---

## 04 - Riscos arquiteturais

| Risco | Por quê | Severidade |
|---|---|---|
| **LLM como motor único** de seleção + geração + correção de distrator, publicado direto sem revisão (3.3/3.6) | Ensinar errado para criança. Report é controle pós-publicação e só a partir de 10 reports. | Alto |
| **OCR de caligrafia infantil** alimenta o diferencial central (redação→vocabulário) | OCR ruidoso → extração ruidosa → personalização degrada. Dependência pesada de entrada ruidosa. | Alto |
| **Lematização sem ferramenta definida** | Crítico para o MVP, ferramenta certa marcada como pós-MVP. Sem isso o banco acumula quase-duplicatas. | Médio-alto |
| **Sem plano de telemetria** | Quase todo limiar é "ajustável com dados reais" sem meio de coletá-los. | Médio |
| **Auth adiada** | Build de apresentação roda com "código de turma" provisório; migração para o auth real do 1º cliente pode aparecer no início do ano letivo. | Médio (mitigado pela arquitetura agnóstica) |

---

## 05 - Riscos de cronograma / escopo

- **Escopo de MVP grande demais para o rótulo "MVP" (seção 08).** Mobile + web,
  motor adaptativo completo, diagnóstico, pipeline de geração por IA, pipeline de
  OCR + análise multidimensional com anotações coloridas, trilha de 72 nós,
  passaporte com dois modos de animação, dashboards, papéis/permissões, combo de
  XP, meta semanal. O conjunto como "MVP" é um produto inteiro.
- **Arte no caminho crítico.** 26 peças (18 cartões-postais + 3 carimbos +
  5 selos) + animações. O doc reconhece que "o custo real é arte". Dependência de
  ilustração externa é atraso clássico — e bloqueia o passaporte, requisito firme.
- **Equipe não dimensionada.** Se for fundador solo, o escopo acima é incompatível
  com prazo curto.

---

## 06 - Recomendações (próximos passos, em ordem)

1. **Decidir a stack** — destrava estimativa, cronograma e contratação.
2. **Cronograma com MVP fatiado** — separar um "MVP apresentável para venda"
   (trilha + questões do banco base + diagnóstico) de um "MVP completo".
   A **redação entra no apresentável de forma estática** — a UI do ciclo (tela de
   redação anotada com cores, dashboard de correção) com dados mockados, **sem**
   OCR/LLM/pipeline rodando. Isso mostra o diferencial e justifica a atenção de
   compra sem construir a parte mais arriscada antes da venda. O pipeline real
   (redação→OCR→análise→atribuição) — de maior risco e maior valor — entra só no
   MVP completo, isolado para não afundar a data de apresentação.
3. **Resolver lematização** (escolher spaCy ou equivalente; tirar do limbo).
4. **Telemetria como requisito de MVP** — sem ela, nenhum "ajustaremos com dados"
   acontece.
5. **Endurecer o QA da IA** — verificação de distrator na geração + gatilho de
   revisão por taxa de erro, não só 10 reports.
6. **Corrigir a inconsistência da linha 785** ("regressão controlada").

---

## 07 - Stack técnica (direção definida)

> Direção de stack acordada na discussão de 29/05/2026. Vira decisão fechada
> quando migrar para `rascunho_product.md` (seção 09 lista "stack técnica fechada"
> como fora do escopo atual — esta seção a resolve).

### Resumo

| Camada | Decisão | Observação |
|---|---|---|
| **App do aluno** | **Flutter** | Mobile-only no MVP apresentável. |
| **Web (dashboards)** | **React/Next separado** | Adiado para o MVP completo. Não compartilha codebase com o app. |
| **Backend** | **Python + FastAPI** | Escolha aberta de equipe; vence pelo ecossistema de IA/NLP e carga I/O-bound. |
| **Banco de dados** | **PostgreSQL** | JSONB p/ payload de questão; pgvector disponível p/ dedup semântico. |
| **Fila de jobs** | **Postgres-backed** (`procrastinate`) | Roda dentro do Postgres existente. Redis **adiado** (ver abaixo). |
| **Cache** | **Adiado** | Sem pressão de cache no MVP. Upstash (serverless) quando precisar. |
| **Animações** | **Em aberto** | Requisito (animação boa) é firme desde o apresentável; ferramenta decidida via teste da peça-âncora (ver abaixo). |
| **Banco gerenciado** | **Neon** | Postgres serverless puro (scale-to-zero/free tier). Preferido a Supabase para evitar lock-in (ver abaixo). |
| **Compute** | **Cloud Run (GCP)** | Escala a zero; production-grade. Render/Railway são alternativas mais simples. |
| **Storage de arquivos** | **Cloudflare R2** | API S3-compatível; sem taxa de egress. Fotos/PDFs de redação. |
| **Região** | `southamerica-east1` (São Paulo) | Residência de dados (crianças BR) — alinhado à LGPD adiada. |

### Princípio que protege de retrabalho: interface estável, provider variável

A escolha de free tier **não cria uma "stack de demonstração" descartável.** É a
**mesma stack**, com o *plano* trocado. As ferramentas expõem **interfaces-padrão**
e o código fala com a interface, não com o provider:

| Camada | Interface (não muda) | Demo (free) → Produção |
|---|---|---|
| Banco | protocolo **Postgres** | Neon free → Neon pago / Cloud SQL / RDS — troca a connection string |
| Compute | container **Docker** | Cloud Run free → Cloud Run com `min-instances` / GKE — troca o deploy target |
| Arquivos | **API S3** | R2 → R2 pago / S3 / GCS — troca endpoint + credencial |
| Fila | Postgres (`procrastinate`) | continua no Postgres até bem longe |

Consequências:

- **Promover demo → produção é um config change** (connection string, env var,
  plano de cobrança, ligar `min-instances` p/ matar cold start), **não uma
  reescrita.** Não se implementa nada à toa.
- Neon, Cloud Run e R2 **já são production-grade** — "ir para a stack definitiva"
  na maioria dos casos é **subir de plano no mesmo provider**. O aluno usa o mesmo
  serviço, no plano pago; nunca toca no free tier como tecnologia.
- **O refactor doloroso mora no lock-in proprietário**, não no free tier. Por isso
  ficamos em interfaces abertas (Postgres, Docker, S3) e **preferimos Neon a
  Supabase**: Supabase por baixo é Postgres, mas sua graça é a camada proprietária
  (auth, storage SDK, edge functions) — usá-la amarra e gera o retrabalho que se
  quer evitar.
- Única troca *real* possível no futuro: a fila (`procrastinate` → Celery/Redis).
  Provavelmente desnecessária cedo e, escondendo o "enfileirar job" atrás de uma
  função fina, fica contida em um arquivo.

**Estratégia: free-tier-first sobre interfaces abertas até ~2 escolas vendidas;
depois, subir de plano no mesmo provider.** $0 de custo variável na demo (o
apresentável com redação estática nem chama OCR/LLM), código idêntico em produção.

### Racional

- **Flutter (app do aluno).** A UI é 100% custom (trilha, passaporte, cards,
  animações) — não usa widget nativo de plataforma. Nesse cenário o "muito
  Android" do Flutter não se aplica: a renderização própria (Impeller) entrega
  design premium idêntico em iOS e Android com ótima performance de animação. O
  receio do "cheiro de Android" vale para apps que imitam o nativo comum, não para
  um app gamificado de marca própria.
- **Web como codebase separado, adiada.** A web do MVP completo são os dashboards
  de educador/admin (data-heavy, tabelas, gráficos, redação anotada) — perfil
  oposto ao app gamificado. React/Next é a ferramenta certa para essa surface;
  forçar Flutter Web nos dashboards seria uma armadilha. Como a web não entra no
  MVP apresentável, isso reforça o fatiamento (seção 06, recomendação 2): o
  apresentável é só mobile.
- **Python + FastAPI.** As partes difíceis do produto vivem no ecossistema Python
  (orquestração de LLM, spaCy para lematização, Hunspell, glue de NLP, orquestração
  de OCR). A carga é I/O-bound e de baixo QPS (escolas), então o ponto fraco do
  Python (GIL/CPU-bound) não morde — o trabalho pesado é delegado a APIs externas e
  libs nativas. Go/Java resolveriam um problema de throughput que o produto não tem.
- **PostgreSQL.** Domínio fortemente relacional (usuário, associação, turma,
  palavra, questão, atribuição, estado de domínio, redação, report). JSONB guarda o
  payload flexível da questão gerada pela IA; pgvector fica disponível se houver
  dedup semântico no banco de palavras.
- **Fila no Postgres, Redis adiado.** O apresentável não tem pipeline assíncrono
  (redação estática, questões do banco base já prontas) — sem fila nem cache. No
  MVP completo, a fila de jobs (geração lazy, OCR+análise, sinal de turma) roda
  **dentro do Postgres** via `procrastinate` (`FOR UPDATE SKIP LOCKED`),
  eliminando um serviço inteiro. Redis gerenciado tem mau custo/benefício em escala
  pequena (Memorystore cobra ~US$35–50/mês ocioso); quando houver pressão real de
  cache/throughput, **Upstash** (serverless, paga por uso) é a melhor opção. Adiar
  até precisar.
- **Animações: ferramenta em aberto, requisito firme.** A animação boa é necessária
  **desde o apresentável** (é o que justifica a venda), então o *resultado* não se
  adia — só a *ferramenta*. A tensão honesta: "premium" + "sem designer" + "sem
  gastar" não fecham os três juntos. Opções: (a) **LottieFiles** (assets prontos,
  grátis, mas genéricos); (b) **código Flutter** (`flutter_animate`, `confetti`) —
  bom para movimento/transições e bem escrito por IA, fraco para personagem
  ilustrado; (c) **Rive** — premium, mas a IA do Rive (MCP server, Early Access) só
  faz *scaffolding de state machine* (a lógica), **não gera a arte**: ainda exige a
  ilustração riggada por um humano no editor; (d) **freelancer** para as peças-âncora
  ($$); (e) vídeo IA (Runway/Veo) — premium, mas é vídeo (pesado, não interativo).
  **Decisão adiada via teste da peça-âncora**: prototipar a revelação do passaporte
  por Lottie pronto vs. código Flutter; se "vender", fecha barato; se não, abre a
  conversa de Rive+designer/freelancer.
- **Compute Cloud Run; banco em Neon; arquivos em R2.** O custo real em escala
  pequena é o **banco gerenciado**, não o compute: Cloud SQL cobra mínimo ocioso,
  enquanto **Neon** escala a zero com free tier. Compute no **Cloud Run** (escala a
  zero, production-grade) ou PaaS mais simples (Render/Railway). Arquivos de redação
  em **Cloudflare R2** (API S3, sem egress). Não há trava no GCP: chamar o Google
  Vision é só uma API call de qualquer lugar. Região `southamerica-east1` por
  residência de dados (crianças BR), alinhada à decisão de LGPD/privacidade adiada
  (seção 10 do produto). **Atenção a cold start** em serviços scale-to-zero: ligar
  `min-instances=1` na hora de apresentar/produção.

### Em aberto na stack (pendências que sobraram)

- **Ferramenta de animação** — requisito firme, ferramenta a decidir pelo teste da
  peça-âncora (acima).
- **Modelo de LLM** para análise/geração — segue como decisão 1 da seção 10 do
  produto (testar GPT-4o mini, Gemini 2.5 Flash-Lite e Gemini 2.5 Flash com redações
  reais).
- **Lematização** — recomendação **spaCy** (`pt_core_news`); falta confirmar e tirar
  do limbo "pós-MVP" (ver seções 01 e 06).

### Pendências resolvidas nesta discussão

- ~~Stack técnica (era a maior pendente)~~ → resolvida: Flutter, FastAPI, Postgres
  (Neon), Cloud Run, R2, fila no Postgres.
- ~~Cache/Redis~~ → adiado; fila roda no Postgres.
- ~~Web no MVP~~ → adiada para o MVP completo; apresentável é mobile-only.
- ~~Risco de retrabalho na transição demo→produção~~ → mitigado pelo princípio
  "interface estável, provider variável" + evitar lock-in proprietário.
