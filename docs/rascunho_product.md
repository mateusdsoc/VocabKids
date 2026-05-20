# VocabBR Kids - Documento de Produto

> Fonte da verdade atual do projeto. Este documento registra a visão decidida pelo dono do produto, separando claramente o que está definido do que ainda precisa de validação.
>
> Última atualização: 19 de maio de 2026.

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

O núcleo do produto é um aplicativo com questões de vocabulário. A hipótese atual é trabalhar com aproximadamente 3 a 4 tipos de questões.

Tipos inicialmente previstos:

1. Escolher o significado correto de uma palavra (reconhecimento);
2. Escolher o melhor sinônimo em determinado contexto (associação);
3. Completar uma frase com a palavra ou sinônimo adequado (aplicação);
4. Identificar se uma palavra foi usada corretamente em uma frase (avaliação).

A sequência dos tipos segue uma progressão pedagógica: do reconhecimento básico até a avaliação crítica. Cada tipo testa uma habilidade diferente do aluno em relação à palavra.

O conjunto exato de tipos pode mudar, mas o produto não deve virar uma plataforma genérica de português. O centro continua sendo vocabulário.

### 3.2 Card de descoberta

Quando uma palavra nova aparece pela primeira vez para o aluno, ele não vai direto para uma questão. Antes, vê um card de descoberta: uma tela rápida e visual que apresenta a palavra, sua definição curta e um exemplo de uso em contexto.

O card aparece uma única vez, na primeira interação com a palavra. Se o aluno regredir em níveis, não vê o card novamente.

O objetivo é ensinar antes de testar. O aluno precisa ter contato com o significado da palavra antes de ser cobrado. O card não é um flashcard tradicional (não tem lado A/B, não exige memorização). É uma apresentação integrada na trilha, rápida e divertida.

A sequência completa de uma palavra fica:

```
Descoberta → Nível 1 (reconhecimento) → Nível 2 (sinônimo) → Nível 3 (aplicação) → Nível 4 (avaliação) → Dominada ✅
```

### 3.3 Montagem de questões e distratores

Nem todas as questões precisam ser armazenadas por completo no banco. Algumas podem ser montadas dinamicamente em tempo real.

#### Níveis 1 e 2 (montagem dinâmica)

- Nível 1: a definição correta vem do metadado da palavra. As alternativas erradas (distratores) são definições de outras palavras.
- Nível 2: o sinônimo correto vem do metadado da palavra. Os distratores são sinônimos de outras palavras.

#### Níveis 3 e 4 (conteúdo pré-gerado)

- Nível 3: exige frases com lacunas, pré-escritas ou geradas por IA.
- Nível 4: exige frases de julgamento (certa ou errada), pré-escritas ou geradas por IA.

#### Dados armazenados por palavra

| Dado | Tipo | Quantidade |
|---|---|---|
| Definição | Metadado da palavra | 1 |
| Sinônimos | Metadado da palavra | 2–3 |
| Categoria semântica | Metadado da palavra | 1 |
| Nível de dificuldade | Metadado da palavra | 1 (escala numérica) |
| Frases com lacuna (nível 3) | Conteúdo gerado | mínimo 2 variações |
| Frases de julgamento (nível 4) | Conteúdo gerado | mínimo 2 variações |

#### Categorias semânticas e segurança dos distratores

Cada palavra pertence a uma categoria semântica (ex: tamanho, importância, velocidade, beleza, qualidade). A regra principal é: distratores nunca vêm da mesma categoria semântica da palavra-alvo. Isso impede que duas respostas estejam corretas ao mesmo tempo.

Exemplo para a palavra "relevante" (categoria: importância):

- Resposta correta: "Que tem importância para algo"
- Distratores: definições de palavras das categorias tamanho, velocidade, beleza — nunca importância

Se não houver palavras suficientes de outras categorias no mesmo nível de dificuldade, o sistema relaxa o nível de dificuldade dos distratores. O importante é que a resposta correta esteja no nível adequado.

Além da categoria semântica, o sistema mantém uma lista de sinônimos por palavra e verifica que nenhum distrator está nessa lista.

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

#### Base inicial de palavras

O MVP deve começar com 500 a 800 palavras, suficientes para vários meses de uso. O banco será expandido progressivamente.

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

A progressão deve ser representada por uma trilha temática visual, com inspiração em experiências como Candy Crush ou Duolingo:

- níveis organizados em sequência;
- nós ou fases com exercícios;
- temas ou capítulos visuais;
- indicação clara do progresso;
- recompensas ao completar etapas importantes.

A trilha é parte importante do produto, não apenas decoração. Ela deve ajudar o aluno a entender onde está, o que já completou e qual é o próximo passo.

### 3.8 Expansão para questões de sintaxe

Existe interesse em avaliar questões além de vocabulário puro, como acentuação, sintaxe básica, estrutura da frase e outros pontos de língua portuguesa.

Isso ainda não está decidido como escopo do MVP. Entretanto, a arquitetura do sistema deve ser extensível: da mesma forma como vocabulário da redação alimenta questões de vocabulário, no futuro erros de sintaxe identificados na redação devem poder alimentar questões de sintaxe, sem reconstruir o sistema.

A decisão de incluir ou não questões de sintaxe depende de orçamento e prazo. Se o custo permitir, é um diferencial competitivo forte para atrair mais escolas.

Critério para entrar no produto: a funcionalidade precisa melhorar a escrita do aluno, não apenas transformar o app em um banco amplo de gramática.

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

### 4.6 Redações manuscritas e OCR

Redações escritas à mão são enviadas por foto. O texto é extraído por OCR antes da análise.

Riscos conhecidos do OCR:

- Palavras mal lidas ou inexistentes: validadas contra dicionário (Hunspell) antes de qualquer ação.
- Ruído do OCR: pré-processamento limpa o texto antes de enviar para análise.

Serviços de OCR pesquisados: Google Cloud Vision ($1.50 por 1.000 páginas, primeiras 1.000/mês grátis) e Azure AI Vision. Ver `pesquisa_ferramentas.md` para detalhes.

### 4.7 Ferramenta de análise

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

### 5.1 Ideia em avaliação

Existe interesse em incluir questões relacionadas a livros lidos pela turma, mas isso ainda não está totalmente decidido.

A ideia seria usar uma API de IA para gerar questões sobre um livro específico, ajudando o professor a verificar se os alunos leram e compreenderam a obra.

### 5.2 Possíveis usos

O módulo de livros pode ter duas frentes:

- perguntas de compreensão sobre o livro;
- vocabulário específico do livro.

As perguntas de compreensão serviriam para avaliar leitura.

O vocabulário do livro serviria para identificar palavras diferentes, relevantes ou mais sofisticadas que aparecem naquela obra e que poderiam ser úteis também em redações.

### 5.3 Integração com vocabulário

Se o módulo de livros for incluído, palavras relevantes dos livros poderão entrar no vocabulário do aluno.

Exemplo:

- a turma está lendo um livro com palavras pouco comuns, mas úteis;
- a IA identifica essas palavras;
- o professor ou o sistema aprova a lista;
- o app cria questões para praticar significado, sinônimos e aplicação;
- essas palavras passam a fazer parte da trilha ou de uma missão específica.

Essa funcionalidade deve continuar em avaliação até ficar claro se vale o custo, a complexidade e o valor pedagógico.

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

- App de questões de vocabulário (3 a 4 tipos);
- Card de descoberta na primeira interação com cada palavra;
- Questões montadas dinamicamente (níveis 1–2) e pré-geradas (níveis 3–4);
- Categorias semânticas para distratores seguros;
- Domínio de palavras com sequência fixa e regressão controlada;
- XP, níveis e trilha temática visual;
- Vocabulário adaptativo com diagnóstico inicial e adaptação contínua;
- Base inicial de 500 a 800 palavras;
- Análise de redação multidimensional (vocabulário, acentuação, vírgulas, uso de palavras, coesão);
- Redação digital e manuscrita (OCR);
- Rigor da redação configurável pelo professor com preset por ano;
- Apresentação da redação corrigida com anotações visuais coloridas;
- Vocabulário da redação alimentando questões na trilha do aluno;
- Banco de questões por palavra com geração por IA quando necessário;
- Validação de palavras com Hunspell antes de gerar questões;
- Painel básico para escola/professor acompanhar progresso.

### Próxima fase provável

- Questões de sintaxe e acentuação (se não entrarem no MVP);
- Conexão dos erros de sintaxe da redação com questões de sintaxe;
- Eventos e competições entre turmas;
- Expansão do banco de palavras.

### Fases futuras ou em avaliação

- Módulo de livros com perguntas geradas por IA;
- Vocabulário extraído de livros;
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
- Módulo de livros como MVP obrigatório;
- Gramática/sintaxe como escopo obrigatório do MVP;
- Pipeline complexo de pré-processamento NLP como requisito do MVP.

Esses itens podem voltar a ser discutidos, mas não devem guiar implementação agora.

---

## 10 - Decisões em aberto

1. Quais serão exatamente os 3 ou 4 tipos de questões iniciais? (os tipos previstos estão definidos, mas o conjunto final pode mudar)
2. O módulo de livros entra no produto ou fica como experimento posterior?
3. Quais recompensas fazem sentido para eventos entre turmas, anos e escolas?
4. A expansão para Fundamental I começa no 3º, 4º ou 5º ano?
5. Qual modelo de IA será usado para análise de redações? (pesquisa feita, decisão técnica pendente)
6. Questões de sintaxe entram no MVP ou na fase seguinte? (depende de orçamento e prazo)
7. Quantas categorias semânticas serão necessárias no banco inicial de palavras?
8. Qual serviço de OCR será usado para redações manuscritas? (Google Vision e Azure pesquisados)

---

## 11 - Princípio de produto

O VocabBR Kids não deve ser apenas um app de quiz.

Ele deve ser um sistema que observa onde o aluno tem pobreza ou repetição de vocabulário, transforma isso em prática personalizada e acompanha a evolução até que novas palavras sejam realmente incorporadas ao repertório do aluno.

O ciclo completo é: redação revela dificuldade → sistema ensina alternativas → aluno pratica → próxima redação mostra melhoria.
