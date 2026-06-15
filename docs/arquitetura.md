# Arquitetura Técnica — VocabBR Kids

> Design técnico do produto. Construído em **blocos** para revisão incremental:
>
> - **Bloco 1 — Modelo de dados** ✅
> - **Bloco 2a — Pipelines do apresentável** (sessão + diagnóstico) ✅
> - **Bloco 2b — Pipelines do completo** (redação→OCR→análise→geração→atribuição; QA; sinal de turma) ✅
> - **Bloco 3 — Estrutura do app e serviços** ✅
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
| `palavra` | `id`, `lema` (unique), `definicao`, `exemplo_uso`, `nivel_dificuldade` (1–10), `audio_url` (nullable), `origem` (`banco_base`\|`redacao`) | Chave de busca/dedup é o **lema** (spaCy normaliza antes de inserir — seção 3.3). `definicao` + `exemplo_uso` são o conteúdo do **card de descoberta** (seção 3.2); `audio_url` fica **reservado pós-MVP** (TTS fora do MVP — decisão 11/06). Global. | A |
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
| `aluno_palavra` | `id`, `usuario_id→usuario`, `palavra_id→palavra`, `estado` (`descoberta`\|`nivel_1..4`\|`dominada`), `origem` (`pessoal_redacao`\|`sinal_turma`\|`banco_base`), `palavra_gatilho` (nullable), `nivel4_agendado_para` (int, nullable), `atribuida_em`, `dominada_em` (nullable) | Estado de domínio por aluno (seção 3.4). `palavra_gatilho` só em origem pessoal (seção 3.2). `nivel4_agendado_para` = sessão-alvo do N4 adiado (Bloco 2a). | A |
| `aluno_questao` | `usuario_id→usuario`, `questao_id→questao`, `tentativas`, `acertou` (bool), `acertou_primeira` (bool), `respondida_em` | Garante "nunca repergunta variação já acertada" (seção 3.4) e alimenta XP/combo. | A |

A **composição da sessão** (12 questões, 2 palavras novas, intercalação de erros,
nível 4 adiado — seção 3.4) é **lógica de runtime** (Bloco 2), lida desses estados.
Não há tabela "sessão de questões fixa"; a sessão é montada na hora.

---

### 4. Progressão, XP e recompensas — **isolado por escola**

| Tabela | Campos-chave | Notas | Fase |
|---|---|---|---|
| `aluno_progresso` | `usuario_id→usuario` (PK), `xp_total`, `no_atual_id→trilha_no`, `palavras_dominadas` (contador), `combo_atual`, `nivel_dificuldade_atual` (1–10), `sessoes_total` (int), `nivel_mudou_em_sessao` (int, nullable) | 1:1 com aluno. `combo` é **por sessão** (decidido 10/06): zera ao **iniciar cada sessão** e ao errar/2ª tentativa (seção 3.7) — não carrega entre sessões (sem `combo_data`). `nivel_dificuldade_atual` = faixa do banco base para o aluno (diagnóstico + adaptação, Bloco 2a). `sessoes_total` = contador p/ timing do N4 e janela de adaptação. `nivel_mudou_em_sessao` = cooldown da histerese da adaptação. | A |
| `aluno_colecionavel` | `usuario_id→usuario`, `colecionavel_id→colecionavel`, `ganho_em` | Até 28 por aluno (passaporte: 20 cartões + 3 carimbos + 5 selos — seção 3.10 / `referencia_arte.md`). Booleano (ganhou/não). | A |

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
         zera ao errar, ao acertar só na 2ª, e ao INICIAR cada sessão
         (combo é por sessão — seção 3.7; não carrega entre sessões)
xp_questao = xp_base + (combo>0 ? bônus : 0)
ao dominar palavra (passar N4): + 500 de bônus; palavras_dominadas += 1
```

`aluno_progresso.xp_total += xp_questao` → alimenta a barra do nó atual (`trilha_no.xp_limiar`).
Ao cruzar o limiar do nó: avança `no_atual_id` e dispara recompensa (confete / cartão-postal
ao fechar destino / carimbo ao fechar país — seção 3.10).

### Filosofia: diagnóstico leve + adaptação forte (decidido 31/05)

Com múltipla escolha (**25% de chance de chute**) e ~15 questões, é **impossível cravar**
o nível no diagnóstico — o ruído domina. Então não tentamos: o **diagnóstico é um chute
rápido e levemente conservador**, e a **adaptação contínua (que sobe E desce) faz a
precisão real na 1ª semana**, onde há muito mais dados. Isso baixa a pressão sobre o
diagnóstico e move o peso para a adaptação.

### Diagnóstico inicial — escada grosso→fino com desconto de chute (preenche gap da 3.5)

Usa **questões de reconhecimento (tipo n1)** de palavras de `nivel_dificuldade` variado
(testa a dificuldade do **conteúdo**). Enquadrado como jogo (3.5):

```
nivel ← default do ano da turma (ex.: 7º → 3);  passo ← 2   # fase GROSSA
repetir (máx. 15 questões):
    acertou questão(nivel)?
        sim → nivel = min(10, nivel + passo)
        não → teto ← nivel;  passo ← 1;  nivel = max(1, nivel − 1)   # vira fase FINA
    parar quando "bracketado": passou consistente em L e falhou em L+1..L+2
confirmação anti-chute: 2 questões no nível-teto candidato
    passou nas 2 → ceiling = teto    |    senão → ceiling = teto − 1
nivel_dificuldade_atual ← max(1, ceiling − 1)        # posicionamento CONSERVADOR
```

- **Grosso→fino** (±2 depois ±1): acha a faixa rápido sem desperdiçar o orçamento de 15
  viajando; refina no fim.
- **Desconto de chute**: 2 questões no nível-teto (1 acerto sozinho não promove); reduz
  falso-positivo de ~25% → ~6%.
- **Conservador** (`ceiling − 1`): primeiras sessões são vitória (onboarding, 3.5).
- **Parada**: bracket estável ou 15 questões.
- As **2 demos** (acerto/erro) vêm **antes** do diagnóstico (3.5).

### Adaptação contínua — sobe E desce, sinal limpo, com histerese (3.5)

Roda ao fim de cada sessão. É aqui que mora a precisão do placement.

**Sinal limpo:** acurácia de **1ª tentativa só nas questões de palavras novas do nível
atual** — não a janela misturada com revisão (revisão tem acurácia alta e inflaria o
número, fazendo o aluno subir indevidamente). Janela móvel de ~10 questões de palavra
nova.

```
acuracia_novas (1ª tentativa, janela móvel, palavras NOVAS do nível atual):
   ≥ 90%  → nivel_dificuldade_atual += 1     (acelera)
   ≤ 50%  → nivel_dificuldade_atual − 1       (recua — recupera placement alto demais)
   entre  → mantém
histerese: só move se o sinal se sustenta pela janela cheia; um nível por vez;
           cooldown de 1 sessão após mover (nivel_mudou_em_sessao)
limites 1..10; limiares/janela/cooldown são constantes CONFIGURÁVEIS (telemetria calibra)
```

A mudança de faixa é **segura** porque é desacoplada da trilha/XP (3.7): muda só quais
palavras novas chegam, não o progresso visual. Lido de `aluno_questao` × `aluno_palavra`
recentes.

### Ajustes ao modelo de dados (Bloco 1) — já consolidados

Os 3 campos abaixo **já foram incorporados às tabelas do Bloco 1** (seções 3 e 4):

| Tabela | Campo | Para quê |
|---|---|---|
| `aluno_progresso` | `nivel_dificuldade_atual` (1–10) | Saída do diagnóstico + adaptação contínua; guia a seleção de palavras novas. Depende da rubrica de dificuldade da palavra (seção 3.5 do produto). |
| `aluno_progresso` | `sessoes_total` (int) | Contador para o agendamento do N4 e janela de adaptação. |
| `aluno_progresso` | `nivel_mudou_em_sessao` (int, nullable) | Sessão da última mudança de nível — para o cooldown da histerese da adaptação. |
| `aluno_palavra` | `nivel4_agendado_para` (int, nullable) | Sessão-alvo do N4 adiado. |

### Decisões do Bloco 2a (resolvidas 31/05)

**Filosofia:** diagnóstico leve + adaptação forte (acima).

1. **Diagnóstico:** escada **grosso→fino** (±2 depois ±1) + **desconto de chute** (2
   questões no nível-teto) + **placement conservador** (`ceiling − 1`) + parada por
   bracket ou 15 questões.
2. **Adaptação contínua:** sinal = acurácia de 1ª tentativa **só nas palavras novas do
   nível atual** (janela ~10); **sobe (≥90%) e desce (≤50%)**; **histerese** (sustentar
   o sinal) + **cooldown de 1 sessão**; um nível por vez; limiares/janela/cooldown
   configuráveis (telemetria calibra).
3. **Adiamento do N4:** fixo em **2 sessões** no MVP; ajustável depois com telemetria.
4. **Tamanho da sessão:** alvo **~12** (≈10 questões + 2 cards, com ~4 de revisão).

---

## Bloco 2b — Pipelines do completo (redação → trilha)

Os fluxos de runtime da fatia **C** (fase Out/26–Jan/27, ver cronograma na seção 08 do
produto). É aqui que entram as **fontes de palavra adiadas** no Bloco 2a: a **redação
pessoal** (1ª prioridade) e o **sinal de turma** (2ª) — seção 3.5. O banco base (3ª)
continua preenchendo os gaps exatamente como no Bloco 2a; este bloco só **alimenta** as
mesmas tabelas de estado (`aluno_palavra`, `aluno_questao`) que a sessão já consome.

Tudo aqui é **assíncrono e caro** (OCR, LLM): roda na fila `procrastinate` no Postgres
(stack, seção 12), não no caminho síncrono do app. Escreve em `redacao*`, `palavra`/
`questao` (banco global), `aluno_palavra`, `sinal_turma`, `report_questao`. Nenhuma
tabela nova é necessária — o Bloco 1 já previu todas (decisão "schema único", item 4).

### Visão geral

```
Professor ─→ redacao_atribuicao (tema, prazo, turma)
Aluno ─→ envia (foto|PDF) ─→ redacao(status=enviada)
                                    │
                  ┌─────────────────┴── pipeline assíncrono (fila) ──────────────────┐
                  ▼                                                                   │
   1. INGESTÃO    OCR (manuscrita) | extração de texto (PDF) → limpeza → texto_extraido
                  ▼
   2. ANÁLISE     LLM multidimensional (preset_rigor da turma) → redacao_analise (JSONB)
                  ▼
   3. EXTRAÇÃO    palavras fracas/superutilizadas → Hunspell (válida?) → spaCy (lema)
                  │                                          └─ inexistente → anotação ortográfica
                  ▼                                              (NÃO vira questão — 3.6)
   4. ATRIBUIÇÃO  para cada palavra fraca: LLM sugere alternativas → buscar_ou_gerar(lema)
                  ▼                                                    → aluno_palavra
   redacao(status=analisada)  +  redação anotada volta ao aluno (4.4)

   (em paralelo, periódico)  job de sinal de turma → sinal_turma → atribui aos alunos
```

### 1. Ingestão — `extrair_texto(redacao)`

Normaliza os dois formatos (4.6) num único `texto_extraido`:

- **Manuscrita** (`formato=manuscrita`): foto no R2 → **OCR Google Cloud Vision**
  (decidido, 4.7; preço/comparativo em `pesquisa_ferramentas.md`). Suporte PT-BR
  confirmado.
- **Digital** (`formato=digital`): PDF no R2 → extração de texto nativa; OCR de
  fallback só se o PDF for imagem escaneada.
- **Limpeza** (4.7): remove ruído de OCR (quebras espúrias, caracteres soltos) antes da
  análise. Pré-processamento leve; **não** é o NLP pesado que o produto descartou do MVP
  (seção 09).

Falha de OCR/extração → `redacao.status=erro_ingestao`, sem consumir as etapas caras
seguintes; reenfileirável.

### 2. Análise multidimensional — `analisar(redacao)`

Uma chamada de **LLM** (modelo **em aberto** — 4.8/seção 10, decidido com o 1º cliente)
produz as anotações por dimensão (4.2): vocabulário, acentuação, vírgula/pontuação, uso
adequado, coesão/estrutura. Resultado em `redacao_analise.anotacoes` (JSONB por dimensão
— trechos + marcação para a tela anotada da seção 4.4).

- **Rigor configurável** (4.3): lê `turma_config.preset_rigor` (default por ano se
  null). Dimensões desativadas pelo professor **não** são analisadas/anotadas.
- **Só vocabulário gera questão** no MVP (4.2/4.5); as demais dimensões são **feedback
  informativo**. A arquitetura é extensível: sintaxe poderia gerar questão no futuro sem
  reconstrução (3.8) — mas fora de escopo agora (seção 09).
- O **piso é o preset da turma; o teto pode subir** para o nível individual do aluno
  como bônus, nunca cobra além do preset (4.3) — alinha com `nivel_dificuldade_atual`.

### 3. Extração e validação de palavras — `extrair_palavras(redacao_analise)`

Da dimensão de vocabulário saem candidatas `fraca`|`superutilizada` (3.6/4.5):

1. **Validação Hunspell** (3.6/4.7, decidido): palavra **inexistente no dicionário PT-BR**
   é erro ortográfico → vira anotação na redação, **não** vocabulário fraco (não gera
   questão). Evita gerar questão sobre lixo de OCR ou typo.
2. **Lematização spaCy** (seção 3.3; lema como chave de indexação, decidido): grava
   `redacao_palavra(texto, lema, tipo)`.

A palavra extraída é a **palavra-problema** do aluno (ex.: "importante" superutilizada);
ela não vira card. O que vira card/questão são as **alternativas** dela (passo 4).

### 4. Atribuição à trilha — `buscar_ou_gerar_e_atribuir(palavra_problema, aluno)`

Fecha o ciclo do produto (4.5). Para cada palavra-problema:

```
alternativas ← LLM sugere 2–4 sinônimos mais ricos (ex.: importante → relevante,
               essencial, significativo)                               # seção 3.6
para cada alternativa alt:
    lema_alt ← spaCy(alt)
    p ← palavra WHERE lema = lema_alt                                   # banco GLOBAL
    se p existe e tem questões ativas:  reusar
    senão:                              gerar_questoes(p)  # 4 níveis, ≥2 variações (3.3)
                                        → QA preventiva (abaixo) → salvar no banco
    atribuir: aluno_palavra(usuario, p, estado=descoberta,
                            origem='pessoal_redacao',
                            palavra_gatilho = palavra_problema.texto)    # gancho do card (3.2)
```

- **Banco compartilhado** (3.6/Bloco 1 §2): questões são recurso da palavra (global),
  não do aluno. Dois alunos que erram a mesma palavra no mesmo dia reusam as mesmas
  questões — sem duplicação.
- **Geração lazy + permanente**: gera só quando falta; salva no banco para sempre.
  `palavra.origem='redacao'` distingue do `banco_base`.
- **`palavra_gatilho`** preenchido só aqui (origem pessoal) — habilita o card pessoal
  "Você usou 'importante' várias vezes. Conheça uma alternativa:" (3.2).
- **`redacao_palavra.virou_atribuicao=true`** ao concluir, para telemetria/idempotência.

### Sinal de turma — `computar_sinal_turma(turma, periodo)` (fonte 2ª)

Job **periódico** (não por envio individual), agrega o `redacao_palavra` da turma no
período letivo (3.5):

```
para cada lema marcado fraca|superutilizada nas redações da turma:
    pct ← alunos_distintos_com_o_lema / alunos_da_turma
    se pct ≥ 30% (limiar inicial, configurável):           # 3.5
        upsert sinal_turma(turma, palavra, periodo, pct)
        para cada aluno da turma que NÃO dominou a palavra:
            se já está na fila por redação pessoal: pular   # dedup, pessoal vence (3.5)
            senão: aluno_palavra(..., origem='sinal_turma')  # peso/prioridade menor
```

- **Dedup** com a fonte pessoal: a palavra aparece uma vez só, com o gancho pessoal
  quando houver (3.5).
- O 30% é **inicial e ajustável** com telemetria; mesma natureza dos outros limiares
  "ajustáveis com dados reais".

### Precedência de fontes na sessão (muda o Bloco 2a?)

Não muda a mecânica da sessão; muda **de onde vêm as "palavras novas"**. `montar_sessao`
(Bloco 2a, passo 1) passa a puxar palavras novas por prioridade (3.5):

```
1ª  aluno_palavra origem='pessoal_redacao'   (mais recentes primeiro)
2ª  aluno_palavra origem='sinal_turma'
3ª  banco base no nivel_dificuldade_atual    (preenche o resto — exatamente o Bloco 2a)
```

A adaptação contínua (Bloco 2a) segue lendo **só palavras novas do nível atual** como
sinal; palavras de redação/turma fora do nível entram como conteúdo, mas o ajuste de
faixa continua governado pelo banco base no nível — evita que uma redação difícil
empurre o placement.

### QA da IA em 3 camadas (seção 3.6)

A geração e a análise são automáticas e **publicadas direto** (sem revisão prévia do
professor). Qualidade controlada por:

| Camada | Quando | Mecanismo | Tabela |
|---|---|---|---|
| **Preventiva** | na geração (passo 4) | 2º passo barato da LLM ("algum distrator também é válido nesta frase?") barra distrator ambíguo antes de publicar | — (descarta/regenera) |
| **Corretiva 1 — report** | em uso | aluno reporta com motivo predefinido → admin (não professor); agrega entre escolas | `report_questao` |
| **Corretiva 2 — taxa de erro** | em uso | questão com erro anômalo (1ª tentativa) ou discrepante das outras variações → revisão automática | depende de `evento` |

- **Auto-ocultar** (regra do Bloco 1 §2, decidida): `questao.status→oculta_report` aos
  **2 reports que contam**; reversível pelo admin (corrigir/republicar/remover).
- **Anti-abuso**: report não dá XP nem isenta a questão (incentivo a abusar é baixo);
  autor com vereditos `invalido` tem reports **descontados** — penalização **computada**
  da taxa, não flag fixa (Bloco 1, decisão 3).
- **Camada 2 depende da telemetria** (`evento`, seção 07): por isso entra na **mesma
  janela** Out–Jan, não antes.

### Idempotência, custo e falhas

- Cada etapa é uma **task da fila** com retry/backoff; `redacao.status` é a máquina de
  estados (`enviada→…→analisada`|`erro_*`). Reprocessar é seguro: extração checa
  `virou_atribuicao`; sinal de turma é `upsert` por `(turma, palavra, periodo)`.
- **Custo** (seção 08): OCR ~$1,50/1.000 págs (1.000/mês grátis); a verificação
  preventiva é "centavos" e vale num produto infantil (3.6). Geração de questões é
  **lazy** e **amortizada** pelo banco compartilhado — cai conforme o banco enche.
- **Modelo de LLM** (OCR já decidido; LLM de análise/geração **não**) fica para a janela
  do 1º cliente (4.8/seção 10) — escolha de provedor atrás de uma interface estável
  (princípio "interface-estável/provider-variável", seção 12), sem impacto no esquema.

### Decisões do Bloco 2b

1. **Ingestão única:** OCR (Vision) e extração de PDF convergem para `texto_extraido`;
   limpeza leve, sem NLP pesado (descartado, seção 09).
2. **Análise:** uma chamada de LLM por redação respeitando `preset_rigor`; só
   vocabulário gera questão no MVP (demais dimensões = feedback).
3. **Extração:** Hunspell barra inexistentes (vira ortografia); spaCy lematiza; lema é a
   chave de busca/dedup no banco global.
4. **Atribuição:** `buscar_ou_gerar` reusa o banco compartilhado; gera lazy + permanente;
   `palavra_gatilho` e `origem='pessoal_redacao'` habilitam o card pessoal.
5. **Sinal de turma:** job periódico, limiar 30% configurável; dedup com a fonte pessoal
   (pessoal vence); origem/prioridade menor.
6. **QA:** 3 camadas (preventiva na geração + report + taxa de erro); auto-ocultar em 2;
   anti-abuso computado. Camada de taxa de erro depende da telemetria (mesma janela).
7. **Assíncrono:** tudo na fila `procrastinate`, idempotente, dirigido por
   `redacao.status`.

### Questões em aberto do Bloco 2b

- **Pré-processamento antes da LLM** (LanguageTool): avaliar se vale, com redações reais
  (4.8). Decisão por qualidade/custo, não por prazo.
- **Modelo de LLM** de análise/geração: adiado para o 1º cliente (seção 10) — não
  bloqueia o design.
- **Período do sinal de turma**: "período letivo atual" precisa de uma definição
  operacional (bimestre? ano? janela móvel?) ao implementar `turma_config`.
- **Granularidade do reprocesso** quando o professor muda `preset_rigor` depois de
  redações já analisadas (reanalisar o histórico ou só dali pra frente?).

---

## Bloco 3 — Estrutura do app e serviços

Onde os Blocos 1 (dados), 2a e 2b (runtime) viram **componentes, serviços, API e app**.
Este bloco é a ponte para o código: descreve a topologia, como o backend FastAPI se
organiza, a superfície de API do apresentável e a estrutura do app Flutter. Continua
**marcado por fase** (**A** = apresentável, Jun–Set; **C** = completo, Out–Jan) e fiel à
stack já decidida (seção 12 do produto): Flutter, FastAPI, PostgreSQL/Neon, fila
`procrastinate`, R2, Cloud Run, região São Paulo.

### Topologia de componentes

```
┌──────────────┐        HTTPS / REST+JSON        ┌───────────────────────────┐
│  App Flutter │ ───────────────────────────────▶│  API FastAPI (Cloud Run)  │
│  (iOS/Android│◀─────────────────────────────── │  rotas → serviços → repo  │
│   mobile, A) │   estado autoritativo do server │                           │
└──────────────┘                                 └─────────┬─────────────────┘
                                                           │ SQL (asyncpg)
   ┌────────────── fatia C (completo) ───────────┐         ▼
   │  Worker procrastinate (Cloud Run, C)        │   ┌───────────────┐
   │  OCR · análise LLM · geração · sinal turma  │──▶│ PostgreSQL    │
   │  enfileira/consome a mesma fila no Postgres │◀──│ (Neon)        │
   └───────────────┬─────────────────────────────┘   │ + fila jobs   │
                   │ OCR/LLM (provedores externos, C) └──────┬────────┘
                   ▼                                         │ arquivos
        Google Vision · LLM (em aberto)                      ▼
                                                      Cloudflare R2 (redações, C)

   App do professor (dashboards): Flutter web, MESMO codebase, entrypoint
   separado (main_professor.dart), apresentável. Fala a MESMA API. (Plano antigo
   previa React/Next em C — revisado 15/06; ver telas §8.2 e notas.)
```

Um único codebase de backend serve as duas fatias; a fila/worker e o R2 só entram em
**C**. No **apresentável** o backend é essencialmente **síncrono** (não chama OCR/LLM em
runtime — o banco base é pré-gerado e revisado, seção 3.5).

### Princípio: cliente fino, servidor autoritativo

O app **renderiza e captura**; toda a regra mora no servidor. Motivos:

- **Anti-trapaça / integridade do XP e combo** (seção 3.7): o XP é calculado e persistido
  no backend a cada resposta — o cliente nunca informa pontuação.
- **Lógica adaptativa e de sessão** (Bloco 2a) lê estado cruzado (`aluno_questao` ×
  `aluno_palavra` × `aluno_progresso`) que vive no banco; manter no servidor evita
  divergência e duplicação da regra no Dart.
- **Sem offline forte** (decisão de PK `BIGINT`, Bloco 1): não há sincronização offline
  prevista; o app assume conectividade. Latência é mascarada com animações
  não-bloqueantes (seção 3.7), não com autoridade no cliente.

### Backend FastAPI — camadas e módulos

Três camadas, dependência só para baixo:

```
rotas (API)      validação de entrada (Pydantic), auth/escopo, serialização
   ▼
serviços (domínio)  a lógica dos Blocos 2a/2b; sem SQL cru nem detalhe de HTTP
   ▼
repositórios (dados) acesso ao Postgres (asyncpg/SQLAlchemy core); 1 lugar por agregado
```

Organização **por domínio** (não por camada técnica), espelhando o Bloco 1:

| Módulo | Cobre | Fase |
|---|---|---|
| `identidade` | `usuario`, `associacao`, `escola`, `turma`; entrada por `codigo_turma`; resolução papel/escopo | A |
| `vocabulario` | `palavra`, `palavra_sinonimo`, `questao` (banco global, leitura no apresentável) | A |
| `aprendizado` | `aluno_palavra`, `aluno_questao` — máquina de estados da palavra (Bloco 2a) | A |
| `sessao` | `montar_sessao`, fila/intercalação, `responder`, resumo (Bloco 2a) | A |
| `diagnostico` | escada grosso→fino + desconto de chute (Bloco 2a) | A |
| `adaptacao` | sinal limpo + histerese; roda no fim da sessão (Bloco 2a) | A |
| `progressao` | XP/combo, `aluno_progresso`, avanço de `trilha_no`, recompensas | A |
| `trilha` | catálogo `pais/destino/trilha_no/colecionavel`; passaporte (`aluno_colecionavel`) | A |
| `redacao` | atribuição/envio + orquestração do pipeline (Bloco 2b) | C (mock em A) |
| `report` | `report_questao`, auto-ocultar, anti-abuso (Bloco 2b/QA) | C (mock em A) |
| `professor` | painel de turma/aluno, meta semanal, atribuição de redação (telas §8.2, §3.11) | C (mock em A) |
| `telemetria` | `sessao`/`evento` (analytics agregada, seção 07) | C |

> No apresentável, `redacao`/`report`/`professor` existem como **rotas mockadas** (devolvem dados
> fixos) — a tela é real, o backend não grava (decisão "schema único", Bloco 1).

### Fronteira síncrono × assíncrono

- **Síncrono (request/response):** tudo do apresentável — montar sessão, responder,
  progresso, trilha, passaporte, diagnóstico. Operações curtas sobre o estado
  operacional. É o caminho que existe em **A**.
- **Assíncrono (`procrastinate` no Postgres):** o pipeline de redação do Bloco 2b
  (OCR→análise→extração→atribuição) e o job periódico de **sinal de turma**. Roda num
  **worker separado** (processo Cloud Run distinto da API, mesma imagem/codebase),
  dirigido por `redacao.status`, com retry/backoff e idempotência. Entra em **C**.
- Sem Redis: a fila é o próprio Postgres (seção 12). Cache adiado.

### Superfície de API (apresentável)

REST/JSON, **auth-agnóstica** (seção 3.11): no apresentável a sessão de acesso nasce do
`codigo_turma`; o flow de auth real é plugado depois sem mexer nas rotas. Esboço dos
recursos de **A** (não exaustivo; versão sob `/v1`):

| Método | Rota | Faz | Serviço |
|---|---|---|---|
| `POST` | `/v1/acesso/turma` | entra por `codigo_turma` → sessão do aluno | identidade |
| `GET` | `/v1/me` | perfil + `aluno_progresso` (XP, nó, palavras dominadas) | progressao |
| `POST` | `/v1/onboarding/diagnostico` | roda/avança o diagnóstico → `nivel_dificuldade_atual` | diagnostico |
| `POST` | `/v1/sessoes` | monta e abre uma sessão (fila de slots) | sessao |
| `GET` | `/v1/sessoes/{id}/proximo` | próximo slot pendente (card ou questão) | sessao |
| `POST` | `/v1/sessoes/{id}/respostas` | registra resposta → XP/combo, avanço de estado, intercalação | sessao+progressao |
| `POST` | `/v1/sessoes/{id}/fim` | fecha sessão → resumo + roda adaptação | sessao+adaptacao |
| `GET` | `/v1/trilha` | mapa: nó atual, destinos, "você está aqui" | trilha |
| `GET` | `/v1/passaporte` | coleção (até 28), modos Conquista/Exploração | trilha |
| `POST` | `/v1/questoes/{id}/report` | report do aluno (mock em A) | report |
| `GET` | `/v1/redacoes` | tela mockada/estática (A) | redacao |
| `GET` | `/v1/professor/turmas` · `/v1/professor/turmas/{id}/painel` · `/v1/professor/escola` | painel do professor/coordenador (mock A) | professor |

A montagem da sessão é **server-side** e a entrega é **híbrida** (decisão #3 ao fim do
bloco, **revisada em 10/06**): o cliente recebe a **fila planejada em lote** (renderiza +
*prefetch*), mas **nunca** a resposta correta antecipada; cada resposta é corrigida no
servidor, que **também reordena a fila persistida** (`sessao.fila`) e a devolve na
resposta (`fila`/`proximo`) — a intercalação de erro (Bloco 2a) vive **só no servidor**,
o app renderiza a ordem recebida.

### App Flutter — organização e telas

Organização **feature-first** (uma pasta por feature, espelhando os módulos), com camadas
`ui / state / data(api client)`. Gerência de estado a definir (ver questões) — o app é
fino, então o peso é baixo. Telas mapeadas ao produto (seção 3.7/3.10):

| Tela | Papel | Fonte |
|---|---|---|
| **Home-hub** | hub ao abrir: status, "Continuar", atalhos | 3.7 |
| **Sessão** | card de descoberta + questões; barra de progresso fina | 3.2/3.4 |
| **Resumo de sessão** | XP ganho + progressão das palavras (sem % nem tempo) | 3.7 |
| **Trilha (mapa)** | aterrissagem pós-sessão; "você está aqui" | 3.7 |
| **Passaporte** | perfil + coleção; Conquista (animado) / Exploração (estático) | 3.10 / `referencia_arte.md` |
| **Onboarding** | código de turma → boas-vindas → 2 demos → diagnóstico → 1ª palavra | 3.5 |
| **Redação / Report** | **mockadas/estáticas** no apresentável | seção 08 |
| **Professor (web)** | app web separado (`main_professor.dart`): painel turma/aluno, meta, atribuir redação | §8.2 / 3.11 |

A animação (passaporte, confete de nó) segue `referencia_arte.md`; ferramenta em aberto
(teste da peça-âncora) **não bloqueia** a estrutura — é camada de movimento sobre telas
que já existem.

### Identidade, escopo e isolamento na prática

- **Resolução de permissão** (seção 3.11) é uma **dependency** da rota: a partir de
  `usuario → associacao → (escola, papel)` resolve `(papel, escopo, capacidade)`. Não é
  tabela (Bloco 1).
- **Isolamento por escola** é imposto no **repositório**: toda query de dado de aluno
  recebe o escopo de escola e filtra por ele (`usuario→associacao→escola`). Opcionalmente
  reforçado por **RLS** do Postgres (Bloco 1). O banco global (`palavra/questao/...`) não
  é escopado.
- **Leaderboards** são agregações dentro do escopo permitido (Bloco 1) — endpoints de
  leitura, sem entidade nova; pós-MVP para o XP de evento.

### Configuração por fase e ambientes

- **Fatia A vs C** por configuração, não por fork: `redacao`/`report` mockados e worker
  desligado em A; em C ligam-se o worker, o R2 e os provedores externos. Mesmo schema
  (decisão "schema único", Bloco 1).
- **Deploy:** dois serviços Cloud Run da **mesma imagem** — `api` (web server) e `worker`
  (procrastinate, só C). Banco no Neon; arquivos no R2; tudo em São Paulo.
- **Config por ambiente** (interface-estável/provider-variável, seção 12): connection
  string, buckets e chaves de provedor vêm de env; demo→produção é troca de plano, não
  reescrita. `min-instances=1` para matar cold start ao apresentar.
- **Conteúdo/seed (A):** trilha (`pais/destino/trilha_no`), 28 colecionáveis e o **banco
  base** (500–800 palavras + questões pré-geradas e revisadas — seção 3.5/3.10) entram por
  **migrations/seed**, não por runtime. A geração+revisão do banco base é um processo
  **offline de conteúdo** (admin), distinto do pipeline lazy do Bloco 2b.

### Decisões do Bloco 3

1. **Cliente fino, servidor autoritativo:** XP/combo, regra de sessão e adaptação no
   backend; o app renderiza e captura. Sem offline forte.
2. **Backend em camadas (rotas→serviços→repositórios), modularizado por domínio** espelhando
   o Bloco 1; um codebase para as duas fatias.
3. **Síncrono no apresentável; assíncrono (worker `procrastinate`) só no completo** para o
   pipeline de redação e o sinal de turma.
4. **API REST/JSON sob `/v1`, auth-agnóstica** (entrada por `codigo_turma`); sessão
   montada no servidor, sem vazar resposta correta.
5. **App Flutter feature-first**; aluno em mobile, **professor em Flutter web** (entrypoint
   separado `main_professor.dart`, mesmo codebase/design system, sem pesar o app do aluno);
   telas mockadas para redação/report/professor; animação como camada sobre telas prontas.
6. **Isolamento por escola no repositório** (escopo em toda query de aluno), RLS opcional;
   permissão resolvida como dependency, não tabela.
7. **Fase por configuração** (worker/R2/provedores ligam em C), mesmo schema; banco
   base/trilha/colecionáveis via seed.

### Decisões de implementação (resolvidas 03/06)

Eram as "questões em aberto" do Bloco 3 — fechadas. Todas **locais e reversíveis**: cada
uma destrava a fatia de código a que pertence (ver tabela ao fim), nenhuma trava o
scaffold nem as migrations do Bloco 1.

1. **Estado no Flutter: Riverpod.** Padrão atual da comunidade, pouco boilerplate;
   suficiente porque o app é cliente fino (quase todo estado vem do servidor). Estado
   gerencia o *dado e seu fluxo*, não o layout das telas.
2. **Acesso a dados: SQLAlchemy Core + Alembic**, com queries explícitas (sem ORM
   pesado). Migrations versionadas; controle do SQL para as seleções não-triviais do
   Bloco 2a (intercalação, janela de adaptação). O schema do Bloco 1 é a verdade.
3. **Entrega da sessão: híbrida** (não slot-a-slot puro nem lote ingênuo). O servidor
   manda a **fila planejada em lote** no início (app renderiza tudo + *prefetch* de
   cards/imagens → snappy, no espírito do Duolingo); a **correção continua no servidor**
   a cada resposta (integridade do XP, não vaza a resposta certa). **Revisado em
   10/06:** a **intercalação de erro também é server-side** — a fila é persistida
   (`sessao.fila` JSONB), reordenada pelo servidor a cada resposta e devolvida em
   `POST /respostas` (`fila`/`proximo`) e `GET /proximo`. Racional: a versão
   anterior ("reordenada no cliente e reconciliada no servidor") duplicava a regra
   no Dart — exatamente o que o princípio do cliente fino quer evitar — e a chamada
   por resposta já existe, então devolver a ordem não custa round-trip extra.
4. **Isolamento: escopo em código agora, RLS adiado** para a janela de LGPD (Out–Jan).
   O escopo por escola no repositório já isola; RLS é reforço defensivo, melhor decidido
   com dados reais de criança.
5. **Convenção de API/erro.** Corpo de erro padronizado
   `{ "error": { "code": <snake_case>, "message": <legível>, "details": {} } }` — o app
   ramifica pelo `code`. Status HTTP com semântica padrão (`400/401/403/404/409/422/429/500`;
   `422` é o default do FastAPI, embrulhado no formato). **Paginação por cursor**
   (`?cursor=&limit=` → `{items, next_cursor}`). **`/v1`** no path; sobe de versão só em
   breaking change (adicionar campo é compatível).

**Ordem em que cada decisão é exercida no código:**

| Etapa | Decisão que precisa estar fechada |
|---|---|
| Setup + scaffold + **migrations do Bloco 1** | nenhuma |
| Primeiro repositório / data layer | #2 |
| Primeira rota | #5 |
| Endpoint de sessão | #3 |
| Primeira tela Flutter | #1 |
| Endurecer isolamento | #4 (adiável p/ Out–Jan) |
