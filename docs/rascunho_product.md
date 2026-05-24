# VocabBR Kids - Documento de Produto

> Fonte da verdade atual do projeto. Este documento registra a visão decidida pelo dono do produto, separando claramente o que está definido do que ainda precisa de validação.
>
> Última atualização: 24 de maio de 2026.

---

## 01 - Visão

O VocabBR Kids é um software de vocabulário para escolas brasileiras.

O foco inicial é o Fundamental II, com possibilidade de expansão futura para o Fundamental I em anos mais avançados, principalmente a partir do 3º ou 4º ano, caso a dificuldade pedagógica e a experiência do aluno façam sentido para essa faixa.

A ideia central é ajudar o aluno a ampliar vocabulário em português por meio de questões curtas, progressão por XP e níveis, trilha temática visual e uso inteligente de dados vindos das próprias produções textuais dos alunos.

O produto deve conectar três frentes:

- prática regular de vocabulário por questões;
- análise de redações para identificar necessidades reais de vocabulário e outros problemas de escrita;
- personalização do conteúdo para ensinar palavras e sinônimos que resolvam dificuldades observadas na escrita.

---

## 02 - Público

### Público primário

Alunos do Fundamental II, em contexto escolar.

### Público secundário futuro

Alunos do Fundamental I a partir do 3º ou 4º ano, dependendo de validação pedagógica. Essa expansão não deve ser assumida como escopo inicial.

### Usuários e interessados

| Perfil | Interesse principal |
|---|---|
| Aluno | Praticar vocabulário de forma gamificada e objetiva. |
| Professor de português | Identificar dificuldades de vocabulário e escrita, acompanhar evolução da turma. |
| Coordenação pedagógica | Ter dados sobre evolução dos alunos e apoiar decisões pedagógicas. |
| Escola | Oferecer uma ferramenta mensurável de desenvolvimento linguístico. |

---

## 03 - Produto decidido

### 3.1 App de questões de vocabulário

O núcleo do produto é um aplicativo com questões de vocabulário. O produto trabalha com exatamente 4 tipos de questões, em progressão pedagógica fixa:

1. Escolher o significado correto de uma palavra (reconhecimento);
2. Escolher o melhor sinônimo em determinado contexto (associação);
3. Completar uma frase com a palavra ou sinônimo adequado (aplicação);
4. Identificar se uma palavra foi usada corretamente em uma frase (avaliação).

A sequência segue uma progressão do reconhecimento básico até a avaliação crítica. Cada tipo testa uma habilidade diferente do aluno em relação à palavra. O produto não deve virar uma plataforma genérica de português — o centro continua sendo vocabulário.

### 3.2 Card de descoberta

Quando uma palavra nova aparece pela primeira vez para o aluno, ele não vai direto para uma questão. Antes, vê um card de descoberta: uma tela rápida e visual que apresenta a palavra, sua definição curta e um exemplo de uso em contexto.

O card aparece uma única vez, na primeira interação com a palavra. Se o aluno regredir em níveis, não vê o card novamente.

O objetivo é ensinar antes de testar. O aluno precisa ter contato com o significado da palavra antes de ser cobrado. O card não é um flashcard tradicional (não tem lado A/B, não exige memorização). É uma apresentação integrada na trilha, rápida e divertida.

#### Conteúdo do card (mínimo)

O card é deliberadamente mínimo. Campos:

- **Palavra** em destaque;
- **Definição curta e conversacional** — linguagem acessível para a faixa etária, não copiada de dicionário. Ex: "relevante = que importa, que faz diferença numa situação", não "que tem relevância; pertinente";
- **Exemplo de uso em frase** — contexto concreto da palavra;
- **Áudio de pronúncia** (recomendado) — ícone de alto-falante com TTS. Custo baixo e ajuda no contato com palavras nunca vistas.

#### Gancho contextual

Quando a palavra vem do erro da própria redação do aluno, o card mostra a conexão antes de apresentar a palavra nova. Ex: "Você usou 'importante' várias vezes. Conheça uma alternativa:" → card de "relevante". Isso transforma o card de genérico em pessoal e motivador, aplicando o ciclo central do produto (redação revela dificuldade → sistema ensina alternativa).

Referências de produto com card de vocabulário no mesmo espírito: Vocabulary.com (definição conversacional + exemplo, para falantes nativos), Duolingo, Memrise e Babbel (vocabulário sempre apresentado em contexto de frase).

A sequência completa de uma palavra fica:

```
Descoberta → Nível 1 (reconhecimento) → Nível 2 (sinônimo) → Nível 3 (aplicação) → Nível 4 (avaliação) → Dominada ✅
```

### 3.3 Montagem de questões e distratores

Questões são geradas pela IA e armazenadas no banco vinculadas à palavra. O banco é o único armazenamento: na primeira vez que uma palavra precisa de questões, a IA as gera e salva permanentemente; nas vezes seguintes, as questões já existem e são reutilizadas sem custo adicional. Esse padrão é chamado de geração lazy — sem replicação, sem camada separada, sem expiração.

#### Fluxo de geração sob demanda

```
palavra identificada (redação, livro ou banco base)
  → normalização para forma base (lematização)
  → consulta indexada no banco: palavra existe?
     ├─ sim → atribui questões existentes ao aluno
     └─ não → IA gera questões completas → salva no banco → atribui ao aluno
```

#### Questões completas geradas pela IA

A IA gera cada questão de forma completa: resposta correta e distratores incluídos. Por entender contexto e significado, a IA garante que nenhum distrator seja secretamente correto — sem precisar de um sistema de categorias semânticas externo para isso.

Cada palavra recebe no mínimo 2 variações de questão por nível (4 níveis no total).

#### Dados armazenados por palavra

| Dado | Tipo | Quantidade |
|---|---|---|
| Definição | Gerado pela IA | 1 |
| Sinônimos | Gerado pela IA | 2–3 |
| Nível de dificuldade | Atribuído na geração | 1 (escala 1–10) |
| Questões nível 1 — reconhecimento | Gerado pela IA | mínimo 2 variações |
| Questões nível 2 — sinônimo | Gerado pela IA | mínimo 2 variações |
| Questões nível 3 — aplicação | Gerado pela IA | mínimo 2 variações |
| Questões nível 4 — avaliação | Gerado pela IA | mínimo 2 variações |

#### Concerns de implementação

**1. Normalização (crítico)**
Antes de consultar o banco, a palavra precisa ser reduzida à sua forma base ("correndo" → "correr", "relevantes" → "relevante"). Sem isso, o banco acumula quase-duplicatas que custam geração e confundem o sistema. Hunspell ou um lematizador resolve antes da consulta.

**2. Latência no "miss"**
Quando uma palavra é nova, a IA precisa gerar as questões antes de atribuir ao aluno. Essa geração deve ser assíncrona: a palavra entra em uma fila, as questões são geradas em background e aparecem na trilha em seguida — sem bloquear a experiência do aluno.

**3. Segurança dos distratores é responsabilidade da IA**
A IA gera a questão inteira e garante que os distratores não sejam respostas corretas. Não há sistema de categorias semânticas para isso. O professor pode sinalizar problemas via validação híbrida (seção 3.6), mas a geração em si depende da IA fazer isso corretamente no prompt.

### 3.4 Domínio de palavras

Cada palavra tem um estado de aprendizado por aluno. A mecânica de domínio segue uma sequência fixa com regressão controlada.

#### Sequência de domínio

A palavra passa por 4 níveis de questão, na ordem:

1. Significado (reconhecimento)
2. Sinônimo (associação)
3. Completar frase (aplicação)
4. Julgar uso (avaliação)

Cada nível tem no mínimo 2 variações de questão.

#### Regras de progressão e regressão

- Acertou a questão → avança para o próximo nível.
- Errou a questão → tenta a segunda variação do mesmo nível.
- Errou as duas variações do mesmo nível → regride um nível, para uma variação que ainda não realizou. Se já realizou todas do nível anterior, repete uma que já errou.
- Acertou a última questão do nível 4 → palavra dominada.

#### Palavra dominada

Palavra dominada sai da rotina normal de revisão. Não volta a aparecer nas questões regulares.

Exceção prevista: palavras dominadas podem aparecer em eventos ou missões especiais de reforço, mas isso não está no MVP.

#### Exemplos de fluxo

```
Acerta 1 → Acerta 2 → Erra 3a → Acerta 3b → Acerta 4 → Dominada ✅

Acerta 1 → Acerta 2 → Erra 3a → Erra 3b → Volta pra 2 (variação não feita) → Acerta 2 → Tenta 3 (uma das que errou) → Acerta 3 → Acerta 4 → Dominada ✅
```

### 3.5 Vocabulário adaptativo

O nível de vocabulário do aluno não é definido pelo ano escolar. Alunos da mesma turma podem ter níveis muito diferentes.

#### Palavras por nível de dificuldade

O banco de palavras é organizado por nível de dificuldade em uma escala numérica (ex: 1 a 10), não por série.

| Nível | Exemplo de palavras |
|---|---|
| 1–2 | importante, bonito, grande, rápido |
| 3–4 | relevante, admirável, vasto, ágil |
| 5–6 | preponderante, esplêndido, amplo, célere |
| 7–8 | imprescindível, majestoso, abrangente, vertiginoso |

#### Diagnóstico inicial

Quando o aluno entra no app, faz uma avaliação diagnóstica curta (10 a 15 questões de diferentes níveis). O sistema identifica onde ele está e posiciona na trilha de acordo.

- Aluno forte do 7º ano → começa no nível 4–5
- Aluno com dificuldade do 7º ano → começa no nível 2
- Ambos estão na mesma turma, mas cada um na sua trilha

#### Adaptação contínua

O sistema ajusta com base no desempenho:

- Acertando muito (90%+) → acelera, oferece palavras mais difíceis
- Errando muito (abaixo de 50%) → freia, consolida o nível atual

#### Trilha independente do ano escolar

A trilha não é organizada por série. O aluno avança conforme o nível de vocabulário dele, não pelo ano que está. Dois alunos do 7º ano podem estar em pontos completamente diferentes da trilha — isso é esperado e correto. O ano escolar afeta apenas a meta semanal configurada pelo professor e o preset de rigor da análise de redação.

Um aluno novo que entra no 8º ano sem histórico no app faz o diagnóstico inicial e é posicionado diretamente no nível correspondente ao seu vocabulário real, sem precisar passar por palavras que já domina.

#### Fontes de recomendação de palavras

As palavras que chegam para o aluno vêm de quatro fontes, em ordem de prioridade:

| Prioridade | Fonte | Quando ativa |
|---|---|---|
| 1ª | Erros de vocabulário da redação pessoal | Sempre que o aluno envia uma redação |
| 2ª | Sinal de turma | Sempre que a turma escreve redações |
| 3ª | Vocabulário de livros | Quando a turma está lendo um livro |
| 4ª | Banco base por nível de dificuldade | Sempre — preenche os gaps das outras fontes |

**Sinal de turma**: quando muitos alunos da turma erram ou evitam uma palavra nas redações, essa palavra é recomendada para todos os alunos que ainda não a dominaram, mesmo que individualmente não tenham cometido esse erro. Isso cria uma camada de currículo compartilhado baseado na realidade da turma, sem depender apenas dos erros pessoais. O peso do sinal de turma é menor que o da redação pessoal.

**Banco base**: as fontes 1–3 têm cadência irregular — só geram palavras quando o aluno ou a turma escreve. O banco base preenche os gaps e garante que o aluno sempre tenha algo para praticar. A seleção dentro do banco não é aleatória: segue a progressão de dificuldade do aluno (nível atual primeiro, avançando conforme desempenho). Dentro do mesmo nível de dificuldade, a ordem entre palavras tem pouco impacto pedagógico.

#### Base inicial de palavras

O MVP deve começar com 500 a 800 palavras, suficientes para vários meses de uso. O banco será expandido progressivamente.

**O que NÃO usar:** listas de frequência simples. As palavras mais frequentes são justamente as que o aluno já conhece e usa. O objetivo do produto é o oposto — ensinar as palavras que ele deveria usar e não usa.

**Lógica correta:** as palavras-alvo são as alternativas de qualidade para as palavras que o aluno superutiliza. Se o aluno repete "importante", as palavras-alvo são "relevante", "essencial", "significativo", "fundamental". O ponto de partida é o vocabulário pobre/repetido; o banco é construído a partir das alternativas a ele.

#### Motor de seleção e geração: LLM

A seleção das palavras-alvo e a geração de suas questões são feitas por LLM, não por bancos de sinônimos externos (TeP, OpenWordNet-PT, Onto.PT). Esses bancos foram avaliados e descartados como dependência: são desatualizados, têm ruído de geração automática, viés de português europeu ou licença comercial incerta.

A escolha pelo LLM se justifica porque nosso domínio é o caso mais favorável para um modelo: palavras comuns e superutilizadas e seus sinônimos — vocabulário central que LLMs dominam bem em PT-BR. Não é vocabulário raro ou técnico onde a alucinação seria um risco alto.

A geração acontece em dois momentos distintos:

| Momento | Mecanismo | Por quê |
|---|---|---|
| Banco inicial (~500–800 palavras, uma vez) | Assinatura mensal do Claude, geração em lotes, revisão humana | Tarefa pontual e manual; custo fixo compensa mais que tokens avulsos |
| Runtime (palavra nova da redação) | API com geração lazy (ver seção 3.3) | Automático, em produção, sem humano no meio |

**Validação:** em ambos os momentos, o Hunspell valida que a palavra existe (ortografia) antes de entrar no banco. A qualidade do sinônimo (adequação e nível) é garantida pela revisão humana no lote inicial e pela validação híbrida do professor no runtime (seção 3.6).

**Identificação das palavras-alvo:** o corpus Essay-BR (~4.570 redações de ensino médio com nota por competência) pode ser usado para análise contrastiva — comparar o vocabulário de redações nota alta vs. baixa e extrair empiricamente as palavras superutilizadas nas redações fracas, que servem de gatilho para o banco.

#### Banco compartilhado entre escolas

O banco de palavras e questões é compartilhado entre todas as escolas. Uma palavra gerada a partir da redação de um aluno de uma escola fica disponível para todos. Isso acelera o crescimento do banco e reduz custos de geração. Dados de alunos e redações continuam isolados por escola.

### 3.6 Geração dinâmica de questões a partir de redações

Quando a redação do aluno identifica palavras fracas ou repetidas, essas palavras precisam virar questões na trilha do aluno.

#### Banco de questões por palavra, não por aluno

As questões são recursos do banco da palavra, não do aluno. O aluno recebe uma atribuição.

Fluxo:

1. A redação identifica que o aluno usa "importante" demais.
2. O sistema busca no banco: já existem questões para "importante"?
3. Se sim: atribui essas questões à trilha do aluno.
4. Se não: gera por IA, valida e salva no banco, depois atribui.

Se dois alunos errarem a mesma palavra no mesmo dia, ambos recebem as mesmas questões do banco. Não há duplicação.

#### Validação híbrida

Questões geradas por IA são liberadas diretamente para o aluno, mas marcadas como "geradas automaticamente". O professor tem visibilidade e pode revisar, corrigir ou reportar problemas a qualquer momento.

#### Validação de palavras inexistentes

Toda palavra extraída da redação é validada contra um dicionário antes de gerar questões. Se a palavra não existe no dicionário, é tratada como erro ortográfico (gera anotação na redação), não como vocabulário fraco (não gera questão).

A ferramenta recomendada para essa validação é o Hunspell, que é open source, gratuito e tem dicionário PT-BR.

### 3.7 XP, níveis e trilha temática

As questões dão pontos de experiência (XP). O XP serve para o aluno subir de nível e avançar na trilha.

A progressão deve ser representada por uma trilha temática visual, com inspiração em experiências como Candy Crush ou Duolingo.

#### Progressão por XP

A trilha avança por XP, não por número de palavras. As palavras geram XP ao serem dominadas, e o XP enche a barra de cada nó da trilha. Isso desacopla o ritmo visual do aluno (trilha) do currículo adaptativo (palavras por nível de dificuldade), permitindo que cada um evolua no seu ritmo sem travar a trilha.

#### Valores de XP

| Evento | XP |
|---|---|
| Acertar questão (1ª tentativa) | 100 |
| Acertar questão (2ª tentativa) | 70 |
| Dominar palavra (bônus ao completar todos os níveis da palavra) | 500 |

Os valores não variam por nível de dificuldade: o nível das questões já é adaptado ao aluno, então toda questão acertada vale o mesmo reconhecimento. A penalidade leve da 2ª tentativa (70 em vez de zero) é intencional — errar e corrigir ainda é aprender, e o objetivo é manter o aluno motivado, não punir o erro. O bônus alto por dominar a palavra (500) reforça a conclusão como a conquista mais valiosa.

Completar uma palavra acertando tudo de primeira rende cerca de 900 XP (4 níveis × 100 + 500 de bônus). Os limiares de XP de cada nó da trilha devem ser dimensionados nessa escala (casa dos milhares). São valores iniciais, ajustáveis depois com dados reais de uso.

#### Estrutura da trilha

A trilha é organizada em três camadas:

- **Nó**: menor unidade visual. O aluno avança um nó por sessão aproximadamente. Completar um nó é o progresso que o aluno sente a cada vez que joga.
- **Ponto turístico**: agrupamento de nós dentro de um tema local. Completar um ponto turístico desbloqueia uma ilustração ou recompensa visual.
- **Cidade**: conjunto de pontos turísticos. Completar uma cidade é uma conquista relevante e deve ter recompensa especial.

A definição exata de tema, cidades e recompensas ainda está em discussão.

A trilha é parte importante do produto, não apenas decoração. Ela deve ajudar o aluno a entender onde está, o que já completou e qual é o próximo passo.

### 3.8 Expansão para questões de sintaxe

Questões de sintaxe não entram no MVP. Erros de acentuação, vírgulas e estrutura identificados na redação são exibidos como feedback informativo para o aluno, mas não geram questões na trilha.

A arquitetura deve ser extensível: da mesma forma como vocabulário da redação alimenta questões de vocabulário, no futuro erros de sintaxe devem poder alimentar questões de sintaxe sem reconstruir o sistema. Isso é um requisito de design, não de prazo.

Critério para entrar no produto em fase futura: a funcionalidade precisa melhorar a escrita do aluno, não transformar o app em um banco genérico de gramática.

---

## 04 - Redações

### 4.1 Objetivo

O produto deve ter uma funcionalidade de análise de redações para identificar problemas na escrita real do aluno. A análise é multidimensional, não limitada a vocabulário.

A análise deve aceitar:

- redações escritas à mão, enviadas por foto ou imagem (com OCR);
- redações digitadas.

Ambos os formatos estão no MVP.

### 4.2 Dimensões de análise

A análise da redação cobre múltiplas dimensões:

- repetição e pobreza de vocabulário;
- acentuação;
- uso de vírgulas e pontuação;
- uso adequado de palavras no contexto;
- possivelmente: coesão, estrutura do texto (início, meio e fim) e clareza.

Todas as dimensões são analisadas e retornadas como feedback. Entretanto, apenas vocabulário gera questões na trilha do aluno no MVP. As demais dimensões são informativas.

A arquitetura é extensível: quando questões de sintaxe existirem no futuro, os erros de acentuação, vírgula e outros aspectos identificados na redação poderão gerar questões automaticamente, da mesma forma como vocabulário já faz.

### 4.3 Rigor por ano e configuração pelo professor

O rigor da análise é graduado. Alunos mais novos recebem análise mais simples; os mais velhos, mais exigente.

O modelo é de preset inteligente com liberdade de ajuste:

- O sistema vem com um preset por ano escolar (ex: 6º ano = vocabulário + acentuação; 9º ano = todas as dimensões).
- O professor pode ativar ou desativar dimensões de análise conforme a realidade da turma.
- Se o professor não mexer, o padrão funciona razoavelmente bem.

Isso existe porque a realidade pedagógica brasileira é muito desigual. Uma escola particular pode trabalhar coesão textual no 6º ano, enquanto outra ainda está consolidando acentuação básica. O professor deve ter as rédeas, mas com orientação quando possível.

Para o vocabulário adaptativo do aluno: o preset do professor define o piso (o que é esperado para a série). O nível individual do aluno pode refinar para cima (sugestões de alternativas mais sofisticadas como bônus), mas nunca cobra além do preset da turma.

### 4.4 Apresentação para o aluno

A redação corrigida volta para o aluno como um texto anotado com marcações visuais por dimensão. A apresentação deve ser personalizada, divertida e adequada para crianças.

Cada tipo de erro recebe uma cor ou indicador visual diferente:

- Vocabulário repetido/fraco
- Acentuação
- Vírgula e pontuação
- Estrutura e coesão

O aluno lê a redação anotada, entende onde errou e o que pode melhorar. Não é uma tela nova para cada dimensão; é o próprio texto do aluno com camadas de feedback.

### 4.5 Ligação entre redação e questões

Essa é uma parte essencial do produto.

As palavras fracas ou repetidas identificadas na redação alimentam diretamente a trilha de questões de vocabulário do aluno. O sistema busca ou gera questões com sinônimos e aplicações dessas palavras (ver seção 3.6).

Exemplo:

1. O aluno repete muito a palavra "importante" na redação.
2. O sistema identifica essa repetição.
3. O app passa a incluir questões com palavras como "relevante", "essencial", "significativo" e "fundamental".
4. O aluno aprende como usar essas alternativas em frases.
5. Em redações futuras, espera-se que ele varie melhor o vocabulário.

O objetivo não é apenas mostrar uma métrica, mas fechar o ciclo: detectar dificuldade, ensinar alternativas e melhorar a escrita.

### 4.6 Envio de redações

O envio é feito pelo próprio aluno, em dois formatos:

- **Manuscrita**: o aluno fotografa a redação pelo app. O texto é extraído por OCR antes da análise.
- **Digital**: o aluno envia em PDF.

O professor tem acesso às redações de todos os alunos da turma, com estatísticas agregadas por aluno, turma e dimensão de análise. O professor não envia redações — apenas visualiza e acompanha.

### 4.8 Riscos do OCR

- Palavras mal lidas ou inexistentes: validadas contra dicionário (Hunspell) antes de qualquer ação.
- Ruído do OCR: pré-processamento limpa o texto antes de enviar para análise.

O serviço de OCR escolhido é o **Google Cloud Vision** ($1,50 por 1.000 páginas, primeiras 1.000/mês grátis, suporte PT-BR confirmado). Ver `pesquisa_ferramentas.md` para comparativo com Azure AI Vision.

### 4.9 Ferramenta de análise

A decisão técnica sobre qual modelo de IA usar para a análise da redação está em aberto.

O que está decidido:

- A análise contextual (uso adequado de palavras, sinônimos, coesão, estrutura) precisa de IA.
- A validação de palavras inexistentes usa Hunspell (open source, gratuito).

O que está em avaliação:

- Qual modelo de IA usar (GPT-4o mini, Gemini Flash-Lite, Claude Haiku ou outro).
- Se vale adicionar uma camada de pré-processamento com ferramentas como LanguageTool antes da IA.
- A decisão depende de testes de qualidade com redações reais de alunos.

A pesquisa de preços e ferramentas está documentada em `pesquisa_ferramentas.md`.

---

## 05 - Livros

O módulo de livros está no MVP.

### 5.1 Objetivo

O produto inclui questões relacionadas a livros lidos pela turma. A IA gera questões sobre um livro específico, ajudando o professor a verificar se os alunos leram e compreenderam a obra, e ampliando o vocabulário a partir das obras trabalhadas em sala.

### 5.2 Frentes do módulo

O módulo de livros tem duas frentes:

- **Compreensão de leitura**: perguntas sobre o conteúdo, personagens, eventos e interpretação do livro.
- **Vocabulário do livro**: identificação de palavras relevantes, pouco comuns ou sofisticadas que aparecem na obra e podem enriquecer o repertório do aluno.

### 5.3 Integração com vocabulário

Palavras relevantes identificadas nos livros entram no vocabulário do aluno:

1. A turma está lendo um livro com palavras pouco comuns, mas úteis.
2. A IA identifica essas palavras.
3. O professor ou o sistema aprova a lista.
4. O app cria questões para praticar significado, sinônimos e aplicação.
5. Essas palavras passam a fazer parte da trilha ou de uma missão específica.

O fluxo de geração e validação de questões segue o mesmo modelo da seção 3.6 (banco por palavra, validação híbrida com professor).

---

## 06 - Competições e eventos

O software deve ter competições e eventos. Essa funcionalidade está prevista no produto, mas sem prioridade definida nem critério de MVP.

Tipos possíveis:

- competição entre turmas do mesmo ano;
- competição entre anos diferentes do Fundamental;
- competição entre escolas.

Eventos entre escolas devem acontecer em intervalos maiores, possivelmente a cada 3 meses ou mais, por terem maior complexidade e exigirem maior organização.

Eventos menores, como entre turmas, podem acontecer com mais frequência.

### Recompensas

Os eventos devem ter recompensas para os vencedores, proporcionais à dificuldade e ao tamanho da competição.

Exemplos de recompensas possíveis:

- selos;
- troféus digitais;
- itens cosméticos;
- destaque no ranking;
- reconhecimento por turma, ano ou escola.

As recompensas não devem prejudicar o aprendizado nem criar vantagem pedagógica injusta. Elas existem para motivar participação e senso de progresso.

---

## 07 - Painel e métricas

Como o produto é para escolas, precisa existir alguma forma de acompanhamento pedagógico.

O painel ainda não está especificado em detalhe, mas deve permitir que professor ou coordenação acompanhem:

- progresso dos alunos;
- XP e níveis;
- palavras dominadas;
- palavras com maior dificuldade;
- evolução por turma;
- desempenho em eventos;
- dados vindos de redações (erros por dimensão, palavras repetidas, sugestões trabalhadas);
- configuração das dimensões de análise de redação por turma.

O painel não deve ser desenhado antes da definição clara do MVP, mas a necessidade dele deve permanecer registrada.

---

## 08 - Escopo por fase

### MVP

- Plataforma: mobile (iOS e Android) e web;
- App de questões de vocabulário (4 tipos fixos: reconhecimento, sinônimo, aplicação, avaliação);
- Card de descoberta na primeira interação com cada palavra;
- Questões geradas pela IA sob demanda (geração lazy), armazenadas permanentemente no banco por palavra;
- Domínio de palavras com sequência fixa e regressão controlada;
- XP, níveis e trilha temática visual (progressão por XP, estrutura: cidade → ponto turístico → nó);
- Vocabulário adaptativo com diagnóstico inicial e adaptação contínua;
- Base inicial de 500 a 800 palavras;
- Análise de redação multidimensional (vocabulário, acentuação, vírgulas, uso de palavras, coesão);
- Redação digital e manuscrita (OCR via Google Cloud Vision);
- Rigor da redação configurável pelo professor com preset por ano;
- Apresentação da redação corrigida com anotações visuais coloridas;
- Erros de sintaxe e acentuação exibidos como feedback informativo (não geram questões no MVP);
- Vocabulário da redação alimentando questões na trilha do aluno;
- Banco de questões por palavra com geração por IA quando necessário;
- Validação de palavras com Hunspell antes de gerar questões;
- Módulo de livros: compreensão de leitura e vocabulário extraído de obras da turma;
- Painel básico para escola/professor acompanhar progresso.

### Próxima fase provável

- Questões de sintaxe geradas a partir de erros identificados na redação;
- Eventos e competições entre turmas;
- Expansão do banco de palavras.

### Fases futuras ou em avaliação

- Eventos entre escolas;
- Expansão para Fundamental I;
- Missões especiais de reforço com palavras dominadas.

---

## 09 - Fora do escopo atual

Os itens abaixo apareceram em documentos antigos ou foram avaliados e descartados como escopo atual:

- Flashcards de repertório como funcionalidade central (substituído pelo card de descoberta);
- SRS clássico como motor obrigatório;
- Mascote específico já decidido;
- Pricing fechado;
- Lista fechada de escolas-alvo;
- Stack técnica fechada;
- Questões de sintaxe no MVP (sintaxe aparece apenas como feedback informativo na redação);
- Pipeline complexo de pré-processamento NLP como requisito do MVP.

Esses itens podem voltar a ser discutidos, mas não devem guiar implementação agora.

---

## 10 - Decisões em aberto

1. Qual modelo de IA para análise de redações e geração de questões? (pesquisa feita — testar GPT-4o mini, Gemini 2.5 Flash-Lite e Gemini 2.5 Flash com redações reais)
2. Quais recompensas para eventos entre turmas, anos e escolas?
3. Autenticação — como alunos e professores fazem login. Decisão envolve conversa com escolas; precisa ser flexível para atender diferentes contextos.
4. Onboarding e workflow do aluno — fluxo completo de uso ainda a definir.

### Decisões fechadas (registradas para histórico)

| Decisão | Resolução |
|---|---|
| Tipos de questões | 4 tipos fixos (seção 3.1) |
| Módulo de livros no MVP | Sim |
| Sintaxe no MVP | Não — apenas feedback informativo na redação |
| OCR | Google Cloud Vision |
| Expansão Fund. I | Não relevante para fase inicial; sem data |
| Plataforma | Mobile (iOS e Android) + web |
| Banco de palavras | Compartilhado entre escolas; dados de alunos isolados por escola |
| Envio de redações | Feito pelo aluno (foto para manuscrita, PDF para digital) |
| Banco de palavras — palavras-alvo | Alternativas às palavras superutilizadas, não listas de frequência |
| Banco de palavras — geração inicial | Assinatura Claude, lotes, revisão humana (tarefa única) |
| Banco de palavras — runtime | API com geração lazy |
| Validação de palavras | Hunspell valida existência; qualidade por revisão humana/professor |
| Montagem de distratores | IA gera questão completa — sem sistema de categorias semânticas |
| Arquitetura de geração de questões | Geração lazy: consulta banco primeiro, IA gera só no miss |
| Tema visual da trilha | Cidades brasileiras como destinos turísticos — MVP: BH, São Paulo, Rio de Janeiro |
| LGPD | Deferido para pré-lançamento com primeiros clientes; arquitetura já é LGPD-friendly |
| Card de descoberta | Mínimo: palavra + definição conversacional + exemplo + áudio (recomendado); gancho contextual quando vem da redação |
| Valores de XP | 100 (1ª tentativa), 70 (2ª tentativa), 500 (bônus por dominar palavra); sem variar por dificuldade |

---

## 11 - Princípio de produto

O VocabBR Kids não deve ser apenas um app de quiz.

Ele deve ser um sistema que observa onde o aluno tem pobreza ou repetição de vocabulário, transforma isso em prática personalizada e acompanha a evolução até que novas palavras sejam realmente incorporadas ao repertório do aluno.

O ciclo completo é: redação revela dificuldade → sistema ensina alternativas → aluno pratica → próxima redação mostra melhoria.
