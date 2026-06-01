# Arquitetura Técnica — VocabBR Kids

> Design técnico do produto. Construído em **blocos** para revisão incremental:
>
> - **Bloco 1 — Modelo de dados** ✅
> - **Bloco 2a — Pipelines do apresentável** (sessão + diagnóstico) ✅
> - **Bloco 2b — Pipelines do completo** (redação→OCR→análise→geração→atribuição; QA; sinal de turma) ⏳
> - **Bloco 3 — Estrutura do app e serviços** ⏳
>
> Fonte da verdade de produto: `rascunho_product.md`. Decisões de stack: seção 12 de lá.
> Racional de riscos: `analise_riscos.md`.
>
> Stack-base (seção 12 do produto): PostgreSQL (Neon), backend Python/FastAPI, fila
> `procrastinate` no Postgres, arquivos no R2, app Flutter.
>
> Data: 29 de maio de 2026.

---

## Bloco 1 — Modelo de dados

### Princípios

1. **Relacional (PostgreSQL).** O domínio é fortemente relacional. `JSONB` só onde o
   formato é flexível (payload de questão, anotações de redação, payload de evento).
2. **Fronteira de isolamento (seção 3.5 do produto):**
   - **Compartilhado entre escolas (global):** banco de vocabulário (`palavra`,
     `sinonimo`, `questao`), reports de questão (agregam entre escolas) e o conteúdo
     da trilha/colecionáveis (catálogo).
   - **Isolado por escola:** tudo do aluno — estado de aprendizado, progresso, XP,
     redações, eventos de telemetria. O isolamento se dá via `usuario → associacao →
     escola`.
3. **Auth-agnóstico (seção 3.11).** `usuario` guarda identidade mínima; o vínculo com
   escola é `associacao` (membership). O flow de auth real entra na janela do 1º
   cliente sem alterar o esquema.
4. **Fase:** cada tabela marca **A** (existe no apresentável) ou **C** (entra no
   completo). No apresentável, redação/dashboard/report são **mockados** — as tabelas
   marcadas "C (mock em A)" podem existir vazias/fixas para a demo, sem backend.

### Convenções

- PK `id BIGINT GENERATED ALWAYS AS IDENTITY` (ou UUID — a confirmar; ver questões).
- `created_at TIMESTAMPTZ NOT NULL DEFAULT now()` em todas as tabelas.
- FKs com `ON DELETE` explícito (definido por tabela; soft-delete onde fizer sentido).
- Enums via tabelas de domínio ou `CHECK`/tipo enum do Postgres (a confirmar).

**Nível de detalhe deste documento.** Este é o modelo **conceitual/lógico**: entidades,
relacionamentos, decisões e os **campos que carregam significado de produto** (ex.:
`palavra_gatilho`, `origem`, `estado`, `veredito`). **Não** lista toda coluna — a lista
exaustiva (tipos, `NOT NULL`, índices, defaults) vive nas **migrations SQL** (código),
que são a verdade real do banco. Critério para um campo entrar aqui: um revisor precisa
dele para validar a lógica do produto.

---

### 1. Identidade e organização

| Tabela | Campos-chave | Notas | Fase |
|---|---|---|---|
| `usuario` | `id`, `nome`, `email` (nullable), `auth_provider` (nullable), `auth_subject` (nullable) | Identidade mínima, auth-agnóstica. Aluno sem e-mail é válido (`email` null). Campos de auth ficam nulos até a janela do 1º cliente. | A |
| `escola` | `id`, `nome` | Raiz do isolamento de dados. | A |
| `turma` | `id`, `escola_id→escola`, `nome`, `ano_escolar` (6–9), `codigo_turma` (unique) | `codigo_turma` é o acesso provisório (seção 3.5). | A |
| `associacao` | `id`, `usuario_id→usuario`, `escola_id→escola` (nullable p/ admin), `papel` (`aluno`\|`professor`\|`coordenador`\|`admin`) | Membership. Um usuário pode ter várias (professor em 2 escolas; coordenador que também leciona). Admin: `escola_id` null. | A |
| `associacao_turma` | `associacao_id→associacao`, `turma_id→turma` | Liga associação a turma(s). Aluno: 1 linha. Professor: N linhas. Coordenador/admin: 0 (escopo é a escola/global). | A |

**Permissão = (papel, escopo, capacidade)** (seção 3.11) é resolvida em código a
partir dessas tabelas — não é uma tabela. Ver não precisa de linha extra; "configurar/
agir" é exclusivo de `professor` nas suas turmas.

---

### 2. Banco de vocabulário — **compartilhado entre escolas**

| Tabela | Campos-chave | Notas | Fase |
|---|---|---|---|
| `palavra` | `id`, `lema` (unique), `definicao`, `exemplo_uso`, `nivel_dificuldade` (1–10), `audio_url` (nullable), `origem` (`banco_base`\|`redacao`) | Chave de busca/dedup é o **lema** (spaCy normaliza antes de inserir — seção 3.3). `definicao` + `exemplo_uso` + `audio_url` são o conteúdo do **card de descoberta** (seção 3.2). Global. | A |
| `palavra_sinonimo` | `palavra_id→palavra`, `texto` | 2–3 por palavra (seção 3.3). | A |
| `questao` | `id`, `palavra_id→palavra`, `nivel` (1–4), `variacao` (`a`\|`b`…), `enunciado`, `opcoes` (JSONB), `resposta_correta`, `status` (`ativa`\|`oculta_report`\|`em_revisao`\|`removida`) | Mín. 2 variações por nível. Recurso do **banco**, não do aluno (seção 3.6). `opcoes` em JSONB (enunciado/distratores). Global. | A |
| `report_questao` | `id`, `questao_id→questao`, `usuario_id→usuario` (reporter), `motivo` (enum), `veredito` (`pendente`\|`valido`\|`invalido`), `resolved_at` (nullable) | Agrega entre escolas (seção 3.6). Veredito do admin alimenta o anti-abuso. | C (mock em A) |

**Auto-ocultar (regra, seção 3.6):** `questao.status → oculta_report` quando a
contagem de reports **que contam** atinge **2** (limiar inicial/ajustável). "Que
contam" = reports cujo autor não está penalizado e que não foram julgados `invalido`.
A penalização do autor (descontar reports) é derivada da taxa de vereditos `invalido`
por `usuario` — computada, não armazenada como flag fixa (mas pode ser materializada
para performance; ver questões).

---

### 3. Estado de aprendizado do aluno — **isolado por escola**

| Tabela | Campos-chave | Notas | Fase |
|---|---|---|---|
| `aluno_palavra` | `id`, `usuario_id→usuario`, `palavra_id→palavra`, `estado` (`descoberta`\|`nivel_1..4`\|`dominada`), `origem` (`pessoal_redacao`\|`sinal_turma`\|`banco_base`), `palavra_gatilho` (nullable), `atribuida_em`, `dominada_em` (nullable) | Estado de domínio por aluno (seção 3.4). `palavra_gatilho` só em origem pessoal (seção 3.2). | A |
| `aluno_questao` | `usuario_id→usuario`, `questao_id→questao`, `tentativas`, `acertou` (bool), `acertou_primeira` (bool), `respondida_em` | Garante "nunca repergunta variação já acertada" (seção 3.4) e alimenta XP/combo. | A |

A **composição da sessão** (12 questões, 2 palavras novas, intercalação de erros,
nível 4 adiado — seção 3.4) é **lógica de runtime** (Bloco 2), lida desses estados.
Não há tabela "sessão de questões fixa"; a sessão é montada na hora.

---

### 4. Progressão, XP e recompensas — **isolado por escola**

| Tabela | Campos-chave | Notas | Fase |
|---|---|---|---|
| `aluno_progresso` | `usuario_id→usuario` (PK), `xp_total`, `no_atual_id→trilha_no`, `palavras_dominadas` (contador), `combo_atual`, `combo_data` (date) | 1:1 com aluno. `combo` zera por dia e ao errar/2ª tentativa (seção 3.7). Contador de dominadas para a home (seção 3.7). | A |
| `aluno_colecionavel` | `usuario_id→usuario`, `colecionavel_id→colecionavel`, `ganho_em` | Até 26 por aluno (passaporte, seção 3.10). Booleano (ganhou/não). | A |

> **XP de evento** (seção 3.9) é uma economia separada e **pós-MVP** — não modelado
> aqui; entra junto de `evento_competicao`/`participacao` quando eventos entrarem.

---

### 5. Trilha e colecionáveis — **conteúdo (catálogo global)**

Conteúdo, não dado de aluno. ~80 nós + 28 peças (seção 3.7/3.10), praticamente fixo.

| Tabela | Campos-chave | Notas | Fase |
|---|---|---|---|
| `pais` | `id`, `nome`, `ordem` | MVP: Brasil, França, Japão. Egito engatilhado como reserva. | A |
| `destino` | `id`, `pais_id→pais`, `nome`, `ordem` | Assimétrico por país: 5 (BR), 7 (FR), 8 (JP) — substitui o antigo `ponto_turistico`. | A |
| `trilha_no` | `id`, `destino_id→destino`, `ordem`, `xp_limiar` (~4.500) | 4 por destino → 80 nós. | A |
| `colecionavel` | `id`, `tipo` (`cartao_postal`\|`carimbo`\|`selo`), `referencia` (destino/país/feito), `asset_ref` | Catálogo das 28 peças. | A |

---

### 6. Redações — **isolado por escola** (núcleo do completo)

| Tabela | Campos-chave | Notas | Fase |
|---|---|---|---|
| `redacao_atribuicao` | `id`, `turma_id→turma`, `professor_associacao_id→associacao`, `tema`, `prazo` | Professor atribui à turma (seção 4.6). | C (mock em A) |
| `redacao` | `id`, `atribuicao_id→redacao_atribuicao`, `usuario_id→usuario`, `formato` (`manuscrita`\|`digital`), `arquivo_ref` (R2), `texto_extraido`, `status`, `enviada_em`, `analisada_em` (nullable) | Aluno envia (foto/PDF). `arquivo_ref` aponta p/ R2. | C (mock em A) |
| `redacao_analise` | `redacao_id→redacao`, `anotacoes` (JSONB por dimensão) | Multidimensional (seção 4.2). Anotações coloridas vêm daqui. | C (mock em A) |
| `redacao_palavra` | `id`, `redacao_id→redacao`, `texto`, `lema`, `tipo` (`fraca`\|`superutilizada`), `virou_atribuicao` (bool) | Palavras extraídas que alimentam a trilha (seção 4.5). `lema` via spaCy. | C |
| `sinal_turma` | `turma_id→turma`, `palavra_id→palavra`, `periodo`, `pct`, `computado_em` | Palavra fraca/superutilizada em ≥30% da turma (seção 3.5). Computado/materializado. | C |

---

### 7. Configuração de turma — **isolado por escola**

| Tabela | Campos-chave | Notas | Fase |
|---|---|---|---|
| `turma_config` | `turma_id→turma` (PK), `meta_semanal` (nullable), `preset_rigor` (JSONB) | Meta em palavras dominadas/semana; default por ano se null (seção 3.5). Preset de dimensões de redação (seção 4.3). Só professor configura. | C (default em A) |

---

### 8. Telemetria — **isolado por escola**

| Tabela | Campos-chave | Notas | Fase |
|---|---|---|---|
| `sessao` | `id`, `usuario_id→usuario`, `iniciada_em`, `finalizada_em` (nullable), `xp_ganho` | Uma prática. | C |
| `evento` | `id`, `usuario_id→usuario` (nullable), `tipo`, `payload` (JSONB), `created_at` | Log de eventos (seção 07 do produto). Calibra limiares e alimenta o gatilho de QA por taxa de erro. Tabela no próprio Postgres (LGPD). | C |

> **Distinção importante (seção 07 do produto):** o estado operacional que a adaptação
> e o diagnóstico leem está em `aluno_palavra`/`aluno_questao`/`aluno_progresso`
> (existe no apresentável). `sessao`/`evento` são a camada de **analytics**, adiada.

---

### Diagrama de relacionamentos (visão macro)

```
escola ──< turma ──< associacao_turma >── associacao >── usuario
   │                                                        │
   │                                          ┌─────────────┼───────────────┐
   │                                          │             │               │
   │                                    aluno_palavra  aluno_questao   aluno_progresso
   │                                          │                              │
   │                                     palavra ──< palavra_sinonimo        └─> trilha_no
   │                                          │                                    │
   │                                       questao ──< report_questao        destino
   │                                          │                                    │
   │                                  (compartilhado global)                    pais
   │
   └──< redacao_atribuicao ──< redacao ──< redacao_palavra
                                  │
                            redacao_analise        aluno_colecionavel >── colecionavel

   (global/compartilhado: palavra, palavra_sinonimo, questao, report_questao,
    pais, destino, trilha_no, colecionavel)
   (isolado por escola: tudo ligado a usuario/turma/redacao/evento)
```

---

### Isolamento, multitenancy e leaderboards

**"Isolado por escola" = isolamento lógico, não banco separado.** Um único
PostgreSQL; as linhas de aluno são vinculadas a uma escola via `usuario → associacao
→ escola`. "Isolado" significa que a escola A **não lê os dados de aluno da escola B**
— imposto por escopo de query (e, opcionalmente, Row-Level Security do Postgres).

**Leaderboards não violam o isolamento** porque cada um é uma agregação dentro de um
escopo permitido:

| Leaderboard | Escopo | Cruza escolas? |
|---|---|---|
| Top 3 da turma (seção 3.9) | uma turma (mesma escola) | Não |
| Contribuintes da escola (eventos) | uma escola | Não |
| Posição entre escolas (eventos) | **só a soma de XP** por escola | Sim, **só agregado** |

O caso "entre escolas" só expõe o **agregado** (soma do XP da escola), nunca uma linha
individual — coerente com a seção 3.9. Não exige tabela nova: o top-3 da turma é uma
query sobre `aluno_progresso.xp_total` + `associacao_turma`. A regra "aluno vê só top 3
+ o próprio XP" é **autorização/apresentação**, não esquema. O **XP de evento** é
economia separada (seção 3.9) e pós-MVP — entra numa tabela de participação própria.

### Decisões do Bloco 1 (resolvidas 31/05)

1. **PK:** `BIGINT GENERATED ALWAYS AS IDENTITY` (não UUID — sem sincronização offline
   forte prevista).
2. **`questao.opcoes`:** `JSONB` (questão lida sempre inteira; QA usa taxa de erro da
   questão, não por opção).
3. **Penalização de reporter:** computada on-the-fly a partir da taxa de vereditos
   `invalido`; materializar em `usuario.report_trust` só se a query pesar.
4. **Schema único:** as tabelas de redação/report **existem no apresentável** (a UI
   mockada não grava nelas) — evita migração dupla entre as fatias A e C.
5. **Entidades:** conjunto do Bloco 1 considerado completo para o MVP (sem lacuna
   apontada na revisão). Leaderboard não exige entidade nova (acima).

---

## Bloco 2a — Pipelines do apresentável (sessão + diagnóstico)

Os fluxos de runtime da fatia A (fase Jun–Set). Tudo aqui usa **só o banco base**
(seção 3.5): no apresentável não há redação pessoal nem sinal de turma — essas fontes
entram no Bloco 2b. Estes fluxos leem/escrevem em `aluno_palavra`, `aluno_questao`,
`aluno_progresso` (estado **operacional**, não telemetria — seção 07 do produto).

### Visão geral

```
Onboarding (1x) ─→ Diagnóstico ─→ define nivel_dificuldade_atual
                                         │
        ┌────────────────────────────────┘
        ▼
   Loop de sessões ─→ montar_sessao() ─→ responder (XP/combo) ─→ resumo ─→ adaptação contínua
```

### Estado de uma palavra para o aluno (máquina de estados)

Reflete `aluno_palavra.estado` (seção 3.4). Sem regressão; loop no nível até acertar.

```
descoberta ─(card visto)→ nivel_1 ─✓→ nivel_2 ─✓→ nivel_3 ─✓→ [aguarda N4 ~2 sessões] ─✓→ dominada
   (errou em qualquer Nx: permanece em Nx; a outra variação volta ao fim da fila)
```

O **nível 4 não acontece na sessão de introdução** — fica agendado (ver "Adiamento do
nível 4"). Por isso o estado pós-N3 é "nivel_3 com N4 pendente", não "dominada".

### Composição da sessão — `montar_sessao(aluno)`

Produz uma **fila ordenada** de ~10–12 slots (cards não contam como questão). Caminho
feliz segue o exemplo da seção 3.4:

```
1. novas ← 2 palavras novas do banco base no nivel_dificuldade_atual do aluno
           (ordem dentro do nível tem pouco impacto — seção 3.5)
2. Para cada palavra nova p (cards agrupados no início, colados às 1ªs questões — 3.2):
       fila += [CARD(p), Q(p, n1), Q(p, n2)]
3. Para cada palavra nova p:
       fila += [Q(p, n3)]           # N3 das duas vem depois dos blocos de card
4. revisao ← selecionar_revisao(aluno)     # ~4 slots; ver abaixo
   Para cada palavra r em revisao:
       fila += [Q_revisao(r)]              # questão de revisão vem ANTES do N4 (3.4)
       se r.n4_vencido: fila += [Q(r, n4)]
5. Se faltam slots de revisão (aluno recém-diagnosticado, poucas palavras em progresso):
       completar com mais palavras novas do banco base (3.4)
```

Resultado típico: `[Card p1, p1N1, p1N2, Card p2, p2N1, p2N2, p1N3, p2N3, +4 revisão]`.

### Mecânica da fila — intercalação de erros (seção 3.4)

A sessão é uma **fila de slots pendentes**. Regra ao responder:

- **Acertou** → slot sai da fila; marca `aluno_questao.acertou`; se foi a 1ª variação
  correta daquele nível, o nível avança (`aluno_palavra.estado`).
- **Errou** → a **outra variação ainda não acertada** do mesmo nível vai para o **fim
  da fila** (intercala). Nunca se repergunta variação já acertada (`aluno_questao`).
- **Único slot pendente** → entra em **loop fixo imediato**, alternando as variações
  não acertadas até acertar (não há com o que intercalar).

Como tudo é múltipla escolha, o aluno sempre acaba acertando; o custo do erro é tempo
(seção 3.4) — e zera o combo (abaixo).

### Seleção de revisão — `selecionar_revisao(aluno)`

Candidatas: palavras **em progresso** (introduzidas, não dominadas). Prioriza as com
**N4 vencido** (ver adiamento). Para cada palavra, escolhe a questão de revisão por
prioridade (seção 3.4):

1. Variação não usada do **nível 2**;
2. Se as duas do N2 esgotaram → variação não usada do **nível 3** (e vice-versa);
3. Se N2 e N3 esgotaram → repete a errada do N2; errando, a do N3; alternando.

**Nível 1 nunca** vira revisão (seção 3.4).

### Adiamento do nível 4 (seção 3.4)

Quando uma palavra passa o N3, seu N4 é **agendado para ~2 sessões à frente**. O N4
vencido entra no bloco de revisão da sessão futura, precedido por uma questão de
revisão da própria palavra. Mecânica proposta (ver ajustes ao modelo):

- Ao completar o N3: `aluno_palavra.nivel4_agendado_para = aluno_progresso.sessoes_total + 2`.
- `montar_sessao` considera "N4 vencido" quando `sessoes_total >= nivel4_agendado_para`.

### XP e combo no momento da resposta (seção 3.7)

Calculado a cada acerto e persistido em `aluno_progresso`:

```
xp_base = 100 (1ª tentativa) | 70 (2ª) | 50 (3ª+, piso)
combo:   só acerto de 1ª tentativa incrementa; bônus = 18 + 2×posicao
         zera ao errar, ao acertar só na 2ª, e a cada novo dia (combo_data)
xp_questao = xp_base + (combo>0 ? bônus : 0)
ao dominar palavra (passar N4): + 500 de bônus; palavras_dominadas += 1
```

`aluno_progresso.xp_total += xp_questao` → alimenta a barra do nó atual (`trilha_no.xp_limiar`).
Ao cruzar o limiar do nó: avança `no_atual_id` e dispara recompensa (confete / cartão-postal
ao fechar destino / carimbo ao fechar país — seção 3.10).

### Diagnóstico inicial — algoritmo proposto (preenche gap da seção 3.5)

> A seção 3.5 define "10–15 questões de níveis diferentes posicionam o aluno na escala
> 1–10", mas não dá o algoritmo. **Proposta** (a validar — ver questões em aberto):

Usa **questões de reconhecimento (tipo n1)** de palavras de `nivel_dificuldade`
variado — testa-se a dificuldade do **conteúdo**, não o tipo pedagógico. Escada
adaptativa, enquadrada como jogo (seção 3.5):

```
nivel ← default do ano escolar da turma (ex.: 7º ano → 3)
repetir 10–15 vezes (ou até estabilizar):
    apresentar questão de reconhecimento de palavra com nivel_dificuldade = nivel
    acertou → nivel += 1   |   errou → nivel -= 1   (limites 1..10)
posicao ← nivel onde a acurácia se estabiliza (~o ponto de virada acerto→erro)
aluno_progresso.nivel_dificuldade_atual ← posicao
```

Converge mais rápido que um espalhamento fixo e cai bem nas 10–15 questões. As **duas
demos roteirizadas** (acerto/erro) vêm **antes** do diagnóstico (seção 3.5).

### Adaptação contínua (seção 3.5)

Após cada sessão (ou janela de N respostas), ajusta `nivel_dificuldade_atual`:

```
acuracia_recente (1ª tentativa, janela móvel):
   ≥ 90% → nivel_dificuldade_atual += 1   (acelera, palavras mais difíceis)
   < 50% → não avança / consolida o nível atual (freia)
   entre → mantém
```

Lido de `aluno_questao` recentes (janela móvel); sem novo campo obrigatório (pode-se
materializar a acurácia se a query pesar).

### Ajustes ao modelo de dados (Bloco 1) que o 2a implica

| Tabela | Campo novo | Para quê |
|---|---|---|
| `aluno_progresso` | `nivel_dificuldade_atual` (1–10) | Saída do diagnóstico + adaptação contínua; guia a seleção de palavras novas. |
| `aluno_progresso` | `sessoes_total` (int) | Contador para o agendamento do N4 e janela de adaptação. |
| `aluno_palavra` | `nivel4_agendado_para` (int, nullable) | Sessão-alvo do N4 adiado. |

São 3 campos leves; nenhuma entidade nova. (Atualizar as tabelas do Bloco 1 quando
estes forem confirmados.)

### Questões em aberto (Bloco 2a)

1. **Diagnóstico — escada adaptativa vs. espalhamento fixo?** Proponho a escada
   (acima). Confirma?
2. **Janela da adaptação contínua** — por sessão ou por N respostas? Proponho avaliar
   ao fim de cada sessão sobre as últimas ~20 respostas de 1ª tentativa.
3. **"~2 sessões" do N4** — fixo em 2 ou configurável? Proponho fixo (2) no MVP,
   ajustável depois com telemetria.
4. **Tamanho exato da sessão** — ~12 com 4 de revisão (10 questões + 2 cards). Confirma
   esse alvo ou prefere fixar em 12 questões "duras"?
