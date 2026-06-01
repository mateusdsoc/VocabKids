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
- ~~**Quem faz a lematização.**~~ ✅ **Resolvido** (29/05): spaCy (`pt_core_news`)
  confirmado como lematizador, distinto do Hunspell (que só valida existência). Ver
  "Pendências resolvidas" e seção 3.3 do produto.

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
- ~~**Limiar de 10 reports é alto.**~~ ✅ **Resolvido** (29/05): limiar baixado para
  **2** (reversível, pendente de revisão do admin) + **gatilho por taxa de erro**
  independente de report + anti-abuso por veredito do admin (seção 3.6 do produto).
- ~~**Garantia de distrator é suposição, não garantia.**~~ ✅ **Resolvido** (29/05):
  adotada **verificação automática na geração** (2º passo da IA revê distratores
  antes de publicar) no MVP completo (seção 3.6 do produto).

---

## 04 - Riscos arquiteturais

| Risco | Por quê | Severidade |
|---|---|---|
| **LLM como motor único** de seleção + geração + correção de distrator (3.3/3.6) | Ensinar errado para criança. ✅ **Mitigado**: verificação na geração (preventiva) + report (limiar 2) + gatilho por taxa de erro. | Alto → Médio |
| **OCR de caligrafia infantil** alimenta o diferencial central (redação→vocabulário) | OCR ruidoso → extração ruidosa → personalização degrada. Dependência pesada de entrada ruidosa. | Alto |
| ~~**Lematização sem ferramenta definida**~~ | ✅ **Resolvido**: spaCy confirmado (seção 3.3). | — |
| **Sem plano de telemetria** | ✅ **Endereçado**: telemetria decidida (tabela de eventos no Postgres), construída na janela do 1º cliente; habilita calibração e o gatilho de QA. | Médio → Baixo |
| **Auth adiada** | Build de apresentação roda com "código de turma" provisório; migração para o auth real do 1º cliente pode aparecer no início do ano letivo. | Médio (mitigado pela arquitetura agnóstica) |

---

## 05 - Riscos de cronograma / escopo

- **Escopo de MVP grande demais para o rótulo "MVP" (seção 08).** Mobile + web,
  motor adaptativo completo, diagnóstico, pipeline de geração por IA, pipeline de
  OCR + análise multidimensional com anotações coloridas, trilha de 80 nós,
  passaporte com dois modos de animação, dashboards, papéis/permissões, combo de
  XP, meta semanal. O conjunto como "MVP" é um produto inteiro. ✅ **Mitigado** pelo
  fatiamento (apresentável vs. completo, seção 08): a venda só depende do
  apresentável.
- **Arte no caminho crítico.** 28 peças (20 cartões-postais + 3 carimbos +
  5 selos) + animações. O doc reconhece que "o custo real é arte". Dependência de
  ilustração externa é atraso clássico — e bloqueia o passaporte, requisito firme.
  (Ferramenta de animação em aberto; teste da peça-âncora — seção 07.)
- **Equipe enxuta + deadline duro (atualizado 29/05).** Equipe = dono + agentes de
  IA. Cronograma definido (seção 08): apresentável até Set/26, venda Set–Out, completo
  Out–Jan, alunos em **Fev/27 (deadline duro — perdeu, espera o próximo ano)**. O
  risco concreto: a janela **Out–Jan (~3 meses)** concentra o trabalho mais arriscado
  (pipeline de redação, LGPD, auth, testes de carga). Mitigação: regra de corte —
  priorizar o que o aluno toca em fevereiro (prática + redação) sobre o adiável
  (dashboards ricos, eventos).
- **Go-to-market do apresentável (✅ endereçado 29/05).** O comprador (coordenação/
  escola) quer dados de evolução, mas o apresentável é mobile/aluno. Resolvido: o
  apresentável inclui **dashboard e redação mockados** (telas estáticas com dados
  fictícios) para a demo falar com quem assina o contrato (seção 08).
- **Animação no caminho crítico do apresentável (🟠 aberto).** A animação "premium"
  justifica a venda e é construída na janela Jun–Set, mas a ferramenta depende de um
  teste manual do dono ainda não feito (seção 07/stack). Se o teste exigir
  Rive+designer, é custo/tempo batendo na janela do apresentável. Priorizar o teste
  da peça-âncora cedo.

---

## 06 - Recomendações (próximos passos, em ordem)

1. ~~**Decidir a stack**~~ ✅ resolvida (seção 07).
2. ~~**Cronograma com MVP fatiado**~~ ✅ definido (seção 08 do produto): apresentável
   até Set/26 → venda Set–Out → completo Out–Jan → alunos Fev/27. — Separar um "MVP
   apresentável para venda"
   (trilha + questões do banco base + diagnóstico) de um "MVP completo".
   A **redação entra no apresentável de forma estática** — a UI do ciclo (tela de
   redação anotada com cores, dashboard de correção) com dados mockados, **sem**
   OCR/LLM/pipeline rodando. Isso mostra o diferencial e justifica a atenção de
   compra sem construir a parte mais arriscada antes da venda. O pipeline real
   (redação→OCR→análise→atribuição) — de maior risco e maior valor — entra só no
   MVP completo, isolado para não afundar a data de apresentação.
3. ~~**Resolver lematização**~~ ✅ spaCy confirmado (seção 3.3).
4. ~~**Telemetria**~~ ✅ Decidida: tabela de eventos no Postgres, construída na janela
   do 1º cliente (não no apresentável). Habilita calibração e o gatilho de QA.
5. ~~**Endurecer o QA da IA**~~ ✅ Três camadas decididas: verificação na geração
   (preventiva, completo) + report redesenhado (limiar 2 + anti-abuso) + gatilho por
   taxa de erro (seção 3.6).
6. ~~**Corrigir a inconsistência da linha 785**~~ ✅ Corrigida (rev. 13).

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
  peça-âncora (acima). O dono vai testar manualmente.
- **Modelo de LLM** — ⚠️ **ADIADO, não é prioridade agora.** Decidido só na conversa
  com o 1º cliente (junto de auth), com redações reais. Foco atual é funcionalidade
  básica; o apresentável usa redação estática e não chama LLM. Pesquisa já feita
  (decisão 1, seção 10 do produto). Não bloqueia nada — manter atrás de uma
  interface que aceita qualquer provider depois.
  (Lematização foi resolvida — ver "Pendências resolvidas" abaixo.)

### Pendências resolvidas nesta discussão

- ~~Stack técnica (era a maior pendente)~~ → resolvida: Flutter, FastAPI, Postgres
  (Neon), Cloud Run, R2, fila no Postgres.
- ~~Cache/Redis~~ → adiado; fila roda no Postgres.
- ~~Web no MVP~~ → adiada para o MVP completo; apresentável é mobile-only.
- ~~Risco de retrabalho na transição demo→produção~~ → mitigado pelo princípio
  "interface estável, provider variável" + evitar lock-in proprietário.
- ~~Lematização (gap "crítico, mas ferramenta marcada como pós-MVP")~~ → resolvida:
  **spaCy** (`pt_core_news`) confirmado, só no MVP completo, usado como chave de
  indexação/dedup (nunca no texto da questão — a IA flexiona na geração); Hunspell
  valida existência, papel distinto. Coexistem no pipeline de entrada de palavra.
- ~~QA da IA (distrator "garantido" no prompt; 10 reports é alto)~~ → resolvido: três
  camadas (verificação na geração + report com limiar 2 e anti-abuso + gatilho por
  taxa de erro). Seção 3.6 do produto.
- ~~Telemetria (sem plano de coleta)~~ → decidida: tabela de eventos no Postgres,
  construída na janela do 1º cliente (não no apresentável). Habilita calibração dos
  limiares e o gatilho de QA por taxa de erro.
