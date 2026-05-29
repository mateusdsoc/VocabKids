# VocabBR Kids - Documento de Produto

> Fonte da verdade atual do projeto. Este documento registra a visão decidida pelo dono do produto, separando claramente o que está definido do que ainda precisa de validação.
>
> Última atualização: 29 de maio de 2026 (rev. 13).

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

O card aparece uma única vez, no início da sessão em que a palavra é introduzida (ver "Estrutura da sessão" na seção 3.4) — não reaparece depois; o lembrete passa a ser o destaque inline (ver abaixo). Como não há regressão de nível (seção 3.4), a palavra nunca volta ao estado de descoberta.

O objetivo é ensinar antes de testar. O aluno precisa ter contato com o significado da palavra antes de ser cobrado. O card não é um flashcard tradicional (não tem lado A/B, não exige memorização). É uma apresentação integrada na trilha, rápida e divertida.

#### Conteúdo do card (mínimo)

O card é deliberadamente mínimo. Campos:

- **Palavra** em destaque;
- **Definição curta e conversacional** — linguagem acessível para a faixa etária, não copiada de dicionário. Ex: "relevante = que importa, que faz diferença numa situação", não "que tem relevância; pertinente";
- **Exemplo de uso em frase** — contexto concreto da palavra;
- **Áudio de pronúncia** (recomendado) — ícone de alto-falante com TTS. Custo baixo e ajuda no contato com palavras nunca vistas.

#### Gancho contextual

Quando a palavra vem do erro da própria redação do aluno, o card mostra a conexão antes de apresentar a palavra nova. Ex: "Você usou 'importante' várias vezes. Conheça uma alternativa:" → card de "relevante". Isso transforma o card de genérico em pessoal e motivador, aplicando o ciclo central do produto (redação revela dificuldade → sistema ensina alternativa).

Para viabilizar isso sem recomputar nada na hora de exibir o card, a atribuição da palavra ao aluno guarda um campo `palavra_gatilho` — qual palavra superutilizada motivou a recomendação (ex.: "importante" gerou "relevante"). Esse dado já é computado durante a análise da redação, então é só persistir na atribuição e ler na exibição do card.

O gancho é **exclusivo da origem pessoal**. Quando a palavra vem do sinal de turma (e não do erro do próprio aluno), o card aparece sem gancho, na forma genérica — para não expor a turma nem soar como culpa coletiva. O campo `palavra_gatilho` só é preenchido para palavras de origem pessoal.

A palavra de origem pessoal **não recebe alerta nem notificação à parte**: ela entra na fila de prioridade pessoal (seção 3.5) e aparece numa sessão seguinte como palavra nova, com card e gancho, pelo fluxo normal — sem interromper o aluno com um aviso separado do tipo "nova palavra da sua redação".

Referências de produto com card de vocabulário no mesmo espírito: Vocabulary.com (definição conversacional + exemplo, para falantes nativos), Duolingo, Memrise e Babbel (vocabulário sempre apresentado em contexto de frase).

#### Destaque inline (lembrete)

Depois do card, nas questões daquela palavra, a palavra nova fica **destacada** visualmente (cor/marcação). Tocar nela **reabre o card** (definição, exemplo, áudio) sem sair da questão — um lembrete leve, inspirado na marcação "palavra nova" do Duolingo. O card cheio aparece uma vez (no início da sessão); o destaque inline é o reforço nas questões seguintes, para quem precisar relembrar sem quebrar o fluxo.

A sequência completa de uma palavra fica:

```
Descoberta → Nível 1 (reconhecimento) → Nível 2 (sinônimo) → Nível 3 (aplicação) → Nível 4 (avaliação) → Dominada ✅
```

### 3.3 Montagem de questões e distratores

Questões são geradas pela IA e armazenadas no banco vinculadas à palavra. O banco é o único armazenamento: na primeira vez que uma palavra precisa de questões, a IA as gera e salva permanentemente; nas vezes seguintes, as questões já existem e são reutilizadas sem custo adicional. Esse padrão é chamado de geração lazy — sem replicação, sem camada separada, sem expiração.

#### Fluxo de geração sob demanda

```
palavra identificada (redação ou banco base)
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
Antes de consultar o banco, a palavra precisa ser reduzida à sua forma base ("correndo" → "correr", "relevantes" → "relevante"). Sem isso, o banco acumula quase-duplicatas que custam geração e confundem o sistema. A lematização é feita pelo **spaCy** (`pt_core_news`) — Hunspell **não** lematiza (só valida existência); são funções distintas que coexistem (ver 3.6 e seção 12).

**Importante — o lema é chave, não texto.** A forma base existe só como **chave de indexação e deduplicação** no banco (como a palavra é guardada e encontrada). Ela **nunca** é o texto que o aluno vê. O enunciado e a resposta são escritos pela IA em português natural, com a flexão que a frase pedir: uma questão arquivada sob a chave `relevante` pode conter "relevantes" na frase ("As descobertas mais ___ mudaram a ciência" → "relevantes"). Por isso o spaCy ser de mão única (só reduz, não reconstrói flexões) não é limitação: reconstruir flexão é trabalho da IA na geração, não do lematizador. Nem spaCy nem Hunspell tocam no conteúdo da questão — atuam só na entrada, para achar a gaveta certa no banco.

**2. Latência no "miss"**
Quando uma palavra é nova, a IA precisa gerar as questões antes de atribuir ao aluno. Essa geração deve ser assíncrona: a palavra entra em uma fila, as questões são geradas em background e aparecem na trilha em seguida — sem bloquear a experiência do aluno.

**3. Segurança dos distratores é responsabilidade da IA**
A IA gera a questão inteira e garante que os distratores não sejam respostas corretas. Não há sistema de categorias semânticas para isso. Problemas que escaparem podem ser sinalizados pelo report do aluno (seção 3.6), mas a geração em si depende da IA fazer isso corretamente no prompt.

### 3.4 Domínio de palavras

Cada palavra tem um estado de aprendizado por aluno. A mecânica segue uma sequência fixa de 4 níveis; no erro o aluno **repete o nível até acertar** (sem regredir), com os retries intercalados ao longo da sessão.

#### Sequência de domínio

A palavra passa por 4 níveis de questão, na ordem:

1. Significado (reconhecimento)
2. Sinônimo (associação)
3. Completar frase (aplicação)
4. Julgar uso (avaliação)

Cada nível tem no mínimo 2 variações de questão (a/b). Passar um nível é acertar **uma** das variações.

#### Regras de progressão

- Acertou uma variação do nível → nível concluído, avança para o próximo.
- Errou → a outra variação ainda não acertada do mesmo nível volta para a fila e reaparece **mais à frente na sessão**, não na hora (ver "Intercalação de erros"). **Não há regressão** a níveis anteriores.
- Nunca se repergunta uma variação que o aluno já acertou.
- Acertou o nível 4 → palavra dominada.

#### Intercalação de erros (estilo fila)

A sessão é uma fila de questões pendentes. Quando o aluno erra, o retry vai para o **fim da fila** — intercala-se com as outras questões pendentes em vez de reaparecer na hora. Isso espaça a repetição, retém melhor e evita monotonia (modelo do Duolingo). Só quando a questão é a **única pendente** restante é que ela entra em loop fixo imediato (alternando entre as variações ainda não acertadas) até o aluno acertar.

Como as questões são de múltipla escolha, o aluno sempre acaba acertando; o "custo" de errar é o tempo gasto, o que naturalmente recompensa quem tenta de verdade em vez de chutar.

#### Estrutura da sessão

Cada sessão tem ~12 questões e introduz **2 palavras novas**. Arranjo no caminho feliz (sem erros):

```
Card palavra 1 → P1 nível 1 → P1 nível 2
Card palavra 2 → P2 nível 1 → P2 nível 2
P1 nível 3 → P2 nível 3
+ 4 questões de revisão (palavras já apresentadas, ainda não dominadas)
```

Os cards das palavras novas ficam **agrupados no início**, cada um colado às primeiras questões da sua palavra — nenhum card interrompe o meio da sessão (ver 3.2).

O **nível 4 (avaliação) de cada palavra nova é adiado ~2 sessões**, entrando como conteúdo de revisão de uma sessão futura, junto de uma questão de revisão dos níveis anteriores. Esse espaçamento antes da avaliação final reforça a retenção: a palavra só é dominada ao passar o nível 4 depois de um intervalo, nunca no mesmo fôlego da introdução.

Quando faltam palavras em progresso para preencher as 4 questões de revisão (ex.: aluno recém-diagnosticado), os slots são completados com mais palavras novas do banco base — as primeiras sessões são naturalmente mais "novas".

#### Seleção da questão de revisão

Para cada palavra em revisão, a questão escolhida segue a prioridade:

1. Variação ainda não usada do **nível 2**.
2. Se as duas variações do nível 2 já se esgotaram (o aluno errou o nível 2 na introdução) → variação não usada do **nível 3** (e vice-versa).
3. Se níveis 2 e 3 já se esgotaram → repete a variação errada do nível 2; errando de novo, a do nível 3; alternando até acertar.

O **nível 1 nunca** é usado como revisão — é o mais fácil (reconhecimento) e só reaparece na própria sessão de introdução, caso o aluno erre lá. Na sessão de revisão, a questão de revisão vem **antes** do nível 4 da palavra.

#### Palavra dominada

Palavra dominada sai da rotina normal de revisão. Não volta a aparecer nas questões regulares.

Exceção prevista: palavras dominadas podem aparecer em eventos ou missões especiais de reforço, mas isso não está no MVP.

#### Exemplos de fluxo

```
Caminho feliz
  Intro:    Card → N1 ✓ → N2 ✓ → N3 ✓        (N4 fica para ~2 sessões depois)
  Revisão:  revisão de N2 ✓ → N4 ✓ → Dominada ✅

Erro no nível 2 na introdução (retry vai pro fim da fila, intercalado)
  Intro:    N1 ✓ → N2a ✗ → (segue as outras questões) → ... → N2b ✓
            (as duas variações de N2 ficaram gastas → a revisão dessa palavra usará N3)
  Revisão:  revisão de N3 ✓ → N4 ✓ → Dominada ✅

Última questão pendente da sessão (loop fixo, nada com que intercalar)
  ... → N3a ✗ → N3b ✗ → N3a ✗ → N3b ✓
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

#### Onboarding (primeira vez)

A primeira experiência do aluno costura entrada, diagnóstico e a primeira palavra:

1. **Entrada** — via código de turma (provisório, até a decisão de autenticação — seção 10).
2. **Boas-vindas temáticas** — uma tela curta apresentando a viagem pelas cidades.
3. **Demonstração** — duas questões-demo roteirizadas: uma mostra como é **acertar** (XP, confete) e outra como é **errar** (feedback gentil, recuperação, sem punição). O objetivo é normalizar o erro antes de cobrar.
4. **Diagnóstico** — a avaliação diagnóstica (acima), enquadrada como jogo e não como prova; posiciona o aluno na trilha.
5. **Primeira palavra** — card de descoberta → nível 1 → primeiro XP, fechando o onboarding com uma vitória.

A ferramenta de report (seção 3.6) é apresentada uma vez durante essas primeiras questões. As demos vêm antes do diagnóstico de propósito: ensinam a mecânica (e que errar é seguro) antes de o sistema calibrar o nível.

#### Adaptação contínua

O sistema ajusta com base no desempenho:

- Acertando muito (90%+) → acelera, oferece palavras mais difíceis
- Errando muito (abaixo de 50%) → freia, consolida o nível atual

#### Trilha independente do ano escolar

A trilha não é organizada por série. O aluno avança conforme o nível de vocabulário dele, não pelo ano que está. Dois alunos do 7º ano podem estar em pontos completamente diferentes da trilha — isso é esperado e correto. O ano escolar afeta apenas a meta semanal configurada pelo professor e o preset de rigor da análise de redação.

Um aluno novo que entra no 8º ano sem histórico no app faz o diagnóstico inicial e é posicionado diretamente no nível correspondente ao seu vocabulário real, sem precisar passar por palavras que já domina.

#### Meta semanal do professor

O professor pode configurar uma meta semanal para a turma, medida em **palavras dominadas por semana**. Essa é a unidade porque é concreta e pedagogicamente significativa — diferente do XP, que varia com o bônus de combo e confundiria a leitura.

- Há um valor padrão sugerido por ano escolar; o professor ajusta se quiser.
- É opcional: se o professor não mexer, o padrão funciona sozinho.
- Cumprir a meta da semana é reconhecido com um indicador visual na home do aluno ("meta cumprida nesta semana"), sem gerar um colecionável no passaporte — a meta tem visibilidade própria, separada do balde de selos de feitos.

#### Fontes de recomendação de palavras

As palavras que chegam para o aluno vêm das seguintes fontes, em ordem de prioridade:

| Prioridade | Fonte | Quando ativa |
|---|---|---|
| 1ª | Erros de vocabulário da redação pessoal | Sempre que o aluno envia uma redação |
| 2ª | Sinal de turma | Sempre que a turma escreve redações |
| 3ª | Banco base por nível de dificuldade | Sempre — preenche os gaps das outras fontes |

O vocabulário de livros seria uma fonte adicional, mas o módulo de livros ficou fora do MVP (ver seção 05). Quando voltar, entra como mais uma fonte, acima do banco base.

**Sinal de turma**: quando muitos alunos da turma superutilizam ou evitam uma palavra nas redações, essa palavra é recomendada para todos os alunos que ainda não a dominaram, mesmo que individualmente não tenham cometido esse erro. Isso cria uma camada de currículo compartilhado baseado na realidade da turma, sem depender apenas dos erros pessoais. O peso do sinal de turma é menor que o da redação pessoal.

*Critério*: uma palavra vira sinal de turma quando é marcada como fraca ou superutilizada nas redações de **pelo menos 30% da turma** dentro do período letivo atual. Em vocabulário não se trata de "erro" e sim de superuso/pobreza (vários alunos repetem a mesma palavra fraca). O limiar de 30% é inicial e ajustável com dados reais.

*Deduplicação com a fonte pessoal*: se uma palavra já está na fila do aluno pela própria redação (fonte 1ª), o sinal de turma para a mesma palavra é ignorado para ele. A palavra aparece uma única vez, com o gancho pessoal. A prioridade pessoal vence.

**Banco base**: as fontes 1ª e 2ª têm cadência irregular — só geram palavras quando o aluno ou a turma escreve. O banco base preenche os gaps e garante que o aluno sempre tenha algo para praticar. A seleção dentro do banco não é aleatória: segue a progressão de dificuldade do aluno (nível atual primeiro, avançando conforme desempenho). Dentro do mesmo nível de dificuldade, a ordem entre palavras tem pouco impacto pedagógico.

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

**Validação:** em ambos os momentos, o Hunspell valida que a palavra existe (ortografia) antes de entrar no banco. A qualidade do sinônimo (adequação e nível) é garantida pela revisão humana no lote inicial e pelo report do aluno no runtime (seção 3.6).

**Identificação das palavras-alvo:** o corpus Essay-BR (~4.570 redações de ensino médio com nota por competência) pode ser usado para análise contrastiva — comparar o vocabulário de redações nota alta vs. baixa e extrair empiricamente as palavras superutilizadas nas redações fracas, que servem de gatilho para o banco.

#### Banco compartilhado entre escolas

O banco de palavras e questões é compartilhado entre todas as escolas. Uma palavra gerada a partir da redação de um aluno de uma escola fica disponível para todos. Isso acelera o crescimento do banco e reduz custos de geração. Dados de alunos e redações continuam isolados por escola.

### 3.6 Geração dinâmica de questões a partir de redações

Quando a redação do aluno identifica palavras fracas ou repetidas, essas palavras precisam virar questões na trilha do aluno.

#### Banco de questões por palavra, não por aluno

As questões são recursos do banco da palavra, não do aluno. O aluno recebe uma atribuição.

Fluxo:

1. A redação identifica que o aluno usa "importante" demais.
2. A IA sugere palavras alternativas: "relevante", "essencial", "significativo", "fundamental".
3. O sistema busca cada alternativa no banco: já existem questões para ela?
4. Se sim: atribui as questões existentes à trilha do aluno.
5. Se não: gera por IA, valida e salva no banco, depois atribui.

Se dois alunos errarem a mesma palavra no mesmo dia, ambos recebem as mesmas questões do banco. Não há duplicação.

#### Publicação direta e report do aluno (MVP)

No MVP as questões geradas pela IA são **publicadas direto** para o aluno, sem revisão prévia. O professor **não** revisa nem aprova questões — a qualidade no runtime é controlada depois da publicação, pelo report do aluno.

Quando uma questão parece errada (ex.: resposta incoerente com o enunciado, sinal de alucinação da IA), o aluno pode **reportá-la** escolhendo um **motivo predefinido** numa caixa de opções (ex.: "a resposta parece errada", "não entendi a palavra"). O report sobe para o **admin da plataforma** — não para o professor. Como o banco de questões é compartilhado entre escolas (seção 3.5), os reports de uma mesma questão **agregam entre todas as escolas**.

Regras:

- **Não isenta a questão**: reportar não pula nem anula a questão; o aluno responde normalmente. Evita usar o report para fugir de questão difícil.
- **Não dá XP**: reportar não rende pontos, para não incentivar spam.
- **Auto-ocultar em 10 reports**: ao acumular 10 reports, a questão **sai automaticamente de circulação** (deixa de ser atribuída) e fica pendente para o admin revisar junto com os reports. O admin decide corrigir, manter ou remover.
- A ferramenta de report é apresentada uma vez ao aluno, no onboarding.

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
| Acertar questão (3ª tentativa em diante) | 50 (piso) |
| Dominar palavra (bônus ao completar todos os níveis da palavra) | 500 |

Os valores não variam por nível de dificuldade: o nível das questões já é adaptado ao aluno, então toda questão acertada vale o mesmo reconhecimento. A penalidade leve da 2ª tentativa (70 em vez de zero) é intencional — errar e corrigir ainda é aprender, e o objetivo é manter o aluno motivado, não punir o erro. A partir da 3ª tentativa o XP continua decrescente, mas com **piso de 50** — como as questões são de múltipla escolha e o aluno sempre acaba acertando (seção 3.4), o piso garante que insistir nunca valha zero, sem premiar o chute como um acerto de primeira. O bônus alto por dominar a palavra (500) reforça a conclusão como a conquista mais valiosa.

Completar uma palavra acertando tudo de primeira rende cerca de 900 XP de base (4 níveis × 100 + 500 de bônus), sem contar o bônus de combo, que adiciona mais conforme a sequência de acertos. Os limiares de XP de cada nó da trilha devem ser dimensionados nessa escala (casa dos milhares). São valores iniciais, ajustáveis depois com dados reais de uso.

#### Bônus de sequência (combo)

Acertos consecutivos de primeira tentativa acumulam um bônus de sequência, somado ao XP base de 100. O bônus tem uma parte fixa e uma parte crescente:

> **bônus = 18 + (2 × posição na sequência)**

| Acerto seguido | Cálculo | XP total da questão |
|---|---|---|
| 1º do dia | 100 (inicia a sequência, sem bônus) | 100 |
| 2º seguido | 100 + (18 + 2) | 120 |
| 3º seguido | 100 + (18 + 4) | 122 |
| 4º seguido | 100 + (18 + 6) | 124 |
| 10º seguido | 100 + (18 + 18) | 136 |

A parte fixa (18) mantém o bônus perto de 20 e evita distorcer a economia de XP; a parte crescente (+2 por acerto) garante que o valor nunca se repita exatamente, dando a sensação de que cada acerto seguido vale mais. O crescimento é suave de propósito — mesmo após 20 acertos seguidos o bônus chega a apenas ~58.

Regras da sequência:

- **Zera ao errar**: qualquer erro reinicia a sequência do zero.
- **Zera na 2ª tentativa**: acertar apenas na 2ª tentativa também reinicia a sequência. Só acertos de primeira tentativa constroem e mantêm o combo.
- **Reinicia por dia**: a sequência é diária; começa do zero a cada novo dia.

#### Estrutura da trilha

A trilha é organizada em três camadas, cada uma com sua recompensa de progressão (garantida — todo aluno ganha ao avançar):

- **Nó**: menor unidade visual. O aluno completa um nó a cada 2–4 sessões (limiar de ~4.500 XP por nó). Completar um nó dá um feedback visual (confete), sem item colecionável.
- **Ponto turístico**: agrupamento de nós dentro de um tema local. Completar um ponto turístico desbloqueia um **cartão-postal** colecionável da atração — encaixa no tema de viagem e vai para a coleção do aluno.
- **Cidade**: conjunto de pontos turísticos. Completar uma cidade dá um **carimbo no passaporte** (ver seção 3.10).

As recompensas de trilha são um dos três baldes do sistema de recompensas (trilha, feitos e eventos), descrito na seção 3.10. O MVP tem **3 cidades** (BH, São Paulo, Rio de Janeiro), cada uma com **6 pontos turísticos** e **4 nós por ponto** — 72 nós no total, dimensionados para ~1 ano letivo de uso típico (~10 palavras dominadas/semana). A definição visual fina de cada ponto turístico e cartão-postal é trabalho de arte, não de produto.

Quando o aluno termina as 3 cidades, entra em **modo livre**: a prática continua normalmente (questões, XP, palavras dominadas), mas o mapa da trilha fica no último nó. Novas cidades serão adicionadas com base nos dados reais de uso do primeiro cliente.

A trilha é parte importante do produto, não apenas decoração. Ela deve ajudar o aluno a entender onde está, o que já completou e qual é o próximo passo.

#### Tela inicial (home) e a trilha como seção

Ao abrir o app, o aluno cai numa **home-hub**, não direto na trilha. A trilha é uma **seção dedicada**, a um toque da home. A escolha é deliberada: o Duolingo pode ter o caminho como tela inicial porque o app *é* só a trilha; o VocabBR Kids orquestra também redação, eventos, leaderboards e dashboards, então uma home que dá acesso a tudo isso faz mais sentido, com a trilha como destino central da prática.

A **home** reúne:

- **Status do aluno** — XP/nível, bolha do nó atual, **número de palavras dominadas** (o contador, não a lista, que ficaria longa demais) e métricas básicas.
- **Ação de prática** — um botão **"Continuar"** como CTA primário, que leva direto à próxima sessão (menor fricção para praticar), e o **acesso ao mapa da trilha** como ação secundária.
- **Atalho de redação** — leva à área de redação (envio das redações atribuídas e dashboards de correção — da última e do ano).
- **Acesso a eventos e leaderboards.**

A **trilha** (seção) mostra o mapa, "você está aqui", o próximo nó/ponto turístico e permite continuar a sessão a partir dali.

**Ao sair de uma sessão, o aluno aterrissa na trilha (mapa), não na home.** Isso reforça o senso de progresso ("avancei aqui") e puxa o aluno para a trilha naturalmente. Cada tela ganha um papel claro: a **home** é o que se vê ao *abrir* o app (o hub); a **trilha** é onde se *aterrissa depois de praticar*.

A hierarquia visual fina dos botões (tamanho do "Continuar" vs. acesso ao mapa) é detalhe de design, a definir na tela.

#### Feedback de progresso na sessão

O progresso é mostrado em camadas, para o aluno sempre sentir avanço sem que a trilha precise interromper o fluxo a cada sessão:

- **Durante a sessão** — uma barra de progresso fina no topo enche a cada questão respondida (inspiração: Duolingo). É o feedback contínuo, dentro da própria questão, sem levar o aluno de volta ao mapa.
- **No fim da sessão** — uma tela de resumo leve, separada da trilha, mostrando o **XP ganho** e a **progressão das palavras** trabalhadas na sessão (ex.: "relevante" subiu de nível, ou foi dominada). Não exibe percentual de acerto — transformaria a sessão em boletim, contra o princípio "errar é aprender" — nem tempo/velocidade — recompensar rapidez incentivaria chute, ruim para vocabulário.
- **Ao completar um nó** — a animação na trilha (marcador avançando, confete). É a celebração maior; o resumo de sessão é o feedback leve e frequente. O aluno típico completa um nó a cada 2–4 sessões; assim a celebração de nó é um marco real, mais raro que o resumo de fim de sessão.

Princípio de animação: curtas e não-bloqueantes. Nenhuma animação deve travar o aluno antes de poder seguir — é o que mantém a experiência rápida mesmo com muito feedback visual (observado no Duolingo).

### 3.8 Expansão para questões de sintaxe

Questões de sintaxe não entram no MVP. Erros de acentuação, vírgulas e estrutura identificados na redação são exibidos como feedback informativo para o aluno, mas não geram questões na trilha.

A arquitetura deve ser extensível: da mesma forma como vocabulário da redação alimenta questões de vocabulário, no futuro erros de sintaxe devem poder alimentar questões de sintaxe sem reconstruir o sistema. Isso é um requisito de design, não de prazo.

Critério para entrar no produto em fase futura: a funcionalidade precisa melhorar a escrita do aluno, não transformar o app em um banco genérico de gramática.

### 3.9 Eventos, competições e leaderboards

O produto tem duas economias de XP distintas: o **XP individual** (descrito em 3.7, que move a trilha do aluno) e o **XP de evento**, usado em competições coletivas.

#### Leaderboard individual da turma

O aluno sempre vê o próprio XP. Da turma, vê apenas o **top 3**, com o valor de XP de cada um dos três. Não tem acesso ao XP exato dos demais colegas. Mostrar o valor dá um objetivo concreto (saber a distância para o topo), e limitar ao top 3 evita expor a posição de quem está no meio ou no fim.

#### XP de evento separado do individual

Quando uma competição começa, o XP de evento **inicia do zero para todos os participantes**, independente do XP individual acumulado. Isso é essencial para a justiça: caso contrário, escolas com alunos usando o app há mais tempo venceriam por inércia, não por engajamento durante o evento. As duas pontuações são contabilizadas separadamente.

#### Eventos de meta coletiva

Existem em dois níveis:

- **Entre turmas** (dentro da mesma escola): o XP de todos os alunos da turma é somado. Os alunos veem a progressão da própria turma e o **top 3 contribuintes** da turma.
- **Entre escolas**: o XP de todos os alunos da escola é somado. O aluno vê a própria contribuição, o **top 10 contribuintes** da escola e a **posição geral das outras escolas** (sem acesso aos detalhes internos delas). A lógica é fazer o aluno se sentir parte da escola, não só da turma.

#### Visibilidade dos educadores

| Papel | Durante competição | Fora de competição |
|---|---|---|
| Professor | Total da escola + desempenho detalhado apenas dos seus próprios alunos | Seus alunos + estatísticas da sua turma |
| Coordenador | Tudo da própria escola | Tudo da própria escola |

Sobre outras escolas, professores e coordenadores veem o mesmo que os alunos: apenas a posição geral, sem detalhes internos.

O modelo de papéis e permissões que sustenta essa visibilidade está na seção 3.11.

#### Criação e adesão a competições

O **admin da plataforma** cria as competições. Cada escola **aceita ou rejeita** participar. A decisão de adesão pode acontecer fora da plataforma (o admin cadastra manualmente as escolas participantes), então a arquitetura precisa ser flexível para inscrever ou não cada escola em uma competição — não assumir que toda escola participa de tudo.

#### Virada de ano letivo

Há uma distinção importante entre o **algoritmo adaptativo** e o **XP/nível visível**:

- O **algoritmo adaptativo nunca zera**. Ele acumula a competência real do aluno (palavras dominadas, padrões de erro, histórico) ano após ano para melhorar a recomendação. Esse é o dado valioso e não se perde.
- O **XP/nível visível é redefinido para a média da turma** na virada de ano (todos os alunos vão para a média — acima, abaixo e na média). Isso evita que um aluno novo entre muito distante da turma e que o número visível vire uma barreira social.

O raciocínio: o XP visível é um indicador motivacional, não o modelo de aprendizado. O aluno forte não perde competência real (volta ao topo rápido porque de fato sabe mais), e o aluno novo não começa milhares de XP atrás.

#### Comportamento da trilha e recompensas durante eventos

Como eventos são pós-MVP (ver seção 06 e escopo por fase), isto fica registrado como **princípio de design**, a refinar quando eventos entrarem no escopo:

- Durante um evento, a **trilha pausa**: a atividade do evento alimenta o **XP de evento** (separado, acima) e **não enche os nós** da trilha individual.
- As **recompensas de trilha pausam junto**: nenhum cartão-postal ou carimbo novo é concedido enquanto a trilha está congelada — voltam a progredir quando o evento termina. Coerência: se a trilha pausa, suas recompensas também pausam.
- **Participar do evento conta como meta semanal cumprida** naqueles dias. Como o evento é um mundo à parte e **não gera palavra dominada** (ver dinâmicas e estrutura na seção 06), ele não soma na meta no sentido literal de "palavras dominadas/semana"; em vez disso, participar **protege** a meta — quem joga o evento não é penalizado por não dominar palavras novas naquela janela.
- A recompensa do próprio evento é o balde "Eventos" (troféus + hall da fama, seção 3.10), com espaço para recompensas mais **temáticas** a explorar (seção 06).

### 3.10 Sistema de recompensas

As recompensas se dividem em três baldes, cada um com uma lógica distinta. Manter essa separação clara evita confundir progresso, mérito individual e competição.

| Balde | Lógica | Recompensas |
|---|---|---|
| **Trilha** | Garantida — todo aluno ganha ao avançar | Nó: feedback visual (confete). Ponto turístico: **cartão-postal** colecionável. Cidade: **carimbo no passaporte** |
| **Feitos** | Condicional individual | **Selos** no passaporte: primeira redação enviada; combo de 10 acertos seguidos; 25, 100 e 250 palavras dominadas (5 selos no total) |
| **Eventos** | Competitivo — só para destaques | **Troféus** digitais (1º/2º/3º) e destaque no hall da fama |

A taxonomia (os três baldes e o que entra em cada um) e o conjunto de colecionáveis estão **decididos**. A arte total do MVP é: **18 cartões-postais** (6 pontos turísticos × 3 cidades) + **3 carimbos** (1 por cidade) + **5 selos** = **26 peças**.

#### Passaporte

Como o tema da trilha é turismo por cidades brasileiras, as recompensas colecionáveis seguem a metáfora de um **passaporte**. O passaporte é também o **perfil do aluno** — ao tocar no próprio avatar ou ícone de perfil, o aluno abre o passaporte, que reúne toda a coleção e o status pessoal em um só lugar. Não há tela separada de "achievements" ou "perfil": o passaporte cumpre esse papel. Os itens são **puramente colecionáveis** no MVP, sem bônus de gameplay, para manter a economia de XP intacta.

O passaporte opera em dois modos distintos:

**Modo 1 — Conquista (animado, disparado uma vez):** ocorre logo após o resumo de sessão, quando há um item novo para revelar. O passaporte sobe em tela cheia, vira automaticamente até a página correta com uma animação de virada de página, o slot do item novo pulsa, o aluno toca para abrir e o item se revela e se encaixa no lugar. Após a revelação, o passaporte permanece aberto para exploração ou o aluno pode fechar. A animação de virada de página é reservada exclusivamente para esse momento de conquista — ela não aparece no Modo 2, o que preserva o impacto.

**Modo 2 — Exploração (estático, scrollável):** ao abrir o passaporte pelo perfil a qualquer hora, o aluno navega por scroll vertical por seções — capa com nome e nível, seção de carimbos de cidades, seção de cartões-postais por cidade, seção de selos de feitos. A sensação de passaporte vem do design visual (texturas, tipografia, layout de coleção), não do gesto de virar páginas. Itens ainda não conquistados aparecem como silhuetas ou com cadeado, tornando visível o que falta ganhar — o que é motivador por si só. Tocar num item já conquistado pode reproduzir uma versão curta da animação de revelação.

Sobre armazenamento: a coleção do aluno é trivialmente pequena — até 26 flags booleanas por aluno (ganhou ou não cada item). Não representa preocupação de armazenamento em nenhuma escala relevante para o MVP.

Sobre a complexidade técnica: a parte lógica é simples (verificar condição → marcar item como ganho → disparar animação). O custo real é de **arte/ilustração** — cada carimbo, cartão-postal e selo precisa ser desenhado. O conjunto do MVP é de 26 peças (18 cartões-postais + 3 carimbos + 5 selos), gerenciável e expansível sem mexer no sistema.

#### Revelação de recompensa

A revelação usa uma animação genérica de **abrir com toque** — o aluno toca no item que pulsa e ele se abre antes de se encaixar no passaporte. A mesma animação é reutilizada para todos os 26 itens; só o asset de arte muda. A mecânica de **raridade aleatória** dos baús (níveis sorteados tipo "mega"/"raro") **não** é adotada.

- **Recompensa determinística, não sorteada** — cada feito dá uma recompensa específica e previsível (completar o ponto turístico X dá o cartão-postal de X). Sem aleatoriedade.
- **Sem loot box** — recompensa aleatória ou por chance levanta questões éticas e regulatórias com público infantil; fica fora.
- **Animação curta e não-bloqueante** — a revelação não pode travar o aluno; mesmo princípio das animações de sessão (seção 3.7).

#### Itens cosméticos de evento (adiado)

Itens cosméticos exclusivos de competição (capa especial de passaporte, moldura no perfil, título exibido no leaderboard) exigem uma camada de customização de perfil que ainda não foi desenhada. Ficam **fora do MVP**: para eventos, troféus e destaque no hall da fama são suficientes. Cosméticos entram quando o perfil/customização do aluno for definido.

### 3.11 Papéis e permissões

O produto tem quatro papéis: **aluno**, **professor**, **coordenador** e **admin da plataforma**. O que separa professor de coordenador não é um conjunto diferente de telas — são os **mesmos dashboards com escopo diferente** — somado à distinção entre **ver** e **configurar**.

#### Modelo de dados: identidade + associações

A identidade (login) é separada do vínculo com a escola. Um `usuário` tem uma ou mais **associações** (memberships); cada associação liga o usuário a uma escola, com um papel e um escopo:

| Papel | Escopo da associação | Pode ver | Pode configurar/agir |
|---|---|---|---|
| Aluno | Uma turma | Próprio progresso + leaderboard limitado (seção 3.9) | Responder questões, enviar redação, reportar questão |
| Professor | Conjunto de turmas | Detalhe dos próprios alunos/turmas | Meta semanal, preset de rigor de redação e atribuição de redação — **só nas próprias turmas** |
| Coordenador | Escola inteira | Tudo da escola (todas as turmas, alunos e professores) | **Nada de configuração pedagógica** — papel de supervisão |
| Admin da plataforma | Global (sem escola) | Agregados de plataforma e reports de questões | Cria competições, trata reports, cuida do banco compartilhado |

Modelar o vínculo como **associação** (em vez de cravar a escola dentro do usuário) resolve de graça o professor que atua em duas escolas (duas associações) e o caso de quem é **coordenador e também leciona** (uma associação de coordenador na escola + uma de professor nas turmas que dá) — sem precisar de um papel híbrido especial. Isso encosta na decisão de autenticação (seção 10), mas a estrutura aqui não a trava.

#### Ver ≠ configurar

A permissão é função de **(papel, escopo, capacidade)**, com duas capacidades distintas:

- **Ver** é por escopo: o professor enxerga as próprias turmas; o coordenador enxerga a escola inteira.
- **Configurar/agir** (meta semanal — seção 3.5; preset de rigor — seção 4.3; atribuir redação — seção 4.6) é **exclusivo do professor**, e só nas suas turmas. O coordenador **não configura nem atribui** — acompanha. Isso separa responsabilidade: quem age na turma é o professor; o coordenador supervisiona.

Os defaults continuam vindo do sistema (valor sugerido por ano — seções 3.5 e 4.3) e são ajustados pelo professor; o coordenador não define padrões. A adesão a competições segue como já decidido (admin cadastra a escola — seção 3.9), fora do fluxo de configuração de turma.

---

## 04 - Redações

### 4.1 Objetivo

O produto deve ter uma funcionalidade de análise de redações para identificar problemas na escrita real do aluno. A análise é multidimensional, não limitada a vocabulário.

A análise deve aceitar:

- redações escritas à mão, enviadas por foto ou imagem (com OCR);
- redações digitais enviadas em PDF.

Ambos os formatos estão no MVP.

### 4.2 Dimensões de análise

A análise da redação cobre múltiplas dimensões:

- repetição e pobreza de vocabulário;
- acentuação;
- uso de vírgulas e pontuação;
- uso adequado de palavras no contexto;
- coesão, estrutura do texto (início, meio e fim) e clareza.

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

O professor **atribui** a redação à turma (tema e prazo); o **aluno envia** em resposta, em dois formatos:

- **Manuscrita**: o aluno fotografa a redação pelo app. O texto é extraído por OCR antes da análise.
- **Digital**: o aluno envia em PDF.

O professor tem acesso às redações de todos os alunos da turma, com estatísticas agregadas por aluno, turma e dimensão de análise. O professor **não escreve nem envia** redações — atribui, visualiza e acompanha.

Como o envio é disparado pela atribuição do professor, enquanto não houver atribuição a fonte de palavras do aluno é o banco base e o sinal de turma (seção 3.5); a fonte pessoal (redação) entra a partir da primeira redação atribuída.

### 4.7 Riscos do OCR

- Palavras mal lidas ou inexistentes: validadas contra dicionário (Hunspell) antes de qualquer ação.
- Ruído do OCR: pré-processamento limpa o texto antes de enviar para análise.

O serviço de OCR escolhido é o **Google Cloud Vision** ($1,50 por 1.000 páginas, primeiras 1.000/mês grátis, suporte PT-BR confirmado). Ver `pesquisa_ferramentas.md` para comparativo com Azure AI Vision.

### 4.8 Ferramenta de análise

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

## 05 - Livros (fora do MVP)

> **Status: fora do MVP, registrado como fase futura.** O módulo foi avaliado e tirado do MVP por uma barreira técnica de conteúdo, descrita abaixo. O núcleo do produto (redação → vocabulário adaptativo) não depende dele.

### 5.1 Objetivo

O produto poderia incluir questões relacionadas a livros lidos pela turma: gerar perguntas sobre uma obra específica para verificar leitura e compreensão, e ampliar o vocabulário a partir das obras trabalhadas em sala.

### 5.2 Por que ficou fora do MVP

O obstáculo é o acesso ao conteúdo do livro. Tanto a compreensão de leitura quanto a extração de vocabulário exigem que a IA conheça o texto da obra a fundo. Para livros canônicos (clássicos, paradidáticos famosos) a LLM conhece bem; para obras obscuras, recentes ou regionais, ela alucina — e a alucinação de vocabulário é ainda mais perigosa que a de enredo, porque uma palavra plausível que não está no livro passa despercebida, enquanto um enredo errado o professor percebe na hora.

As três saídas possíveis têm, cada uma, um custo inescapável:

| Abordagem | Custo |
|---|---|
| Catálogo curado de livros conhecidos | Limita os livros que o professor pode escolher |
| Professor fornece o texto (PDF) | Burocracia de LGPD/pirataria e esforço do professor |
| LLM gera a partir do título | Qualidade não confiável para livros que ela não conhece |

Não é possível ter qualidade confiável, qualquer livro e sem fornecer texto ao mesmo tempo. Sem uma dessas restrições resolvida, o módulo não tem qualidade para um MVP.

### 5.3 Condição para entrar em fase futura

O módulo volta quando houver uma solução de conteúdo confiável — por exemplo, um fornecedor de conteúdo licenciado, RAG sobre texto autorizado, ou uma integração que dê à IA acesso real ao texto da obra. Quando entrar, o vocabulário do livro deve alimentar a trilha pelo mesmo fluxo de geração lazy e validação das demais fontes (seção 3.6).

---

## 06 - Competições e eventos

O software deve ter competições e eventos. A mecânica detalhada (XP de evento separado, leaderboards, visibilidade por papel, criação e adesão) está definida na seção 3.9. Esta seção cobre os tipos de evento e as recompensas.

Tipos possíveis:

- competição entre turmas do mesmo ano;
- competição entre anos diferentes do Fundamental;
- competição entre escolas.

Eventos entre escolas devem acontecer em intervalos maiores, possivelmente a cada 3 meses ou mais, por terem maior complexidade e exigirem maior organização.

Eventos menores, como entre turmas, podem acontecer com mais frequência.

### Dinâmicas e estrutura do evento (pós-MVP)

> Direção de design registrada; eventos são pós-MVP (ver escopo por fase). A refinar quando entrarem no escopo.

Um evento **não** é a trilha com placar. É um **mundo à parte**, com dinâmicas próprias e variadas e temas diversos (pré-história, espaço, Napoleão, fundo do mar...), para não repetir o formato da prática regular e ficar maçante.

**Regra central — a dinâmica decide o vocabulário.** O divisor é a pressão de tempo:

- **Dinâmica com velocidade/cronômetro → só palavras já dominadas.** Velocidade somada a palavra nova premia o chute e atropela o aprendizado cuidadoso de palavra nova (mesmo princípio de "não recompensar rapidez", seção 3.7).
- **Dinâmica exploratória, sem cronômetro → pode introduzir palavra nova**, por dedução, significado e sinônimo. A palavra introduzida no evento é **prévia/aquecimento**: não vira "dominada" por aqui (só na trilha), mas dá familiaridade se reaparecer depois.

**Duas famílias de evento:**

- **A) Mini-jogos de vocabulário** — curtos, gamados, competitivos. Ex.: caça-palavras (palavras antigas, com a pista sendo o significado/sinônimo, não só achar letras); quiz "quem acerta mais" (palavras dominadas; o erro custa mais que a lentidão, para premiar quem sabe e não quem toca rápido); forca por significado e sinônimos (pode ser palavra nova, sem cronômetro).
- **B) Produção e colaboração** — mais longos, sociais, de ordem superior. Ex.: correção de redações entre alunos de forma anônima. Exige cuidado extra: correção **guiada/estruturada** (rubrica, marcar trechos, "a palavra X foi bem usada?"), nunca texto livre, com professor no circuito — o anonimato protege o autor mas pode desinibir comentário maldoso. Amarrada à missão: foco em usar as palavras-alvo na escrita. É uma expansão consciente de escopo (toca escrita, não só vocabulário). Registrada como **ideia para o futuro, não para o MVP** (ver escopo por fase, seção 08).

**Estrutura — evento como trilha temática curta.** Cada evento é uma trilha curta (poucos nós, ~5–8, dimensionada para a janela do evento, ex.: ~7 dias) cujos **nós são mini-jogos diferentes**, com um tema dando a cara da temporada. Os jogos rotacionam entre eventos (uns disponíveis agora, outros depois). Durante o evento, o mapa do evento **substitui** o mapa da trilha principal (que já está congelada, seção 3.9) — nunca dois mapas ao mesmo tempo.

**Entrega técnica (sem travar o celular).** Mini-jogos de palavra são leves (texto + lógica, sem 3D/física) — o gameplay não é o risco; o risco é tamanho/peso. Padrão: o **motor** de cada tipo de jogo embarca uma vez no app e **fica** (é minúsculo e reutilizado); o **conteúdo** do evento (tema, mapa, artes, lista de palavras) é **baixado quando o evento começa e descartado quando termina**. Resumo: "motor fica, conteúdo gira". Assim o app não incha e roda em celular comum. Só uma **mecânica realmente nova** (não tema/palavra nova) pede atualização da loja.

### Recompensas

Os eventos devem ter recompensas para os vencedores, proporcionais à dificuldade e ao tamanho da competição. As recompensas de evento são o balde "Eventos" do sistema de recompensas (seção 3.10), distinto dos selos, carimbos e cartões-postais (que são por feitos individuais e por progressão de trilha).

No MVP, as recompensas de evento são:

- **Troféus digitais** para 1º, 2º e 3º lugares;
- **Destaque no hall da fama** (reconhecimento por turma, ano ou escola).

Há espaço para recompensas mais **temáticas** (ligadas ao tema de cada evento) além do troféu e do hall da fama — registrado como direção a explorar, não como compromisso firme.

Itens cosméticos exclusivos de evento ficam **fora do MVP** — exigem uma camada de customização de perfil ainda não definida (ver seção 3.10).

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

### MVP fatiado: apresentável vs. completo

O MVP é construído em duas fatias, para não atrasar a venda com a parte mais
arriscada:

- **MVP apresentável** (para vender às primeiras escolas): app mobile (Flutter),
  trilha + questões do banco base + diagnóstico + XP/recompensas. A **redação entra
  de forma estática** — a UI do ciclo (tela de redação anotada com cores, dashboard
  de correção) com dados mockados, **sem** OCR/LLM/pipeline rodando — presente para
  justificar a atenção de compra (é o diferencial), mas sem construir o backend
  arriscado antes da venda. Sem web. Custo variável ~$0 (free tier; não chama
  OCR/LLM).
- **MVP completo** (após fechar as primeiras escolas): pipeline real de redação
  (OCR → análise → atribuição de palavras), web/dashboards (React/Next, codebase
  separado) e a infraestrutura sobe de plano (ver seção 12).

A lista de funcionalidades abaixo é o MVP completo. Stack e infraestrutura na
seção 12; racional detalhado em `analise_riscos.md`.

### MVP (completo)

- Plataforma: mobile (iOS e Android); web (dashboards) no MVP completo;
- App de questões de vocabulário (4 tipos fixos: reconhecimento, sinônimo, aplicação, avaliação);
- Card de descoberta na primeira interação com cada palavra;
- Questões geradas pela IA sob demanda (geração lazy), armazenadas permanentemente no banco por palavra;
- Domínio de palavras com sequência fixa e loop até acertar (sem regressão — seção 3.4);
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
- Bônus de sequência (combo) no XP;
- Meta semanal configurável pelo professor (palavras dominadas por semana);
- Painel básico para escola/professor acompanhar progresso.


### Próxima fase provável

- Questões de sintaxe geradas a partir de erros identificados na redação;
- Eventos e competições entre turmas (mecânica já especificada na seção 3.9);
- Expansão do banco de palavras.

### Fases futuras ou em avaliação

- Eventos entre escolas;
- Expansão para Fundamental I;
- Missões especiais de reforço com palavras dominadas;
- Evento de correção de redações entre alunos (família de produção/colaboração; exige moderação guiada/estruturada e toca escrita além de vocabulário — ver seção 06);
- Módulo de livros (compreensão de leitura + vocabulário), quando houver solução de conteúdo confiável (ver seção 05);
- Itens cosméticos de evento, quando houver camada de customização de perfil.

---

## 09 - Fora do escopo atual

Os itens abaixo apareceram em documentos antigos ou foram avaliados e descartados como escopo atual:

- Flashcards de repertório como funcionalidade central (substituído pelo card de descoberta);
- SRS clássico como motor obrigatório;
- Mascote específico já decidido;
- Pricing fechado;
- Lista fechada de escolas-alvo;
- Questões de sintaxe no MVP (sintaxe aparece apenas como feedback informativo na redação);
- Módulo de livros no MVP (barreira de acesso confiável ao conteúdo das obras — ver seção 05);
- Itens cosméticos de evento no MVP (dependem de camada de customização de perfil);
- Ofensiva / sequência de dias (streak diário ao estilo Duolingo) — decidido não usar; o combo por acertos seguidos (seção 3.7) é mecânica distinta e permanece;
- Pipeline complexo de pré-processamento NLP como requisito do MVP.

Esses itens podem voltar a ser discutidos, mas não devem guiar implementação agora.

---

## 10 - Decisões em aberto

> ⚠️ **Prioridade e sequenciamento — LER ANTES DE PEGAR QUALQUER ITEM ABAIXO.**
> O foco atual é construir as **funcionalidades básicas** do MVP apresentável. As
> decisões 1 (modelo de LLM) e 2 (auth/privacidade) estão **deliberadamente
> adiadas para quando houver o primeiro cliente interessado** — NÃO são para
> resolver agora e NÃO bloqueiam o desenvolvimento atual.
>
> Em especial o **modelo de LLM (decisão 1) NÃO é prioridade.** É um reflexo comum
> querer "já escolher o modelo de IA" — resista. O apresentável usa redação
> estática (não chama LLM), a pesquisa de custo já está feita, e a escolha
> definitiva sai só na conversa com o cliente, com redações reais. Trabalhe as
> funcionalidades primeiro.

1. **[ADIADA — não é prioridade agora]** Qual modelo de IA para análise de redações
   e geração de questões? Decidida só **na conversa com o primeiro cliente**, com
   redações reais — junto da decisão 2. A pesquisa já está feita (testar GPT-4o
   mini, Gemini 2.5 Flash-Lite e Gemini 2.5 Flash). Não bloqueia o desenvolvimento:
   o apresentável usa redação estática e não chama LLM; o código de geração fica
   atrás de uma interface que aceita qualquer provider depois.
2. **[ADIADA — não é prioridade agora]** Autenticação e política de privacidade — **decididas apenas quando houver o primeiro cliente interessado**, não antes. Justificativa: o prazo entre a escola aceitar e a implementação é de ~2 semanas (folgado), e o ciclo de venda (oferta em out/nov → implementação em fev, no início do ano letivo) dá bastante tempo. O build de apresentação para as escolas roda com acesso provisório (código de turma — seção 3.5) e não depende dessa decisão. A arquitetura já é auth-agnóstica: o modelo de identidade + associações (seção 3.11) suporta diferentes flows sem retrabalho.
   - *Direção provável, a confirmar com a escola cliente*: SSO institucional (Google/Microsoft) para professores, coordenadores e alunos de escolas que têm e-mail; para escolas sem e-mail, professor/coordenador usam e-mail + magic link e os alunos recebem **código temporário de primeiro acesso** (gerado em lote pelo admin, distribuído em sala) com o qual **definem a própria senha** — só o aluno a conhece. Reset de senha é feito pelo professor, que emite um novo código temporário (sem e-mail nem QR no fluxo do aluno).
3. Recompensas temáticas de evento (pós-MVP) — além de troféu e hall da fama, recompensas ligadas ao tema de cada evento (seção 06).

### Decisões fechadas (registradas para histórico)

| Decisão | Resolução |
|---|---|
| Tipos de questões | 4 tipos fixos (seção 3.1) |
| Módulo de livros no MVP | Não — fora do MVP por barreira de acesso ao conteúdo; fase futura (seção 05) |
| Sintaxe no MVP | Não — apenas feedback informativo na redação |
| OCR | Google Cloud Vision |
| Expansão Fund. I | Não relevante para fase inicial; sem data |
| Plataforma | Mobile (iOS e Android) + web |
| Banco de palavras | Compartilhado entre escolas; dados de alunos isolados por escola |
| Envio de redações | Feito pelo aluno (foto para manuscrita, PDF para digital) |
| Banco de palavras — palavras-alvo | Alternativas às palavras superutilizadas, não listas de frequência |
| Banco de palavras — geração inicial | Assinatura Claude, lotes, revisão humana (tarefa única) |
| Banco de palavras — runtime | API com geração lazy |
| Validação de palavras | Hunspell valida existência; qualidade por revisão humana (lote inicial) e report do aluno → admin (runtime) |
| Validação de questões (runtime) | Publicação direta no MVP (sem revisão do professor); report do aluno com motivo predefinido → admin; 10 reports auto-ocultam a questão, pendente de revisão |
| Montagem de distratores | IA gera questão completa — sem sistema de categorias semânticas |
| Arquitetura de geração de questões | Geração lazy: consulta banco primeiro, IA gera só no miss |
| Tema visual da trilha | Cidades brasileiras como destinos turísticos — MVP: BH, São Paulo, Rio de Janeiro |
| LGPD | Deferido para pré-lançamento com primeiros clientes; arquitetura já é LGPD-friendly |
| Sequência de autenticação e privacidade | Decididas só com o primeiro cliente interessado (ciclo de venda dá folga); arquitetura já auth-agnóstica via identidade + associações (seções 3.11 e 10) |
| Card de descoberta | Mínimo: palavra + definição conversacional + exemplo + áudio (recomendado); gancho contextual quando vem da redação |
| Valores de XP | 100 (1ª tentativa), 70 (2ª), 50 da 3ª em diante (piso), 500 (bônus por dominar palavra); sem variar por dificuldade |
| Bônus de sequência (combo) | 18 + 2×posição por acerto seguido de 1ª tentativa; zera ao errar, na 2ª tentativa e a cada dia |
| Leaderboard de turma | Aluno vê próprio XP + top 3 da turma com valores; não vê XP exato dos demais |
| XP de evento | Separado do XP individual; zera para todos no início da competição |
| Eventos coletivos | Entre turmas (top 3 contribuintes) e entre escolas (top 10 + posição geral das outras) |
| Visibilidade educadores | Professor: total da escola + detalhe dos próprios alunos; coordenador: tudo da escola |
| Criação de competições | Admin da plataforma cria; escola aceita/rejeita; arquitetura inscreve escolas flexivelmente |
| Virada de ano | Algoritmo adaptativo acumula sempre; XP/nível visível vai para a média da turma |
| Gancho contextual / `palavra_gatilho` | Campo guarda só a origem pessoal; palavra de sinal de turma usa card genérico sem gancho |
| Critério de sinal de turma | Palavra fraca/superutilizada em ≥30% da turma no período letivo (ajustável) |
| Deduplicação de fontes | Palavra já na fila por redação pessoal ignora o sinal de turma; aparece uma vez, gancho pessoal |
| Taxonomia de recompensas | Três baldes: trilha (cartão-postal/carimbo), feitos (selos) e eventos (troféus); seção 3.10 |
| Recompensa de ponto turístico | Cartão-postal colecionável |
| Recompensas de evento | Troféus (1º/2º/3º) + hall da fama; itens cosméticos fora do MVP |
| Meta semanal do professor | Configurável em palavras dominadas/semana; default por ano; cumprir dá indicador visual na home, não um colecionável |
| Dimensionamento da trilha | 3 cidades × 6 pontos turísticos × 4 nós = 72 nós; limiar ~4.500 XP por nó; aluno típico completa um nó a cada 2–4 sessões; calibrado para ~1 ano letivo a ~10 palavras/semana |
| Selos de feitos (conjunto inicial) | 5 selos: primeira redação enviada, combo de 10 acertos seguidos, 25/100/250 palavras dominadas |
| Arte total do MVP (colecionáveis) | 18 cartões-postais + 3 carimbos + 5 selos = 26 peças |
| Passaporte e metáfora de colecionáveis | Confirmado como requisito firme do MVP; escala com os 26 itens definidos acima |
| Trilha esgotada (aluno termina as 3 cidades) | Modo livre: prática continua sem avançar o mapa; novas cidades adicionadas com base nos dados reais do primeiro cliente |
| Feedback de progresso na sessão | Barra na sessão + resumo leve no fim (XP + progressão das palavras); sem % de acerto e sem tempo; animação maior só ao completar nó (seção 3.7) |
| Revelação de recompensa do passaporte | Abrir com toque (estilo baú); determinística, sem raridade aleatória nem loot box; animações curtas e não-bloqueantes (seção 3.10) |
| Passaporte como perfil do aluno | Passaporte é a tela de perfil — reúne coleção e status em um lugar só; dois modos: Conquista (animado, pós-sessão, com virada de página) e Exploração (scroll vertical, estático); virada de página reservada ao momento de conquista; itens bloqueados exibidos como silhuetas (seção 3.10) |
| Estrutura da sessão | ~12 questões, 2 palavras novas; cards no início; nível 4 adiado ~2 sessões; 4 questões de revisão (seção 3.4) |
| Mecânica de domínio | Loop até acertar substitui a regressão; retries vão pro fim da fila (intercalados); loop fixo só na última pendente; nunca repergunta variação já acertada (seção 3.4) |
| Seleção de revisão | Prioridade nível 2 → nível 3 → repetir erradas; nível 1 nunca vira revisão; revisão antes do nível 4 (seção 3.4) |
| Lembrete inline do card | Palavra destacada nas questões; tocar reabre o card sem sair (seção 3.2) |
| Onboarding | Entrada (código de turma, provisório) → boas-vindas → 2 questões-demo (acerto e erro) → diagnóstico como jogo → primeira palavra com card; report apresentado 1x (seção 3.5) |
| Envio de redação | Professor atribui (tema/prazo); aluno envia (foto/PDF); fonte pessoal entra na 1ª redação atribuída (seção 4.6) |
| Palavra da redação na trilha | Entra na fila pessoal e aparece com card + gancho pelo fluxo normal; sem alerta/notificação à parte (seção 3.2) |
| Tela inicial (home) | Home-hub (não a trilha): status do aluno (XP/nível, nó atual, nº de palavras dominadas), "Continuar" como CTA primário + acesso ao mapa, atalho de redação, eventos e leaderboards; trilha é seção dedicada (seção 3.7) |
| Saída da sessão | Ao sair de uma sessão, o aluno aterrissa na trilha (mapa), não na home (seção 3.7) |
| Eventos x trilha (pós-MVP) | Evento pausa a trilha e suas recompensas (cartão-postal/carimbo); participar conta como meta semanal cumprida na janela (protege, não soma palavra dominada); recompensa do evento = troféu + hall da fama (seção 3.9) |
| Evento de correção de redação | Ideia para o futuro, não MVP (família produção/colaboração; exige moderação estruturada — seções 06 e 08) |
| Conteúdo/dinâmica do evento (pós-MVP) | A dinâmica decide o vocabulário: com velocidade → só palavras dominadas; sem cronômetro → pode introduzir palavra nova (prévia, não vira dominada). Evento é mundo à parte, com dinâmicas e temas próprios; duas famílias (mini-jogos e produção/colaboração) (seção 06) |
| Estrutura do evento (pós-MVP) | Trilha temática curta (~5–8 nós) cujos nós são mini-jogos; substitui o mapa principal durante o evento; jogos rotacionam entre eventos (seção 06) |
| Entrega técnica de eventos (pós-MVP) | Motor de cada jogo embarca no app e fica; conteúdo do evento baixa no início e é descartado no fim ("motor fica, conteúdo gira"); só mecânica nova pede atualização da loja (seção 06) |
| Papéis e permissões | Quatro papéis (aluno, professor, coordenador, admin); identidade + associações (papel + escopo); permissão = (papel, escopo, capacidade) (seção 3.11) |
| Professor x coordenador | Mesmos dashboards, escopos diferentes: professor vê e configura as próprias turmas; coordenador vê a escola inteira mas é supervisão — não configura nem atribui (seção 3.11) |
| Ofensiva / streak de dias | Fora do produto — não haverá sequência de dias ao estilo Duolingo; o combo por acertos seguidos (seção 3.7) é distinto e permanece (seção 09) |
| Stack — app do aluno | Flutter (mobile-only no apresentável); UI 100% custom dispensa widget nativo, então o "muito Android" não se aplica (seção 12) |
| Stack — web | React/Next, codebase separado, adiada para o MVP completo (seção 12) |
| Stack — backend | Python + FastAPI — ecossistema de IA/NLP e carga I/O-bound (seção 12) |
| Stack — banco de dados | PostgreSQL (via Neon serverless); fila de jobs no próprio Postgres (`procrastinate`), Redis adiado (seção 12) |
| Stack — infra/hospedagem | Cloud Run (compute) + Neon (banco) + Cloudflare R2 (arquivos), região São Paulo; free-tier-first até ~2 escolas (seção 12) |
| Stack — animação | Ferramenta em aberto; resultado é requisito firme desde o apresentável; decisão via teste da peça-âncora (seção 12) |
| Estratégia de infra | Interface estável, provider variável: demo→produção é troca de plano/config, não reescrita; evitar lock-in proprietário (seção 12) |
| MVP fatiado | Apresentável (mobile + trilha/banco base/diagnóstico + redação estática) vs. completo (pipeline de redação + web); seção 08 |
| Lematização | spaCy (`pt_core_news`), confirmado; só no MVP completo; roda quando palavra entra (análise de redação) para casar com o banco; lema é chave de indexação/dedup, nunca o texto exibido (a IA flexiona na geração); Hunspell valida existência, papel distinto (seções 3.3 e 12) |

---

## 11 - Princípio de produto

O VocabBR Kids não deve ser apenas um app de quiz.

Ele deve ser um sistema que observa onde o aluno tem pobreza ou repetição de vocabulário, transforma isso em prática personalizada e acompanha a evolução até que novas palavras sejam realmente incorporadas ao repertório do aluno.

O ciclo completo é: redação revela dificuldade → sistema ensina alternativas → aluno pratica → próxima redação mostra melhoria.

---

## 12 - Stack técnica e infraestrutura

> Decisões de stack tomadas em 29/05/2026. O racional detalhado (trade-offs,
> alternativas descartadas, custos) está em `analise_riscos.md`, seção 07. Esta
> seção é o registro resumido na fonte da verdade.

### Decisões

| Camada | Decisão |
|---|---|
| App do aluno | **Flutter** (iOS + Android), mobile-only no apresentável |
| Web (dashboards) | **React/Next**, codebase separado, no MVP completo |
| Backend | **Python + FastAPI** |
| Banco de dados | **PostgreSQL** (JSONB p/ payload de questão; pgvector disponível) |
| Banco gerenciado | **Neon** (Postgres serverless) |
| Fila de jobs | **Postgres** via `procrastinate` (Redis adiado) |
| Cache | Adiado (Upstash quando houver pressão) |
| Compute | **Cloud Run** (ou Render/Railway) |
| Storage de arquivos | **Cloudflare R2** (API S3) |
| Região | `southamerica-east1` (São Paulo) — residência de dados |
| Animação | **Em aberto** (resultado é requisito firme; ver abaixo) |
| Validação ortográfica | Hunspell (já decidido — seção 3.6) |
| Lematização | **spaCy** (`pt_core_news`) — confirmado; só no MVP completo; usado como chave de indexação/dedup, nunca no texto da questão (seção 3.3) |
| OCR | Google Cloud Vision (já decidido — seção 4.7) |
| Modelo de LLM | **Adiado — não é prioridade** (decisão 1, seção 10): só na conversa com o 1º cliente |

### Princípios

- **Interface estável, provider variável.** A stack fala com interfaces-padrão
  (protocolo Postgres, container Docker, API S3). Sair do free tier para produção é
  **troca de plano/connection string**, não reescrita. Neon, Cloud Run e R2 já são
  production-grade — escala-se subindo de plano no mesmo provider.
- **Evitar lock-in proprietário.** É o que causa refactor doloroso — não o free
  tier. Por isso Neon (Postgres puro) em vez de Supabase (camada proprietária de
  auth/storage/edge).
- **Free-tier-first até ~2 escolas vendidas.** Demo a custo variável ~$0; o
  apresentável (redação estática) nem chama OCR/LLM. Ligar `min-instances=1` para
  matar cold start ao apresentar/em produção.
- **Stack auth-agnóstica.** Identidade + associações (seção 3.11) suporta o flow de
  auth que o primeiro cliente exigir, sem retrabalho (decisão 2, seção 10).

### Animação (ferramenta em aberto)

A animação boa é requisito **desde o apresentável** (justifica a venda); só a
ferramenta fica em aberto, pois "premium + sem designer + sem gastar" não fecham
juntos. Decisão via **teste da peça-âncora**: prototipar a revelação do passaporte
em LottieFiles (assets prontos) vs. código Flutter (`flutter_animate`); se "vender",
fecha barato; senão, abre a conversa de Rive + designer/freelancer. (A IA do Rive
gera apenas a *lógica* de state machine, não a arte — não desbloqueia o
não-designer.)
