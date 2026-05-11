# VocabBR Kids - Documento de Produto

> Fonte da verdade atual do projeto. Este documento substitui os documentos antigos e registra a visão decidida pelo dono do produto, separando claramente o que está definido do que ainda precisa de validação.

---

## 01 - Visão

O VocabBR Kids é um software de vocabulário para escolas brasileiras.

O foco inicial é o Fundamental II, com possibilidade de expansão futura para o Fundamental I em anos mais avançados, principalmente a partir do 3º ou 4º ano, caso a dificuldade pedagógica e a experiência do aluno façam sentido para essa faixa.

A ideia central é ajudar o aluno a ampliar vocabulário em português por meio de questões curtas, progressão por XP e níveis, trilha temática visual e uso inteligente de dados vindos das próprias produções textuais dos alunos.

O produto deve conectar três frentes:

- prática regular de vocabulário por questões;
- análise de redações para identificar necessidades reais de vocabulário;
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
| Professor de português | Identificar dificuldades de vocabulário e acompanhar evolução da turma. |
| Coordenação pedagógica | Ter dados sobre evolução dos alunos e apoiar decisões pedagógicas. |
| Escola | Oferecer uma ferramenta mensurável de desenvolvimento linguístico. |

---

## 03 - Produto decidido

### 3.1 App de questões de vocabulário

O núcleo do produto é um aplicativo com questões de vocabulário. A hipótese atual é trabalhar com aproximadamente 3 a 4 tipos de questões.

Tipos inicialmente previstos:

- escolher o significado correto de uma palavra;
- escolher o melhor sinônimo em determinado contexto;
- completar uma frase com a palavra ou sinônimo adequado;
- identificar se uma palavra foi usada corretamente em uma frase.

O conjunto exato de tipos pode mudar, mas o produto não deve virar uma plataforma genérica de português. O centro continua sendo vocabulário.

### 3.2 Possível expansão para língua portuguesa e sintaxe

Existe interesse em avaliar questões além de vocabulário puro, como:

- acentuação;
- identificação de sujeito;
- identificação de verbo;
- sintaxe básica;
- estrutura da frase;
- outros pontos de língua portuguesa que ajudem diretamente a escrita.

Isso ainda não está decidido. Deve ser tratado como uma hipótese pedagógica, não como obrigação do MVP.

Critério para entrar no produto: a funcionalidade precisa melhorar a escrita e o vocabulário do aluno, e não apenas transformar o app em um banco amplo de gramática.

### 3.3 XP, níveis e trilha temática

As questões dão pontos de experiência (XP). O XP serve para o aluno subir de nível e avançar na trilha.

A progressão deve ser representada por uma trilha temática visual, com inspiração em experiências como Candy Crush ou Duolingo:

- níveis organizados em sequência;
- nós ou fases com exercícios;
- temas ou capítulos visuais;
- indicação clara do progresso;
- recompensas ao completar etapas importantes.

A trilha é parte importante do produto, não apenas decoração. Ela deve ajudar o aluno a entender onde está, o que já completou e qual é o próximo passo.

### 3.4 Domínio de palavras

Cada palavra deve ter um estado de aprendizado por aluno.

Quando o aluno completar todos os exercícios necessários de uma palavra, essa palavra será considerada dominada. Depois de dominada, ela não precisa continuar aparecendo como revisão regular.

Regra de produto atual:

- palavra nova entra na trilha ou em exercícios personalizados;
- aluno pratica a palavra em diferentes formatos;
- ao cumprir os critérios definidos, a palavra vira dominada;
- palavra dominada sai da rotina normal de revisão.

Ainda falta definir tecnicamente quantos acertos, em quais formatos e com qual tolerância de erro fazem uma palavra virar dominada.

---

## 04 - Redações

### 4.1 Objetivo

O produto deve ter uma funcionalidade de análise de redações para identificar problemas de vocabulário na escrita real do aluno.

A análise deve aceitar:

- redações escritas à mão, enviadas por foto ou imagem;
- redações já digitalizadas ou digitadas.

Para redações manuscritas, será necessário extrair o texto por OCR antes da análise.

### 4.2 Análise inicial decidida

A análise mínima deve identificar palavras repetidas em excesso no texto em língua portuguesa.

Exemplo: se o aluno usa "bom", "coisa", "muito" ou "bonito" várias vezes, o sistema deve apontar a repetição e sugerir alternativas melhores de vocabulário.

### 4.3 Ferramenta de análise

A solução deve priorizar custo baixo.

Caminhos possíveis:

- ferramenta simples de processamento de texto para contar repetições e filtrar palavras irrelevantes;
- API de IA barata para análise mais contextual;
- combinação dos dois, usando regra simples quando bastar e IA quando for necessário entender contexto.

A decisão técnica ainda está em aberto. O critério principal é custo-benefício.

### 4.4 Análises futuras a validar

Ainda está em avaliação se a análise de redação deve olhar apenas palavras repetidas ou também outros aspectos, como:

- riqueza vocabular;
- sugestões de sinônimos por contexto;
- sintaxe;
- estrutura da redação;
- clareza de frases;
- coesão e repetição de ideias.

Esses pontos não devem ser assumidos como escopo fechado até validação pedagógica e técnica.

### 4.5 Ligação entre redação e questões

Essa é uma parte essencial do produto.

As palavras repetidas ou fracas identificadas na redação devem alimentar o vocabulário praticado pelo aluno. O sistema deve gerar ou selecionar questões com sinônimos e aplicações dessas palavras.

Exemplo:

1. O aluno repete muito a palavra "importante" na redação.
2. O sistema identifica essa repetição.
3. O app passa a incluir questões com palavras como "relevante", "essencial", "significativo" e "fundamental".
4. O aluno aprende como usar essas alternativas em frases.
5. Em redações futuras, espera-se que ele varie melhor o vocabulário.

O objetivo não é apenas mostrar uma métrica, mas fechar o ciclo: detectar dificuldade, ensinar alternativas e melhorar a escrita.

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

O software deve ter competições e eventos.

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
- dados vindos de redações, principalmente palavras repetidas e sugestões trabalhadas.

O painel não deve ser desenhado antes da definição clara do MVP, mas a necessidade dele deve permanecer registrada.

---

## 08 - Escopo por fase

### MVP provável

O MVP deve focar no núcleo do produto:

- app de questões de vocabulário;
- 3 a 4 tipos de questões;
- XP e níveis;
- trilha temática visual;
- estado de palavra dominada;
- painel básico para escola/professor acompanhar progresso;
- base inicial de palavras adequada ao Fundamental II.

### Próxima fase provável

Depois do núcleo validado:

- análise de redações;
- identificação de palavras repetidas;
- sugestões de sinônimos;
- geração de questões personalizadas a partir da redação.
- Redação de x em x tempos feitas com algumas palavras selecionadas que o aluno dominou.

### Fases futuras ou em avaliação

- análise mais profunda de sintaxe e estrutura da redação;
- questões de língua portuguesa além de vocabulário;
- módulo de livros com perguntas geradas por IA;
- vocabulário extraído de livros;
- eventos entre escolas;
- expansão para Fundamental I.

---

## 09 - Fora do escopo atual

Os itens abaixo apareceram em documentos antigos ou foram especificados cedo demais, mas não devem ser tratados como decisão atual:

- Flashcards de repertório como funcionalidade central;
- SRS clássico como motor obrigatório;
- mascote específico já decidido;
- pricing fechado;
- lista fechada de escolas-alvo;
- stack técnica fechada;
- módulo de livros como MVP obrigatório;
- análise completa de redação como MVP obrigatório;
- gramática/sintaxe como escopo obrigatório.

Esses itens podem voltar a ser discutidos, mas não devem guiar implementação agora.

---

## 10 - Decisões em aberto

1. Quais serão exatamente os 3 ou 4 tipos de questões iniciais?
2. Quantos exercícios uma palavra precisa ter para ser considerada dominada?
3. Palavra dominada nunca volta ou pode voltar apenas em eventos/missões especiais?
4. A análise de redação começa com texto digitado antes de OCR?
5. A análise de redação usará regra simples, IA barata ou abordagem híbrida?
6. A análise de redação ficará limitada a repetição de palavras ou incluirá sintaxe e estrutura?
7. O módulo de livros entra no produto ou fica como experimento posterior?
8. Como o vocabulário extraído de redações e livros será revisado antes de virar questão?
9. Quais recompensas fazem sentido para eventos entre turmas, anos e escolas?
10. A expansão para Fundamental I começa no 3º, 4º ou 5º ano?

---

## 11 - Princípio de produto

O VocabBR Kids não deve ser apenas um app de quiz.

Ele deve ser um sistema que observa onde o aluno tem pobreza ou repetição de vocabulário, transforma isso em prática personalizada e acompanha a evolução até que novas palavras sejam realmente incorporadas ao repertório do aluno.
