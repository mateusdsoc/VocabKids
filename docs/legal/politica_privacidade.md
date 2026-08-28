# Política de Privacidade — VocabKids

> ⚠️ **Escrito com pesquisa de fonte primária (texto da LGPD no Planalto,
> Enunciado CD/ANPD nº 1/2023, Lei 15.211/2025 — ECA Digital, guidelines
> públicas da Apple, política pública da OpenAI — ver
> `docs/legal/fontes_pesquisa.md`), não é aconselhamento jurídico
> individualizado de um advogado.** O texto abaixo reflete o entendimento
> mais defensável a partir dessas fontes públicas no momento da escrita
> (26/08/2026) — leis e políticas de provedor mudam; revisitar quando algo
> relevante mudar (o `ropa.md` tem uma seção "quando revisitar"). Escrito a
> partir do schema real do backend (o que a app efetivamente coleta) e das
> regras R-LG-1 a R-LG-5 de `docs/produto/plano_b2c.md` §11.1. Campos entre
> colchetes `[...]` são placeholders que só você pode preencher (CPF, e-mail
> definitivo) — não são incerteza jurídica, são dado que falta.
>
> Versão: `1.0-rascunho` — data: 26/08/2026. Quando publicada de verdade,
> esta versão é o valor gravado em `conta.consentimento_versao` na primeira
> vez que um responsável aceitar (ver Termo de Consentimento Parental).

## 1. Quem somos

O VocabKids é operado por **[Nome completo do responsável legal — pessoa
física, até a abertura de CNPJ]**, [CPF: XXX.XXX.XXX-XX], com contato através
do e-mail **privacidade@vocabkids.app** (ou, enquanto esse domínio não
existir, [mateuaraujo01@gmail.com] — **confirme o e-mail definitivo antes de
publicar**).

Somos os controladores dos dados pessoais tratados no aplicativo VocabKids,
nos termos da Lei Geral de Proteção de Dados (Lei nº 13.709/2018 — LGPD).

## 2. Por que isto importa mais aqui do que em outros apps

O VocabKids é usado por **crianças de 7 a 12 anos**, e duas leis brasileiras
tratam isso como categoria especialmente protegida:

- **LGPD, art. 14** — dado de criança exige consentimento **específico e em
  destaque** dado por um responsável legal (§1º); não basta o aceite
  genérico dos Termos de Uso. Como isso funciona na prática no app está
  descrito na Seção 5. Os demais parágrafos do art. 14 moldam outras partes
  desta política: §2º (publicar o que é coletado e como exercer direitos —
  Seções 4 e 8), §4º (não exigir mais dado do que o necessário pra
  participar — Seção 4, minimização), §5º (esforço razoável pra verificar
  que quem consentiu é mesmo um adulto responsável — Seção 5.1) e §6º
  (linguagem simples e acessível, inclusive pra criança entender — é por
  isso que a criança nunca vê texto jurídico dentro do jogo, só o
  responsável).
- **ECA Digital (Lei nº 15.211/2025)**, em vigor desde 17/03/2026 —
  lei mais nova, específica pra plataformas digitais com crianças
  (chamada informalmente de "Lei Felca"). Detalhe de como o VocabKids se
  posiciona frente a ela está em `docs/legal/eca_digital.md`; o resumo é
  que boa parte dos princípios que ela exige (segurança desde o design,
  supervisão parental gratuita) já estavam no desenho original do produto —
  exceto o canal formal de reporte de risco grave às autoridades, que a lei
  também pede e que o VocabKids **não tem**, por decisão do dono (ver
  `docs/legal/eca_digital.md` e `docs/legal/plano_resposta_incidente.md`
  §8).

## 3. Quem usa o quê

O VocabKids tem dois tipos de usuário, com dados e telas diferentes:

- **O responsável** (adulto): cria a conta, cadastra os perfis das crianças,
  consente com o tratamento de dados, contrata a assinatura e acessa a Área
  do Responsável.
- **A criança** (perfil): joga a trilha de vocabulário e escreve redações.
  **Nunca tem senha própria** — entra escolhendo o próprio perfil dentro da
  conta do responsável, já autenticado. A criança não consente com nada
  diretamente; quem consente é o responsável, por ela.

## 4. Quais dados coletamos (e por quê) — minimização, art. 6º III

Só coletamos o que o produto precisa pra funcionar. Nada de nome completo,
CPF, endereço, foto ou telefone da criança.

### 4.1 Do responsável (conta)

| Dado | Por quê |
|---|---|
| Nome | Identificação da conta, comunicação |
| E-mail | Login, comunicação (recuperação de senha, avisos importantes) |
| Senha (armazenada como hash, nunca em texto puro) | Autenticação |
| PIN de 4 dígitos (armazenado como hash) | Portão da Área do Responsável — protege o acesso ao resumo dos filhos e às configurações de conta contra a própria criança |
| Data e versão do consentimento LGPD | Comprovar quando e a qual versão do termo você consentiu (art. 14 §1) |

### 4.2 Da criança (perfil, dentro da conta do responsável)

| Dado | Por quê |
|---|---|
| Apelido | Identificação dentro do app — **nunca pedimos o nome completo da criança** |
| Ano de nascimento (não a data completa) | Calcula a faixa etária (7–8, 9–10 ou 11–12), que ajusta a dificuldade e a meta semanal — guardamos só o ano, dado mais granular seria desnecessário |
| Progresso no jogo (XP, nível, palavras aprendidas, posição na trilha) | O próprio funcionamento do produto |
| Textos de redação enviados | Ver Seção 6 — tratamento especial |

### 4.3 Técnicos, dos dois

| Dado | Por quê |
|---|---|
| Eventos de uso (ex.: sessão iniciada, resposta dada) — tabela interna, sem SDK de terceiros | Métricas de produto, sem rastreamento de terceiros (ver Seção 10) |
| Status da assinatura (ativa, em teste, cancelada, etc.) | Controlar o acesso ao conteúdo pago |

**O que definitivamente não coletamos:** localização geográfica, contatos do
celular, fotos da galeria (a foto de redação, quando existir, é processada
*no aparelho* e não sobe pro nosso servidor — ver Seção 6.3), nem qualquer
identificador publicitário.

## 5. Consentimento parental — como funciona de verdade

Na própria tela de criação da conta, além do aceite genérico dos Termos de
Uso, existe uma caixa de marcação separada e visualmente destacada
especificamente para o consentimento de dados da criança — não uma
caixinha escondida no rodapé dos Termos. Ela explica, em linguagem direta,
o que será coletado sobre a(s) criança(s) que você cadastrar e para quê.
Sem essa marcação (além do aceite dos termos), a conta simplesmente não é
criada — e sem conta não há como cadastrar nenhum perfil.

Guardamos a **data** e a **versão exata do termo aceito**, desde o momento
do cadastro. Se o termo mudar de forma relevante, pedimos o consentimento
de novo — sua aceitação antiga não vale automaticamente pra uma versão
nova. Texto completo e detalhes de implementação em
`docs/legal/termo_consentimento_parental.md`.

Você pode retirar o consentimento a qualquer momento excluindo a conta
(Seção 8), o que apaga os perfis das crianças junto.

### 5.1 Como verificamos que quem consente é um adulto responsável

A LGPD (art. 14 §5º) exige que o controlador faça "esforços razoáveis"
para verificar que o consentimento veio de fato de um adulto responsável,
"consideradas as tecnologias disponíveis" — não existe um padrão único
exigido, o texto da lei reconhece que o esforço proporcional muda com o
risco e o porte da operação.

No estágio atual do VocabKids, o esforço razoável é: (1) a conta é criada
com e-mail e senha, barreira que uma criança sem acesso a e-mail próprio já
não passa; (2) a tela de consentimento parental pede uma declaração
explícita de que quem está aceitando é maior de idade e responsável legal
pela criança (`termo_consentimento_parental.md`); (3) qualquer compra exige
o método de pagamento cadastrado na conta Apple do aparelho, que por si só
tende a pertencer a um adulto. Isto **não é verificação de identidade
robusta** (nenhum app de uso familiar comum tem isso) — é o padrão
proporcional ao risco desta operação, revisitável se o produto crescer a
ponto de justificar uma verificação mais forte (ex.: confirmação por
documento).

## 6. Redação: o dado mais sensível do produto

A funcionalidade de redação merece uma seção própria porque é onde a criança
mais se expressa livremente — e por isso é tratada com mais cuidado que
qualquer outro dado do app.

### 6.1 Triagem de segurança antes de qualquer outra coisa

Todo texto enviado passa primeiro por uma triagem automática de risco: sinais
de violência doméstica, abuso, autolesão ou outro risco à criança. Se algo
for identificado — mesmo que de forma sutil —, o texto **não** é analisado
ou comentado normalmente: ele fica em revisão humana, e o app mostra à
criança só uma mensagem neutra, sem qualquer indicação de que algo foi
sinalizado. O objetivo é favorecer o falso positivo (uma revisão manual a
mais) sobre o falso negativo (um sinal de risco real que passa batido).

Um sinal confirmado fica registrado internamente para revisão humana — o
VocabKids **não** aciona um canal formal de denúncia às autoridades
(Conselho Tutelar/Disque 100/SaferNet) de forma automatizada ou
processual. Essa é uma limitação conhecida da operação atual, não um
recurso do produto — ver `docs/legal/eca_digital.md` e
`docs/legal/plano_resposta_incidente.md` §8.

### 6.2 Como o texto viaja até a inteligência artificial

O texto da redação é enviado a um provedor externo de inteligência
artificial (hoje, a **OpenAI** — ver Seção 7) para a triagem de risco e a
análise pedagógica. Esse envio é **pseudonimizado**: vai só o texto, a faixa
etária e o tema da redação — **nunca o nome, apelido, e-mail ou qualquer
identificador da criança ou da conta**. A OpenAI não tem como ligar aquele
texto a uma pessoa específica.

### 6.3 Redação por foto (recurso ainda desativado)

O app tem previsto (mas **ainda não ativo**) o envio de redação por foto,
manuscrita. Quando isso for ativado, o reconhecimento de texto (OCR)
acontece **no próprio aparelho** — a foto em si nunca sobe para o nosso
servidor, só o texto já extraído.

### 6.4 Quanto tempo guardamos

O texto da redação e a análise ficam guardados por **24 meses**, tempo
suficiente para o responsável acompanhar a evolução ao longo dos anos
letivos. Depois disso, são apagados automaticamente.

### 6.5 O que o responsável vê, o que a criança vê

A criança nunca vê nota numérica — só comentários construtivos, sempre em
tom de "oportunidade de aprender uma palavra melhor", nunca de erro. Um nível
de desempenho por dimensão da redação (numa escala de 4 níveis nomeados,
nunca numérica) fica disponível **só para o responsável**, na Área do
Responsável, protegida por PIN.

## 7. Com quem compartilhamos dados (suboperadores)

Não vendemos dado de ninguém. Compartilhamos o mínimo necessário com
prestadores de serviço que processam dados em nosso nome:

| Empresa | Papel | O que recebe |
|---|---|---|
| **Apple** | Loja de aplicativos, processamento de pagamento (via App Store) e autenticação opcional (Sign in with Apple) | Dados de compra (a Apple, não nós, vê seu cartão); identificador de compra |
| **OpenAI** | Análise de redação (triagem de risco + comentário pedagógico) | Texto da redação, faixa etária, tema — pseudonimizado (Seção 6.2) |
| **Neon** | Hospedagem do banco de dados (Postgres) | Todos os dados armazenados pelo app, como infraestrutura, não como uso próprio |
| **RevenueCat** | Intermediário de assinatura — resolve a compra feita na Apple/Google e nos avisa do status | Identificador de compra, status da assinatura — não o cartão |
| **[Provedor de push — a definir]** | Notificações do app | [A definir quando o provedor for escolhido] |

Nenhum desses provedores está autorizado a usar os dados da sua família pra
qualquer finalidade própria (como treinar modelos de IA com o texto da sua
redação, no caso da OpenAI) sem opt-in explícito nosso — ver
`docs/legal/opt_out_llm.md` para o detalhe de como isso é garantido com a
OpenAI especificamente.

## 8. Seus direitos (art. 18 da LGPD)

Como responsável pela conta, você pode a qualquer momento:

- **Acessar** todos os dados que temos sobre você e seus filhos.
- **Corrigir** dados incorretos (apelido, ano de nascimento, e-mail).
- **Exportar** seus dados em formato legível (JSON), a pedido, por e-mail.
- **Excluir a conta** inteira, direto pelo app (Área do Responsável →
  Excluir conta) — sem precisar ligar pra ninguém ou mandar carta. A exclusão
  remove a conta e os perfis das crianças em até **30 dias**.
- **Retirar o consentimento** — que, na prática, significa excluir a conta,
  já que sem consentimento não podemos manter os perfis das crianças.

Pra qualquer solicitação relacionada a dados que o app não resolva sozinho,
escreva pro encarregado de dados (Seção 11).

## 9. Loja de aplicativos e classificação etária

O app está listado na categoria **Educação, classificação etária 4+, com
portão parental** — não na *Kids Category* da Apple. Razão registrada em
`docs/produto/plano_b2c.md` §11.2 (Decisão D9): a Kids Category exige que o
público seja declarado dentro de faixas fechadas (5 anos ou menos, 6–8,
9–11), que não cobrem os 7–12 anos do VocabKids por inteiro (perderia a
faixa de 12 anos); e proíbe qualquer transmissão de dado a terceiro mesmo
pseudonimizado — o que entraria em conflito direto com o envio do texto de
redação à OpenAI (Seção 6.2), ainda que sem identificador algum. Fora da
Kids Category, adotamos as mesmas práticas na prática (Seção 10) por
escolha, não por exigência formal da categoria.

Qualquer compra (assinatura) só pode ser feita pelo responsável, nunca pela
criança durante o jogo — o fluxo de compra fica isolado na Área do
Responsável, atrás do portão de PIN, o que a Apple chama de "parental gate"
(exigido tanto na Kids Category quanto, por boa prática e pela Guideline
5.1.4, fora dela quando o público é majoritariamente infantil).

## 10. Sem rastreamento de terceiros

O VocabKids **não usa** SDK de analytics ou publicidade de terceiros (nada
de Firebase Analytics, Meta SDK, ou qualquer rede de anúncios). Toda métrica
de uso do produto é registrada nos nossos próprios servidores, sem sair pra
nenhuma empresa de rastreamento — inclusive porque isso simplifica bastante
a conformidade com apps voltados a crianças.

## 11. Encarregado de Dados (DPO) — art. 41

**[Nome do responsável]**, contato: **[e-mail de contato do DPO — mateuaraujo01@gmail.com,
confirmar antes de publicar]**.

Nota técnica: pela Resolução CD/ANPD nº 2/2022, agentes de tratamento
operados como **pessoa física** (como o VocabKids hoje) são dispensados da
obrigatoriedade formal do art. 41 — ou seja, nomear um encarregado não é uma
exigência legal neste estágio. Mantemos essa figura mesmo assim, por
transparência com as famílias que usam o app: ter um contato claro pra
dúvida sobre dado da criança é mais importante que o mínimo exigido por lei.
Isso deve ser revisto (e aí sim se tornar obrigatório) à medida que a
operação crescer — abertura de CNPJ com faturamento acima do teto de
pequeno porte, por exemplo.

## 12. Alterações nesta política

Alterações relevantes desta política — em especial qualquer mudança que
afete o tratamento de dados de crianças — disparam um novo pedido de
consentimento (Seção 5), não só um aviso passivo.

---

*Última atualização: 26/08/2026. Documento em rascunho — ver aviso no topo.*
