# VocabBR Kids — Especificação Funcional do MVP

> **Objetivo deste documento:** responder a duas perguntas:
>
> 1. **O que o sistema deve fazer?** → Seção 1, Requisitos Funcionais.
> 2. **Como o usuário interage com cada tela?** → Seção 2, Fluxos por Tela (inclui jornadas críticas no topo).
>
> Lendo este doc + `product.md`, um designer deve conseguir produzir wireframes de todas as telas do MVP. Lendo este doc + `architecture.md` (a ser criado), um desenvolvedor deve conseguir implementar ponta a ponta.
>
> **Estado:** rascunho. Decisões em aberto marcadas com `> Decisão em aberto:` ao longo do texto.

---

## 0. Premissas e papéis

O VocabBR Kids tem três papéis e três superfícies distintas:

| Papel | Superfície | O que faz |
|---|---|---|
| **Aluno** (9–13 anos) aprox. | App mobile (iOS / Android) | Faz diagnóstico, joga a trilha, completa sessões, lê o livro do bimestre, escreve redações com análise por IA, customiza aparências (a decidir se de tema, mascote ou outra coisa)|
| **Professor** | Painel (web ou mobile — a decidir) | Vê relatórios da turma, acompanha alunos, lê alertas semanais |
| **Coordenador / Admin escolar** | Painel web | Gerencia turmas, importa alunos, vê dados agregados|

> **Decisão em aberto (D-01):** painel do professor é web ou mobile? Web é mais simples para vender (coordenador testa no notebook na reunião), mas professor pode preferir abrir no celular. Recomendação: **web responsivo no MVP**. Mobile vira app dedicado em V2.

> **Decisão em aberto (D-02):** painel admin escolar é separado do painel do professor ou é a mesma URL com permissões? Recomendação: **mesma URL, papéis diferentes** — coordenador vê tudo que o professor vê + abas extras (turmas, alunos, billing).

### Modelo de identidade do aluno

O acesso do aluno pode ser por **código da turma** + seleção de identidade já cadastrada pela escola. Não há criação de conta pelo aluno. Há a posibilidade também de existir um e-mail escolar, podemos utilizar isso.

> **Decisão em aberto (D-03):** se o aluno tiver senha pessoal (4–6 dígitos definidos no primeiro acesso) ou se basta seleção de nome + PIN gerado pela escola. Recomendação: **PIN gerado pela escola, trocável pelo aluno no primeiro acesso**.

---

## 1. Requisitos Funcionais

Cada requisito é atômico e verificável. Referenciados por ID (RF-XX) em specs futuras.

### 1.1 Identidade e Acesso

#### Aluno
- **RF-01** O sistema deve permitir que o aluno entre no app fornecendo login.
- **RF-02** O sistema deve persistir a sessão do aluno entre aberturas do app, sem exigir novo login enquanto o PIN não for redefinido nem o aluno removido da turma.
- **RF-03** O sistema deve permitir que o aluno faça logout (em Configurações para evitar logout acidental).
- **RF-04** O aluno deve poder trocar sua senha no primeiro acesso e, posteriormente, em Configurações.
- **RF-05** Códigos de turma têm prazo de validade definido pela escola (default: 1 ano letivo) e expiram automaticamente.

#### Professor
- **RF-06** O sistema deve permitir login do professor com email + senha.
- **RF-07** O sistema deve permitir login do professor via link mágico enviado por email (alternativa à senha)
- **RF-08** O sistema deve persistir a sessão do professor.
- **RF-09** O sistema deve permitir reset de senha.

#### Admin escolar
- **RF-10** Admin escolar entra pelo mesmo fluxo de login do professor; o backend identifica seu papel pela conta.
- **RF-11** Admin pode promover ou rebaixar professores em sua escola.

### 1.2 Onboarding do aluno

- **RF-12** No primeiro acesso, o sistema deve apresentar uma sequência curta (≤ 4 telas) que: apresenta o lobo-guará, explica a trilha, explica XP/níveis, e prepara para o Diagnóstico.
- **RF-13** O onboarding deve ser pulável após a primeira tela.
- **RF-14** Ao concluir o onboarding, o aluno é levado direto para o Diagnóstico (não para a Trilha).
- **RF-15** O aluno só pode acessar a Trilha após concluir o Diagnóstico inicial.

### 1.3 Diagnóstico de Vocabulário (Killer Feature 1)

- **RF-16** O Diagnóstico deve durar entre 8 e 12 minutos.
- **RF-17** O Diagnóstico deve apresentar entre 25 e 40 questões adaptativas.

> **Decisão em aberto (D-04):** o Diagnóstico é adaptativo (CAT — Computerized Adaptive Testing) ou tem ordem fixa por dificuldade? Adaptativo dá medida mais precisa em menos tempo, mas é mais caro de construir. Recomendação MVP: **ordem semi-adaptativa** — começa fácil, sobe ou desce de bloco a cada 5 questões conforme a taxa de acerto.

- **RF-18** Cada questão do Diagnóstico deve ter 4 alternativas (formato de Reconhecimento).
- **RF-19** O sistema deve permitir pausar o Diagnóstico e retomar do mesmo ponto até X horas depois.

> **Decisão em aberto (D-05):** valor de X em RF-19. Recomendação: **24 horas**.

- **RF-20** Ao concluir, o sistema deve gerar para o aluno: nível inicial, percentual do vocabulário esperado para a série dominado, próximas palavras a aprender.
- **RF-21** Ao concluir, o sistema deve gerar para o professor: lista das palavras que o aluno errou, lista das palavras que dominou, e o nível inicial atribuído. 
- **RF-22** O Diagnóstico deve poder ser refeito apenas pelo professor (forçar repetição) — o aluno não pode refazer por iniciativa própria.
- **RF-23** O Diagnóstico não concede XP nem registra streak — é puramente avaliativo.

### 1.4 Trilha (mapa visual estilo Candy Crush)

- **RF-24** A Trilha deve ser organizada em **capítulos**, cada um com um conjunto de **nós** (níveis).
- **RF-25** Cada nó representa uma sessão de prática focada em um conjunto de palavras.
- **RF-26** O aluno só pode jogar o próximo nó depois de completar o nó anterior do mesmo capítulo (gating sequencial dentro do capítulo).

> **Decisão em aberto (D-06):** capítulos são desbloqueados sequencialmente ou em paralelo? Recomendação: **sequencial no MVP** — bloqueia complexidade visual do mapa e simplifica curva de dificuldade.

- **RF-27** A Trilha deve exibir nós já concluídos com indicação visual distinta (estrelas, cor, marca).
- **RF-28** Cada nó concluído deve receber 1 a 3 estrelas conforme desempenho (% de acertos).

> **Decisão em aberto (D-07):** critério de estrelas. Recomendação: **3 estrelas = ≥ 90% acertos, 2 = 70–89%, 1 = 50–69%, 0 = abaixo (precisa repetir)**.

- **RF-29** O aluno deve poder rejogar nós já concluídos (treino livre, sem ganho de XP novo após o primeiro 3-estrelas).
- **RF-30** Nós especiais (boss de capítulo, missões temáticas, eventos) devem ter ícone distinto na Trilha.
- **RF-31** A Trilha deve indicar visualmente qual é o "próximo nó a jogar" (pulsando ou destacado).

### 1.5 Sessão de Prática

- **RF-32** Cada sessão deve conter entre 5 e 10 exercícios (configurável por capítulo).

> **Decisão em aberto (D-08):** quantidade fixa de 7 ou variável de 5–10 conforme idade/capítulo? Recomendação: **fixa em 7 no MVP**.

- **RF-33** A composição da sessão deve ser determinada pelo capítulo + nó: cada nó tem um conjunto fixo de palavras-alvo + revisões pontuais de palavras de nós anteriores.
- **RF-34** Cada exercício deve ser apresentado em um dos formatos: Reconhecimento (Nível 1), Produção (Nível 2), ou Contextualização (Nível 3).
- **RF-35** O formato de cada exercício deve ser determinado pelo nível atual da palavra para o aluno.
- **RF-36** Ao responder, o aluno deve receber feedback imediato (correto / incorreto), com narração ou animação do mascote.
- **RF-37** Em caso de erro, o feedback deve exibir a resposta correta e, quando disponível, uma explicação curta acessível.
- **RF-38** Ao concluir os exercícios, o sistema deve exibir a tela de Resultado.
- **RF-39** O aluno pode abandonar a sessão (com confirmação); progresso parcial **não** é registrado.
- **RF-40** Vidas / coração / energia: **não** existem no MVP. Aluno pode jogar o quanto quiser.

> **Decisão em aberto (D-09):** sistema de vidas. Modelo Duolingo dá fricção que motiva voltar no dia seguinte, mas é exatamente o tipo de mecânica que coordenador pode rejeitar. Recomendação: **fora do MVP, avaliar pós-piloto**.

### 1.6 Progressão por palavra

- **RF-41** Cada palavra tem um nível de domínio para cada aluno: Novo (não visto) → Nível 1 → 2 → 3 → 4 (dominada).
- **RF-42** Acertar um exercício sobe o nível da palavra em 1 (teto em 4).
- **RF-43** Errar um exercício derruba o nível da palavra em 1 (piso em 1).
- **RF-44** Palavras em nível 4 entram em revisão eventual (revisões esparsas, não em todo nó).

> **Decisão em aberto (D-10):** o algoritmo de revisão. `product.md` afirma que SRS está fora. Recomendação MVP: **revisão por capítulo** — cada nó traz 70% palavras-alvo do nó + 30% revisões aleatórias de palavras já vistas. Sem agendamento por dias. Avaliar pós-piloto se SRS leve melhora retenção.

- **RF-45** Palavra com 3 erros consecutivos deve ser marcada para reaparecer com mais frequência nos próximos nós (lista negra do aluno).

### 1.7 Módulo Livro do Professor (Killer Feature 2)

> **Nota de escopo:** este módulo amplia o app além do vocabulário base. Como Livro, Redação (1.8) e Trilha base devem aparecer juntos na navegação do aluno é uma **decisão em aberto (D-21)** — depende de pesquisa com professores.

- **RF-93** O sistema deve permitir que o professor cadastre um livro como leitura ativa para sua turma fornecendo título e autor (sem upload de arquivo no MVP).
- **RF-94** Ao cadastrar, o backend deve invocar uma API de LLM para gerar: (a) lista de palavras de vocabulário difícil ou relevante presentes no livro, (b) conjunto de perguntas de compreensão de leitura sobre o livro.
- **RF-95** O conteúdo gerado por LLM deve ser cacheado pela chave (título, autor) — livros já processados são reutilizados sem nova chamada de LLM, mesmo que outra turma cadastre o mesmo livro.
- **RF-96** O professor pode revisar a lista de palavras e perguntas geradas antes de liberar para a turma; pode remover itens, mas não editar/criar do zero no MVP.

> **Decisão em aberto (D-18):** revisão pelo professor é obrigatória antes de liberar ou opcional? Recomendação: **opcional, com aviso "conteúdo gerado por IA, recomendamos revisar"**.

- **RF-97** Cada turma tem no máximo um livro ativo por vez. Cadastrar um novo livro arquiva o anterior — alunos passam a ver o novo, e o histórico do anterior fica visível ao professor.
- **RF-98** O Módulo Livro deve apresentar ao aluno dois tipos de exercício: (a) vocabulário, no mesmo formato da Trilha base (Reconhecimento / Produção / Contextualização), (b) perguntas de compreensão de leitura sobre o livro.
- **RF-99** Perguntas de compreensão de leitura usam múltipla escolha com 4 alternativas.
- **RF-100** O aluno só vê o Módulo Livro se a escola tiver liberado e se houver livro ativo cadastrado para a sua turma.
- **RF-101** Progresso no Módulo Livro concede XP e contribui para o nível global do aluno e para o streak.
- **RF-102** O professor visualiza no painel da turma: % das palavras do livro dominadas por aluno e % de perguntas de compreensão acertadas.

### 1.8 Módulo Redação (Killer Feature 3)

- **RF-103** O sistema deve permitir que o aluno submeta uma redação ao Módulo Redação para análise.
- **RF-104** A submissão aceita dois formatos: (a) texto digitado diretamente no app, (b) upload de uma ou mais imagens (foto da redação manuscrita).
- **RF-105** Submissões em imagem devem passar por OCR antes da análise por LLM.
- **RF-106** Após o OCR (quando aplicável), o sistema deve invocar uma API de LLM para analisar a redação identificando: palavras pobres ou repetidas, vocabulário limitado para a série, sugestões de sinônimos mais ricos.
- **RF-107** O aluno deve receber um dashboard com o resultado da análise: lista de palavras repetidas com contagem, sugestões de sinônimos por palavra, métrica simples de riqueza de vocabulário.

> **Decisão em aberto (D-19):** o dashboard inclui sugestões de reescrita de trechos (LLM mostra o trecho original ao lado de uma versão melhorada)? Recomendação: **fora do MVP, avaliar pós-piloto** — bom diferencial mas custa mais tokens e exige validação pedagógica antes.

- **RF-108** Após o dashboard, o sistema deve gerar automaticamente uma sessão de exercícios personalizada com os sinônimos sugeridos, no mesmo formato dos exercícios da Trilha base.
- **RF-109** Cada redação submetida e seu dashboard ficam disponíveis no histórico do aluno e no painel do professor.
- **RF-110** O sistema deve aplicar uma cota de submissões por aluno por período, para controlar custo de LLM e OCR.

> **Decisão em aberto (D-20):** valor da cota em RF-110. Recomendação: **2 redações por aluno por semana**, ajustável pela escola nas configurações.

- **RF-111** O professor pode propor um tema de redação para a turma; sem tema definido, o aluno escolhe livremente o seu.
- **RF-112** O professor recebe notificação (opt-in) quando um aluno da sua turma submete redação.
- **RF-113** Antes de submeter, o aluno deve ver um aviso explícito: "esta redação será analisada por uma IA, não substitui correção do professor".
- **RF-114** Submissões cuja qualidade de OCR for baixa (texto ilegível) devem retornar erro claro pedindo nova foto ou digitação manual.

> **Nota — sintaxe (D-22):** a inclusão de um módulo de sintaxe (questões gramaticais focadas em estrutura de frase) no MVP está em aberto. Pesquisar com professores e dimensionar antes de incluir.

### 1.9 XP, níveis e gamificação cosmética

- **RF-46** O aluno ganha XP por exercício acertado, por sessão completada, por completar um capítulo e por concluir missões.
- **RF-47** O aluno tem um nível global (separado do nível por palavra), que evolui por XP acumulado.
- **RF-48** Subir de nível desbloqueia recompensas cosméticas: skins do mascote, acessórios, cores da interface, selos.
- **RF-49** Recompensas cosméticas **não** afetam aprendizado nem desbloqueiam conteúdo pedagógico.
- **RF-50** O sistema deve manter um streak diário (dias consecutivos com pelo menos 1 sessão).

> **Decisão em aberto (D-11):** streak quebra ao perder um dia ou tem "freeze" automático em finais de semana? Recomendação: **freeze automático em fins de semana e feriados escolares** — alinha com a vida escolar e evita quebra injusta. Coordenador vai aprovar mais facilmente.

- **RF-51** Eventos por tempo limitado podem ser ativados pelo backend, com meta de XP/sessões para ganhar recompensa cosmética.
- **RF-52** Nenhuma recompensa pode ser comprada com dinheiro real — economia 100% interna.
- **RF-53** O ranking interno é por turma, opt-in pela escola, e mostra apenas os top 10 da turma com XP da semana corrente (não histórico).
- **RF-54** Push notifications são opt-in pela escola; aluno não recebe push se a escola desativar.

### 1.10 Mascote (lobo-guará)

- **RF-55** O mascote aparece como guia no onboarding, narrador de feedback nas sessões e personagem das telas de progresso.
- **RF-56** O aluno pode customizar o mascote (acessórios, skins) usando recompensas cosméticas desbloqueadas.
- **RF-57** O mascote tem **estado neutro por padrão** — não há mecânica de "mascote triste se você não voltou" no MVP (potencial gatilho de FOMO que coordenador rejeita).

> **Decisão em aberto (D-12):** mascote dinâmico (humor varia conforme uso) ou estático (apenas apresentação visual). Recomendação: **estático no MVP**.

### 1.11 Painel do Professor

- **RF-58** O professor deve ver lista das suas turmas, com indicador de atividade da semana por turma.
- **RF-59** Ao abrir uma turma, o professor deve ver: ranking interno por XP da semana, palavras mais erradas pela turma, alunos com menos prática nos últimos 7 dias, mapa de domínio (% do vocabulário esperado).
- **RF-60** O professor deve poder abrir o detalhe de cada aluno: nível atual, palavras dominadas, palavras com dificuldade, último acesso, resultado do Diagnóstico.
- **RF-61** O professor deve poder forçar o aluno a refazer o Diagnóstico.
- **RF-62** O professor deve poder receber um relatório semanal por email (opt-in) com resumo da turma.
- **RF-63** O professor **não** edita o catálogo central de palavras nem o conteúdo da Trilha base no MVP. Pode, porém, cadastrar o livro do bimestre (ver 1.7), revisar/remover itens gerados pela LLM, e propor tema de redação para a turma (ver 1.8). Listas personalizadas e missões customizadas livres ficam para V2.
- **RF-64** O professor deve poder exportar relatório da turma em PDF.

### 1.12 Painel Admin Escolar

- **RF-65** O admin deve poder criar, editar e arquivar turmas.
- **RF-66** O admin deve poder importar alunos via CSV (nome + série) ou cadastrar manualmente.
- **RF-67** O admin deve poder gerar e regenerar códigos de turma.
- **RF-68** O admin deve poder gerar PINs em lote para alunos novos.
- **RF-69** O admin deve poder convidar professores por email.
- **RF-70** O admin deve poder atribuir professores a turmas.
- **RF-71** O admin deve ver dashboard agregado da escola: total de alunos ativos, % de adoção por série, evolução de domínio mês a mês.
- **RF-72** O admin deve gerenciar configurações da escola (modo escola, push, ranking) — ver 1.13.
- **RF-73** O admin deve ver e gerenciar a assinatura: plano atual, histórico de cobrança, atualizar dados de pagamento.

### 1.13 Modo Escola e configurações

- **RF-74** A escola deve poder ativar/desativar push notifications globalmente.
- **RF-75** A escola deve poder ativar/desativar streak globalmente.
- **RF-76** A escola deve poder ativar/desativar ranking interno por turma.
- **RF-77** A escola deve poder definir horários permitidos de uso (ex.: bloquear acesso ao app entre 23h e 6h).

> **Decisão em aberto (D-13):** RF-77 (horário permitido). Útil para vender ao coordenador, mas envolve sincronização cliente-servidor de horário e potencial frustração do aluno. Recomendação: **fora do MVP, V2**.

- **RF-78** Configurações default de uma escola nova: push **off**, streak **on com freeze**, ranking **on**.

### 1.14 Conteúdo

- **RF-79** O catálogo de palavras é centralizado (gerenciado pela equipe VocabBR), não editável pela escola.
- **RF-80** Cada palavra tem: definição infantil-amigável, exemplo em frase, série recomendada, tema/capítulo, nível de dificuldade.
- **RF-81** Capítulos e nós são definidos pela equipe VocabBR; ordem fixa.
- **RF-82** O conteúdo do MVP cobre minimamente as séries 6º a 9º ano com vocabulário curricular esperado.

> **Decisão em aberto (D-14):** quantas palavras por série no lançamento. Recomendação: **300 palavras por série, 1.200 no total para Fund. II**.

### 1.15 Persistência e dados

- **RF-83** Cada sessão concluída gera registro com: aluno, nó, data, XP ganho, acertos, erros, duração.
- **RF-84** O progresso por palavra por aluno persiste: nível atual, número de exposições, último resultado, data da última exposição.
- **RF-85** O Diagnóstico inicial gera registro permanente (snapshot) por aluno.
- **RF-86** Dados de aluno são apagáveis a pedido da escola (LGPD).
- **RF-87** Logs de uso individual são armazenados por no mínimo 1 ano letivo.

### 1.16 Pagamento e billing (B2B)

- **RF-88** A assinatura é cobrada da escola, não do aluno.
- **RF-89** Pagamento processado por gateway B2B (não App Store / Google Play).

> **Decisão em aberto (D-15):** gateway de pagamento. Opções: Stripe, Pagar.me, Asaas, boleto direto. Recomendação: **Stripe + boleto via Asaas** (escolas brasileiras frequentemente preferem boleto / nota fiscal).

- **RF-90** O preço varia por porte da escola (ver `product.md` seção 7).
- **RF-91** A escola pode estar em estado **piloto** (3 meses gratuitos) com data de vencimento explícita.
- **RF-92** Ao expirar o piloto sem conversão, todas as turmas da escola entram em modo somente-leitura (alunos podem abrir, mas não jogar).

---

## 2. Fluxos por Tela

Subseções por superfície: 2.A app do aluno, 2.B painel do professor, 2.C painel admin.

### Jornadas críticas

- **J-01 Primeiro acesso do aluno:** Splash → Login (código + nome + PIN) → Onboarding → Diagnóstico → Resultado do Diagnóstico → Trilha. *Não-óbvio:* não dá pra pular o Diagnóstico — sem ele a Trilha não tem dados pra montar nós adaptados.
- **J-02 Retorno diário do aluno:** Splash → Trilha → Sessão (próximo nó) → Resultado → Trilha. *Não-óbvio:* abrir o app não dispara sessão automática — aluno escolhe o nó.
- **J-03 Aluno explora customização:** Trilha → Perfil/Mascote → Customizar → Trilha. *Não-óbvio:* customização não é incluída no fluxo principal de progressão; é uma aba lateral / botão dedicado.
- **J-04 Professor vê turma na segunda-feira:** Login → Lista de Turmas → Turma X → identifica 3 alunos com baixa prática → exporta PDF para reunião pedagógica. *Não-óbvio:* ele sai do app por email, não pelo painel.
- **J-05 Admin onboarding inicial:** Login (primeiro acesso recebido por convite) → Dashboard vazio → Criar Turma → Importar CSV → Gerar Código → Compartilhar com professores. *Não-óbvio:* o sistema não envia código diretamente para alunos — é o professor / coordenador quem distribui.
- **J-06 Aluno troca PIN esquecido:** aluno só consegue se professor regenerar o PIN no painel; aluno **não** tem fluxo de "esqueci minha senha" autônomo (não tem email confiável).
- **J-07 Piloto expira:** escola cai em modo somente-leitura → admin recebe email com link para conversão → admin entra em Billing → escolhe plano → escola volta ao normal.
- **J-08 Aluno submete redação:** Hub do aluno → Módulo Redação → Nova redação → escolhe formato (texto ou foto) → vê aviso de IA → submete → loading (OCR + LLM) → Dashboard → tap em "Praticar sinônimos" → Sessão personalizada gerada na hora → Resultado → volta ao módulo. *Não-óbvio:* a sessão pós-análise é gerada em runtime a partir da redação específica do aluno, não pré-existe no banco.
- **J-09 Professor cadastra livro do bimestre:** Login → Detalhe da Turma → Cadastrar Livro → digita título + autor → loading enquanto LLM processa (ou retorno imediato se cache hit) → Preview da lista de palavras + perguntas → revisa, remove o que não gostou → Confirma → aluno passa a ver Módulo Livro no próximo abrir. *Não-óbvio:* o cadastro pode demorar dezenas de segundos no primeiro uso de um livro inédito; livros já processados por outras turmas voltam instantaneamente.

---

## 2.A App do Aluno

### A.1 Splash

**Propósito:** decidir rota de entrada com base na sessão local.

**Estados:** Verificando sessão / Erro de inicialização (raro, com retry).

**Ações do usuário:** nenhuma.

**Dados consumidos:** sessão local persistida.

**Transições:**
- Sessão válida → Trilha (se Diagnóstico já feito) ou Diagnóstico (se ainda não feito)
- Sem sessão → Login

---

### A.2 Login do Aluno

**Propósito:** identificar o aluno pelo trio código da turma + nome + PIN.

**Estados:**
- **Inserindo código:** input numérico/alfanumérico de 6–8 caracteres do código da turma.
- **Selecionando nome:** após código válido, lista de alunos da turma para seleção (com avatares ou iniciais, sem foto real).
- **Inserindo PIN:** após selecionar nome, input do PIN (4–6 dígitos).
- **Erro de código:** código não existe ou expirou.
- **Erro de PIN:** PIN incorreto. Após 5 tentativas, bloqueia por 15 minutos.
- **Primeiro acesso:** se for primeiro login, força troca de PIN antes de prosseguir.

**Ações do usuário:**
- Inserir código → valida e avança
- Selecionar nome → avança
- Inserir PIN → autentica
- Tap em "esqueci meu PIN" → mensagem orientando falar com professor

**Dados consumidos:** turma (existência + lista de alunos), PIN (validação).

**Dados produzidos:** sessão autenticada do aluno.

**Transições:**
- Login bem-sucedido, primeiro acesso → Trocar PIN → Onboarding
- Login bem-sucedido, retorno → Trilha (ou Diagnóstico se incompleto)

---

### A.3 Onboarding

**Propósito:** apresentar mascote + mecânicas + preparar para Diagnóstico.

**Estados:** sequência de 4 telas (apresentação do lobo-guará, explicação da Trilha, explicação de XP/níveis, "agora vamos descobrir seu nível").

**Ações:** Avançar / Pular (a partir da tela 2).

**Transições:** → Diagnóstico.

---

### A.4 Diagnóstico

**Propósito:** medir nível inicial do aluno e gerar primeiro mapa de domínio.

**Estados:**
- **Tela de partida:** explica que vai durar ~10 min e que não pode acelerar.
- **Questão ativa:** pergunta + 4 alternativas + barra de progresso.
- **Pausa:** aluno pode pausar (ver RF-19) — retomada do mesmo ponto.
- **Erro de rede:** falha ao submeter resposta.
- **Conclusão:** tela de loading que processa resultado.

**Ações:** Selecionar alternativa / Pausar.

**Dados consumidos:** banco de questões do Diagnóstico.

**Dados produzidos:** snapshot inicial (nível, palavras dominadas, palavras erradas, % esperado para a série).

**Transições:** → Resultado do Diagnóstico.

---

### A.5 Resultado do Diagnóstico

**Propósito:** dar fechamento celebratório ao Diagnóstico e introduzir a Trilha.

**Estados:**
- **Resultado normal:** mensagem do mascote, número de palavras certas, nível atribuído, "agora vamos começar sua jornada".

**Ações:** Tap em "Começar Trilha".

**Transições:** → Trilha.

> **Decisão em aberto (D-16):** mostrar percentual exato (ex.: "você domina 58%") ou apenas categoria visual (iniciante / intermediário / avançado) para o aluno? Percentual gera ansiedade em criança fraca. Recomendação: **categoria visual para o aluno; percentual exato apenas no painel do professor**.

---

### A.6 Trilha (Home do Aluno)

**Propósito:** visualizar progresso e iniciar próxima sessão.

**Estados:**
- **Normal:** mapa visual com capítulo atual, nós já concluídos com estrelas, próximo nó destacado, nós futuros bloqueados.
- **Capítulo concluído:** tela celebratória ao terminar um capítulo, com transição para o próximo.
- **Sem progresso:** estado pós-Diagnóstico, primeiro nó disponível, mascote convidando a começar.
- **Modo somente-leitura:** quando piloto da escola expirou (pode olhar mas não jogar).
- **Loading:** carregando dados.

**Elementos persistentes na tela:**
- XP atual + nível global do aluno
- Streak (se ativo na escola)
- Botão de Perfil/Mascote
- Botão de Conquistas/Eventos

**Ações do usuário:**
- Tap em nó disponível → Sessão
- Tap em nó concluído → Sessão (treino livre, sem XP novo após 3 estrelas)
- Tap em nó bloqueado → tooltip "complete o nó anterior"
- Tap em mascote/perfil → Perfil
- Tap em conquistas → Conquistas/Eventos

**Dados consumidos:** Trilha do aluno (capítulos, nós, status), XP, streak, recompensas ativas.

**Transições:** → Sessão / Perfil / Conquistas.

---

### A.7 Sessão de Prática

**Propósito:** executar 7 exercícios (ver D-08) do nó selecionado.

**Estados:**
- **Carregando:** backend prepara exercícios.
- **Exercício ativo:** pergunta + alternativas (formato conforme nível da palavra).
- **Feedback de acerto:** confirmação visual + animação do mascote.
- **Feedback de erro:** resposta correta revelada + explicação curta.
- **Confirmar saída:** diálogo "tem certeza? você vai perder o progresso desta sessão".
- **Erro de rede:** retry / sair sem registrar.

**Ações:** Selecionar resposta / Próximo / Sair.

**Dados consumidos:** exercícios do nó (palavras, formatos, alternativas, gabaritos).

**Dados produzidos:**
- Por exercício: atualização do nível da palavra para o aluno.
- Ao concluir: registro da sessão (XP, acertos, erros, duração, estrelas).

**Transições:**
- Concluir → Resultado da Sessão
- Abandonar → Trilha (sem registrar)

---

### A.8 Resultado da Sessão

**Propósito:** fechamento + recompensa.

**Estados:**
- **Normal:** estrelas conquistadas (animação), XP ganho, palavras que subiram de nível, streak mantido/renovado.
- **Capítulo concluído:** variação especial com recompensa cosmética desbloqueada.
- **Subiu de nível global:** variação que destaca o novo nível do aluno + recompensa.

**Ações:** Tap em "Continuar" → Trilha. Tap em "Ver minhas conquistas" → Conquistas.

**Transições:** → Trilha (default).

---

### A.9 Perfil / Mascote

**Propósito:** customização do mascote + visualização de progresso pessoal.

**Estados:**
- **Visualização:** mascote com customização atual, nível global do aluno, XP total, total de palavras dominadas, streak.
- **Customização aberta:** grade de itens cosméticos (desbloqueados e bloqueados).
- **Detalhe de item:** tap em item desbloqueado para equipar; tap em bloqueado mostra como conquistar.

**Ações:** Equipar item / Trocar avatar / Voltar.

**Dados consumidos:** estado de customização do aluno, lista de recompensas desbloqueadas, lista de recompensas globais.

**Dados produzidos:** atualização da customização atual.

**Transições:** → Trilha.

---

### A.10 Conquistas e Eventos

**Propósito:** mostrar selos conquistados, eventos ativos, ranking interno.

**Estados:**
- **Aba Conquistas:** lista de selos (conquistados e em progresso).
- **Aba Eventos:** evento ativo (se houver) com meta + recompensa + tempo restante.
- **Aba Ranking:** top 10 da turma na semana (apenas se a escola habilitou).

> **Decisão em aberto (D-17):** abas separadas ou tudo na mesma tela rolável? Recomendação: **abas no MVP** — mais limpo, mais escalável.

**Ações:** Navegar entre abas, ver detalhe de selo, ver detalhe de evento.

**Transições:** → Trilha.

---

### A.11 Configurações do aluno

**Propósito:** ações administrativas mínimas.

**Itens:**
- Trocar PIN
- Som on/off
- Sobre / Termos / Privacidade
- Sair

**Transições:** → Login (após sair).

---

### A.12 Módulo Livro

**Propósito:** praticar vocabulário e compreensão de leitura sobre o livro escolhido pelo professor.

**Estados:**
- **Sem livro ativo:** mensagem "seu professor ainda não escolheu um livro" + ilustração do mascote. Sem CTA.
- **Livro ativo, primeira visita:** capa do livro + título + autor + breve apresentação gerada pela LLM ("vamos explorar este livro juntos") + botão "Começar".
- **Hub do livro:** lista visual de exercícios disponíveis, divididos em duas trilhas/seções: Vocabulário do livro e Compreensão de leitura. Indica progresso (% concluído).
- **Sessão ativa:** reusa estrutura da Sessão de Prática (A.7), com palavras/perguntas extraídas do livro.
- **Livro arquivado:** indica que professor trocou de livro, mostra histórico de progresso.

**Ações do usuário:**
- Tap em exercício disponível → Sessão (mesma estrutura de A.7)
- Tap em "ver progresso" → modal com % palavras dominadas + % perguntas acertadas
- Voltar → Trilha / Hub principal

**Dados consumidos:** livro ativo da turma, conteúdo gerado e cacheado por (título, autor), progresso do aluno no livro.

**Dados produzidos:** atualização de progresso por palavra do livro, registro de sessão de compreensão, XP.

**Transições:** → Sessão / Resultado / Trilha.

---

### A.13 Módulo Redação

**Propósito:** submeter redação para análise por IA, receber dashboard e treinar sinônimos sugeridos.

**Estados:**
- **Hub:** botão "Nova redação" + histórico de submissões anteriores (cada uma abre o dashboard correspondente). Indica cota restante (ex.: "1 de 2 redações disponíveis esta semana").
- **Cota esgotada:** botão "Nova redação" desabilitado + texto explicando quando libera.
- **Escolher tema:** se professor propôs tema, exibe; senão, campo livre para o aluno descrever o tema.
- **Aviso pré-submissão:** modal com texto do RF-113 ("esta redação será analisada por uma IA, não substitui correção do professor"). Aluno confirma.
- **Editor de texto:** campo de texto longo + contador de palavras + botão "Enviar para análise".
- **Upload de foto:** seleciona uma ou mais imagens da câmera ou galeria + preview + botão "Enviar para análise".
- **Processando:** loading com texto "estamos analisando sua redação, isso pode levar até X segundos" e animação do mascote. Cobre OCR (se foto) + chamada à LLM.
- **Erro de OCR:** texto ilegível, pedir nova foto ou alternar para digitação.
- **Dashboard de resultado:** lista de palavras repetidas com contagem + sugestões de sinônimos por palavra + métrica de riqueza de vocabulário + botão "Praticar sinônimos agora" + botão "Ver minha redação".
- **Sessão de exercícios pós-análise:** reusa estrutura da Sessão de Prática (A.7), com palavras geradas a partir das sugestões.

**Ações do usuário:**
- Tap em "Nova redação" → escolha de formato (texto / foto)
- Submeter → processa
- Tap em "Praticar sinônimos agora" → Sessão personalizada
- Tap em redação do histórico → Dashboard salvo

**Dados consumidos:** tema (se houver), cota do aluno, configurações da escola para o módulo.

**Dados produzidos:** registro da redação (texto OCR + texto submetido), dashboard, sessão gerada, atualização de progresso por palavra.

**Transições:** → Sessão / Hub / Trilha.

---

## 2.B Painel do Professor

### B.1 Login

**Propósito:** autenticação do professor.

**Estados:** email + senha / link mágico / erro / reset de senha.

**Transições:** → Lista de Turmas.

---

### B.2 Lista de Turmas

**Propósito:** ver turmas atribuídas + indicador rápido de atividade.

**Estados:**
- **Normal:** cards de turmas com: nome, série, número de alunos, atividade da semana (% que praticou), alerta se houver aluno em risco (sem prática 7+ dias).
- **Vazio:** professor sem turma atribuída — convida a falar com coordenador.
- **Loading.**

**Ações:** Tap em turma → Detalhe da Turma.

**Transições:** → Detalhe da Turma.

---

### B.3 Detalhe da Turma

**Propósito:** visão consolidada da turma para uso pedagógico.

**Estados / abas:**
- **Visão geral:** mapa de domínio (% por aluno e da turma), atividade da semana, top 3 palavras mais erradas pela turma, alunos em risco.
- **Alunos:** lista com nome, nível, % dominado, último acesso. Ordenável.
- **Palavras:** lista de palavras do conteúdo atual com % de domínio pela turma, ordenável.
- **Histórico:** evolução semanal do mapa de domínio.

**Ações:**
- Filtrar por aluno
- Tap em aluno → Detalhe do Aluno
- Exportar PDF
- Forçar Diagnóstico de aluno (com confirmação)

**Transições:** → Detalhe do Aluno / Lista.

---

### B.4 Detalhe do Aluno

**Propósito:** visão individual.

**Estados:**
- Normal: nome, série, nível, % dominado, palavras dominadas, palavras com dificuldade, último acesso, snapshot do Diagnóstico, histórico de sessões da semana.

**Ações:** Forçar Diagnóstico / Resetar PIN / Voltar.

**Transições:** → Detalhe da Turma.

---

### B.5 Configurações do Professor

**Propósito:** preferências da conta.

**Itens:** receber relatório semanal por email (toggle) / receber notificação de redação submetida (toggle) / trocar senha / sair.

---

### B.6 Cadastrar Livro da Turma

**Propósito:** definir o livro ativo do bimestre/trimestre e revisar conteúdo gerado pela LLM.

**Estados:**
- **Sem livro:** form com campos título + autor + botão "Gerar conteúdo".
- **Gerando (loading):** texto "estamos preparando o vocabulário e perguntas do livro, isso pode levar até 1 minuto". Backend chama LLM (ou retorna do cache se já existe).
- **Preview do conteúdo:** lista das palavras geradas (com definição/contexto) + lista das perguntas de compreensão (com gabarito). Cada item tem checkbox "incluir/remover".
- **Confirmar liberação:** modal "ao confirmar, os alunos passam a ver o livro novo. Histórico do livro anterior fica disponível mas é arquivado."
- **Livro ativo:** mostra livro atual + botão "Trocar livro" + métricas agregadas (% palavras dominadas pela turma, % perguntas acertadas).
- **Erro da LLM:** mensagem clara + botão tentar novamente.

**Ações:** Cadastrar / Revisar e remover itens / Confirmar / Trocar livro.

**Dados consumidos:** cache de livros já processados, configurações da escola.

**Dados produzidos:** livro ativo da turma, lista curada de palavras e perguntas.

**Transições:** → Detalhe da Turma.

---

### B.7 Redações da Turma

**Propósito:** acompanhar redações submetidas pelos alunos.

**Estados:**
- **Lista:** tabela com aluno, data, tema, métrica resumo (riqueza de vocabulário). Ordenável.
- **Vazio:** "nenhum aluno submeteu redação ainda" + dica de propor tema.
- **Detalhe:** abre o mesmo dashboard que o aluno viu, com texto da redação (OCR ou digitado) + análise da LLM.
- **Propor tema:** form simples para definir tema vigente para a turma; pode limpar para deixar livre.

**Ações:** Filtrar por aluno / Abrir detalhe / Propor tema / Limpar tema.

**Transições:** → Detalhe da Turma.

---

## 2.C Painel Admin Escolar

> **Observação:** todas as telas do painel do professor (B.1–B.5) também são acessíveis pelo admin. Esta seção lista apenas as **abas extras** que aparecem para admins.

### C.1 Dashboard da Escola

**Propósito:** visão agregada para gestão.

**Estados:**
- **Normal:** total de alunos ativos, % de adoção por série, evolução de domínio mês a mês, próximas datas (renovação de contrato, fim do piloto).
- **Piloto ativo:** banner com tempo restante e CTA de conversão.
- **Pós-vencimento:** banner crítico em vermelho.

**Transições:** → Turmas / Alunos / Billing.

---

### C.2 Turmas

**Propósito:** CRUD de turmas.

**Ações:** Criar turma / Editar / Arquivar / Regenerar código / Atribuir professores.

**Estados:** Lista, Criar (form), Editar, Confirmar arquivamento.

---

### C.3 Alunos

**Propósito:** CRUD de alunos + importação em massa.

**Ações:** Importar CSV (template baixável) / Cadastrar manual / Editar / Remover (com confirmação) / Regenerar PIN / Mover de turma.

**Estados:** Lista filtrável por turma/série, Importar (upload + preview + confirmação), Cadastrar (form).

---

### C.4 Professores

**Propósito:** gestão de professores.

**Ações:** Convidar (email) / Editar papel / Atribuir turmas / Remover.

---

### C.5 Configurações da Escola

**Propósito:** modo escola (ver 1.13).

**Itens (toggles):** push notifications / streak / ranking / horário permitido (V2).

---

### C.6 Billing

**Propósito:** gestão de assinatura.

**Estados:**
- **Piloto:** mostra prazo restante + CTA de conversão.
- **Ativa:** plano atual, próxima cobrança, método de pagamento, histórico.
- **Vencida:** alerta + CTA para regularizar.

**Ações:** Atualizar método / Trocar plano / Baixar nota fiscal / Atualizar dados de cobrança.

**Transições:** → Dashboard.

---

## 3. Rastreabilidade

Todo RF da Seção 1 deve aparecer em pelo menos uma tela da Seção 2 (como ação, dado consumido, ou transição). A conferência cruzada faz parte da verificação: nenhuma tela deve ter transição para tela inexistente; jornadas críticas no topo devem ser realizáveis apenas pelas transições descritas.

Specs de implementação futuras (em `specs/`) citam os RFs que cobrem, formando a cadeia `spec → RF → tela → product.md`.

---

## 4. Decisões em aberto (consolidado)

| ID | Tema | Recomendação atual |
|---|---|---|
| D-01 | Painel do professor: web ou mobile | Web responsivo |
| D-02 | Painel admin separado ou junto com professor | Mesma URL, papéis |
| D-03 | Aluno tem senha ou PIN gerado | PIN gerado, trocável |
| D-04 | Diagnóstico adaptativo ou fixo | Semi-adaptativo |
| D-05 | Janela de retomada do Diagnóstico | 24 horas |
| D-06 | Capítulos sequenciais ou paralelos | Sequenciais |
| D-07 | Critério de estrelas (90/70/50) | Conforme proposto |
| D-08 | Quantidade de exercícios por sessão | Fixa em 7 |
| D-09 | Sistema de vidas | Fora do MVP |
| D-10 | Algoritmo de revisão | Por capítulo (70/30), sem agendamento |
| D-11 | Streak quebra ou tem freeze | Freeze automático em fins de semana |
| D-12 | Mascote dinâmico ou estático | Estático |
| D-13 | Bloqueio por horário | V2 |
| D-14 | Quantidade de palavras por série | 300 / série, 1.200 total |
| D-15 | Gateway de pagamento | Stripe + Asaas (boleto) |
| D-16 | Mostrar % do Diagnóstico ao aluno | Categoria visual |
| D-17 | Conquistas/Eventos: abas ou rolável | Abas |
| D-18 | Revisão obrigatória do conteúdo gerado pela LLM (livro) | Opcional, com aviso |
| D-19 | Sugestões de reescrita de trechos na análise de redação | Fora do MVP |
| D-20 | Cota de redações por aluno | 2 por semana, ajustável pela escola |
| D-21 | Integração UX: Trilha base, Livro e Redação juntos ou separados na navegação do aluno | A decidir após pesquisa com professores |
| D-22 | Módulo de sintaxe entra no MVP | A pensar (pesquisar com professores e dimensionar) |
