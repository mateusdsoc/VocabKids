# VocabBR Kids — Documento de Produto

> Documento de trabalho. Substitui o `vocabbr-kids-documento (1).docx` original como fonte da verdade. O docx fica no repo apenas como referência histórica.

---

## 01 — Visão do produto

VocabBR Kids é um app mobile (iOS e Android) de expansão de vocabulário em português nativo, voltado para crianças e pré-adolescentes em escolas brasileiras.

**Modelo de negócio: B2B.** A escola contrata por assinatura mensal; alunos baixam o app gratuitamente. Nenhuma transação passa por App Store / Google Play, eliminando taxas de plataforma.

**Proposta de valor central:** ser o único app brasileiro que fecha o ciclo completo do vocabulário — diagnostica o que o aluno não sabe, ensina de forma adaptativa e gamificada, e comprova o aprendizado quando ele usa as palavras na escrita real.

**Diferencial competitivo:** nenhum concorrente brasileiro fecha o ciclo completo (diagnóstico → ensino adaptativo → validação por redação real) em um produto especializado em vocabulário, com gamificação séria e identidade brasileira.

---

## 02 — Público e contexto

### Faixa etária

- **Público primário:** Fundamental II — 6º ao 9º ano (10 a 13 anos).
- **Público secundário (avaliar):** anos finais do Fundamental I — 4º e 5º ano (9 a 11 anos), faixa em que a maioria dos alunos de escolas particulares já tem smartphone próprio.

A inclusão do Fundamental I depende de validação pedagógica — vocabulário, dificuldade dos exercícios e tom da gamificação precisam ser calibrados para essa faixa antes de virar oferta comercial.

### Stakeholders

| Perfil | Dor principal | Papel no processo |
|---|---|---|
| Professor de português | Alunos com vocabulário pobre, redações repetitivas, sem repertório | Usuário e defensor interno |
| Coordenador pedagógico | Falta de ferramenta que complemente o professor de forma mensurável | Decisor de compra |
| Diretor / mantenedor | ROI do investimento em tecnologia educacional | Aprovador do orçamento |
| Aluno (9–13 anos) | Aprender sem perceber que está estudando | Usuário final do app |

---

## 03 — Funcionalidades principais

Três pilares formam o produto. Flashcards de Repertório foram removidos do escopo (não fazem parte do plano atual).

### 🎯 Killer Feature 1 — Diagnóstico de Vocabulário

No primeiro acesso, cada aluno realiza um teste de ~10 minutos. O app gera um mapa visual da turma:

- Quais palavras a turma domina coletivamente.
- Quais alunos estão acima e abaixo da média.
- Quais palavras específicas cada aluno precisa trabalhar.
- Qual o percentual do vocabulário esperado para a série que a turma domina.

> Para o diretor: *"sua turma do 8º ano domina 58% do vocabulário esperado para o ano — estas são as 40 palavras que mais precisam de atenção."* Essa tela vende sozinha em qualquer reunião.

### 📝 Killer Feature 2 — Radar de Redação (missão especial)

O aluno fotografa a redação física com a câmera do celular. O app usa OCR para extrair o texto e:

- Identifica palavras repetidas em excesso.
- Detecta palavras aprendidas no app que o aluno **não usou** na redação.
- Monta um quiz personalizado com sinônimos das palavras fracas identificadas.
- Ensina vocabulário a partir da escrita real do aluno — não de uma lista genérica.

**Decisão de produto:** Radar de Redação é apresentado como **missão especial** dentro da trilha (selo próprio, ícone distinto), separado das sessões regulares. Motivos:

1. É o killer feature de venda — precisa ser visível e nomeável para a escola.
2. O ciclo OCR → quiz é caro; melhor disparar sob demanda do aluno/professor.
3. Integrar ao fluxo de revisão regular só faz sentido depois de validar a precisão do OCR em produção.

> Exemplo prático: o aluno usou *"bonito"* seis vezes na redação. O app detecta, oferece um quiz com *"belo, formoso, esplêndido, magnífico"* — e o aluno aprende essas palavras no contexto da própria escrita.

### 🎮 Killer Feature 3 — Gamificação séria

Sistema de progressão e recompensas inspirado em Duolingo / Candy Crush, mas alinhado ao contexto escolar. Detalhes na seção 05.

---

## 04 — Mecânica de aprendizado

### Algoritmo: a definir

A versão adulta do VocabBR usa SRS (Spaced Repetition System) clássico. **A versão Kids não está comprometida com SRS.** Razões:

- Crianças respondem melhor a progressão visível (níveis, trilha) do que a revisão "invisível".
- Engajamento de 10–13 anos depende mais de ritmo de descoberta do que de eficiência de memorização.
- A gamificação por trilha já provê estrutura de retomada natural (níveis anteriores podem ser revisitados).

O que sabemos:

- **Haverá progressão por níveis.** Não é opcional.
- **Haverá revisão de palavras já vistas** dentro das sessões — em que cadência e com qual lógica de seleção é decisão em aberto.
- **A composição das sessões** (quantas palavras novas, quantas em revisão) precisa ser definida com base em testes com a faixa etária.

Decidir o algoritmo é trabalho que vem **depois** de definir a estrutura de níveis e a curva de dificuldade do conteúdo.

### Composição de cada sessão (atual hipótese)

Sessão curta de 5–10 exercícios. Mix de:

- **Reconhecimento (fácil):** ver a palavra e escolher o significado entre 4 opções.
- **Produção (médio):** completar lacuna em frase com a palavra correta.
- **Contextualização (difícil):** avaliar se o uso da palavra em uma frase está correto.

A proporção exata e a inclusão de revisões dentro da sessão dependem da decisão de algoritmo.

---

## 05 — Gamificação e identidade visual

### Mascote: lobo-guará

Identidade brasileira, distinta do mascote de qualquer concorrente (sem mais uma coruja). O lobo-guará aparece como guia, narrador de feedbacks e personagem das telas de progresso e recompensa.

### Sistema de progressão

- **XP** ganho por exercício acertado, por sessão completada e por missões (incluindo Radar de Redação).
- **Níveis** que evoluem por XP acumulado.
- **Trilha visual estilo Candy Crush** (preferida sobre o estilo Duolingo): caminho com nós distintos por capítulo / tema, ícones diferenciados para níveis especiais (boss de capítulo, missão de redação, evento ativo).

### Eventos e recompensas

- Eventos por tempo limitado com metas para ganhar recompensas.
- Recompensas cosméticas — não afetam aprendizado:
  - Skins/cores alternativas para a tela do app.
  - Acessórios visuais para o lobo-guará.
  - Selos e troféus exibíveis no perfil.

> **Princípio:** XP recompensa esforço; o conteúdo de aprendizado decide o que aparece. Recompensa não é dinheiro de verdade nem desbloqueia conteúdo pedagógico.

### Tensão a resolver: gamificação intensa × venda B2B

Coordenador pedagógico que assina o produto pode rejeitar mecânicas de "vício Duolingo" (streak agressivo, push de FOMO, ranking público). Direção atual:

- **Modo escola** com métricas para o professor por baixo da gamificação.
- **Streak e push notification opcionais**, configuráveis pela escola.
- **Ranking interno por turma** em vez de ranking público / global.

Decisão final depende de feedback do piloto.

---

## 06 — Escopo por versão

| Funcionalidade | Descrição | Versão |
|---|---|---|
| Diagnóstico de Vocabulário | Teste inicial que mapeia o nível de cada aluno e gera relatório da turma. | MVP |
| Sessão de prática adaptativa | Mix de reconhecimento, produção e contextualização. Algoritmo a definir. | MVP |
| Trilha visual + XP + Níveis | Progressão em trilha estilo Candy Crush, mascote lobo-guará. | MVP |
| Painel do professor | Relatório semanal: palavras mais erradas da turma, alunos com menos prática, palavras dominadas. | MVP |
| Eventos com recompensas cosméticas | Metas temporárias que desbloqueiam skins, cores, acessórios do mascote. | MVP / V2 |
| Radar de Redação (OCR) | Aluno fotografa redação. Quiz com sinônimos das palavras fracas. Missão especial na trilha. | V2 |
| Lista personalizada pelo professor | Professor cria lista com vocabulário do livro ou tema da aula. | V2 |
| Mini-escrita semanal | Aluno escreve uma frase com cada palavra nova da semana. | V2 |
| Trilha de Inglês | Vocabulário alinhado ao currículo. Oxford 3000 como base. Áudio de pronúncia. | Futuro |

> **Removido do escopo:** Flashcards de Repertório (cards tema + dado + autor + frase de efeito). Não faz parte do plano atual.

---

## 07 — Modelo de negócio

### Precificação

| Porte da escola | Preço / mês | Por aluno / ano |
|---|---|---|
| Até 100 alunos no fund. II | R$ 100 (entrada) | ~R$ 12/aluno |
| 101 a 250 alunos | R$ 150 – 200 | ~R$ 10/aluno |
| 250+ alunos | R$ 250 – 300 | ~R$ 8/aluno |

Referência: Vocabulary.com cobra o equivalente a ~R$ 40/aluno/ano nos EUA. VocabBR Kids entra abaixo dessa referência.

### Potencial de mercado

| Escolas | Receita mensal | Receita anual | % do mercado BR |
|---|---|---|---|
| 20 | R$ 2.000 | R$ 24.000 | < 0,1% |
| 100 | R$ 10.000 | R$ 120.000 | 0,3% |
| 500 | R$ 50.000 | R$ 600.000 | 1,6% |
| 1.000 | R$ 100.000 | R$ 1.200.000 | 3,3% |

Brasil tem mais de 30.000 escolas privadas com Fundamental II. Atingir 1.000 é 3,3% do mercado.

---

## 08 — Estratégia de entrada

### Ordem de abordagem

- **Tier 1** (médias, decisão rápida): Colégio Franciscano Coração de Maria (BH), SESI Escola (BH), escolas dos bairros Buritis, Pampulha, Venda Nova e Contagem.
- **Tier 2** (após caso de sucesso): Pitágoras, Anglo, COC.
- **Tier 3** (apenas com produto consolidado): Marista, Champagnat, Bernoulli — burocracia alta, processo longo.

### Processo de venda

| Etapa | O que fazer |
|---|---|
| 1 | Apresentar VocabBR adulto como protótipo. Mostrar para professores de português — não diretores. Coletar feedback real. |
| 2 | Piloto gratuito de 3 meses. Uma turma, um professor. Coletar dados e depoimento. |
| 3 | Converter para pago. Coordenador leva para o diretor com dados e depoimento em mãos. |
| 4 | Expansão por indicação. Coordenadores se conhecem. BH → MG → Sul/Sudeste → Brasil. |

---

## 09 — Objeções esperadas

**"Por que pagar se o professor já ensina vocabulário?"**
Professor tem 35 alunos com níveis diferentes. É humanamente impossível praticar vocabulário individualizado com todos ao mesmo tempo. O app faz isso e devolve relatório para o professor usar em aula. Ele fica mais eficiente, não substituído.

**"R$ 100 vale mais numa plataforma que faz mais coisas."**
Plataformas que fazem tudo fazem tudo pela metade. Vocabulário é dor específica — produto especializado resolve melhor. Diagnóstico de Vocabulário e Radar de Redação não existem em plataforma genérica.

**"Como sabemos que funciona?"**
Resposta construída pelo piloto gratuito. Após 3 meses: X% de melhora no vocabulário diagnosticado, Y palavras novas aprendidas por aluno, Z% dos alunos usando palavras novas nas redações.

---

## 10 — Panorama competitivo

| Produto | País | Foco | Gap que o Kids preenche |
|---|---|---|---|
| Vocabulary.com | EUA | Vocabulário em inglês para nativos | Não existe versão em português com contexto brasileiro |
| Aprimora | Brasil | Português e Matemática (amplo) | Não tem Diagnóstico, OCR de redação ou algoritmo adaptativo |
| FazGame | Brasil | Gamificação educacional geral | Não tem foco em vocabulário nem ciclo com redação |
| VocabBR Kids | Brasil | Vocabulário PT-BR + ciclo completo + identidade brasileira | — |

Diferencial real: único produto que fecha o ciclo completo — diagnostica, ensina de forma adaptativa e gamificada, e comprova o aprendizado pelo uso na escrita real.

---

## 11 — Próximos passos

| Fase | Quando | O que fazer |
|---|---|---|
| 1 | Agora | Concluir MVP do VocabBR adulto — protótipo para mostrar a professores. |
| 2 | Próximas semanas | Contatar 5 professores de português (LinkedIn, Facebook, Instagram). Pedir feedback — não vender. |
| 3 | Após feedback | Definir algoritmo de progressão Kids. Construir Diagnóstico, trilha + XP, painel do professor. |
| 4 | MVP Kids pronto | Piloto gratuito de 3 meses com 1 escola parceira em BH. |
| 5 | Após piloto | Converter para pago. Validar inclusão de Fund. I (4º, 5º). Expandir em BH e MG. |
| 6 | Tração confirmada | Adicionar Radar de Redação (OCR). Iniciar expansão nacional. |

---

## 12 — Decisões em aberto

Lista explícita do que ainda precisa ser resolvido antes de começar a implementar:

1. **Algoritmo de progressão e revisão.** SRS está fora; o que entra no lugar precisa ser definido com base na faixa etária.
2. **Inclusão de Fundamental I (4º, 5º).** Validar pedagogicamente antes de oferecer comercialmente.
3. **Calibração da gamificação para venda B2B.** Quanto de streak, ranking e push é tolerável para o coordenador pedagógico.
4. **Repo / arquitetura.** Projeto separado do VocabBR adulto (decisão tomada). Stack a confirmar — provavelmente Flutter + FastAPI + Supabase, alinhado ao adulto, mas sem compartilhar codebase no curto prazo.
5. **Conteúdo inicial.** Banco de palavras por série, com revisão pedagógica antes do piloto.
