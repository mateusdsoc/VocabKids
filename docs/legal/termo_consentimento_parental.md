# Termo de Consentimento Parental — VocabKids

> ⚠️ Este é o documento mais sensível dos três (Política de Privacidade,
> Termos de Uso, este) — a redação abaixo foi desenhada especificamente pra
> atender o padrão do art. 14 §1 da LGPD ("consentimento específico e em
> destaque"): caixa de marcação própria, visualmente destacada (cartão com
> borda própria) e separada do aceite genérico dos Termos de Uso, nunca
> pré-marcada, mais uma declaração explícita de maioridade/vínculo legal
> (item 1 da declaração abaixo) que endereça o art. 14 §5º (esforço razoável
> de verificação). Sem revisão de advogado — decisão do dono, ver
> `docs/legal/fontes_pesquisa.md`.
>
> **Implementado (27/08)** em
> [app/lib/features/identidade/cadastro_screen.dart](../../app/lib/features/identidade/cadastro_screen.dart)
> (as duas caixas de marcação) e
> [app/lib/features/identidade/legal_texts.dart](../../app/lib/features/identidade/legal_texts.dart)
> (o texto condensado exibido, `consentimentoLgpdTexto` — versão mobile do
> texto abaixo). O gate no backend já existia desde a Fase 1
> (`_exigir_consentimento` em `backend/app/identidade/routes.py`, testado em
> `tests/test_identidade.py::test_cadastro_exige_consentimento_lgpd`) — o que
> faltava era só a UI mostrar o texto de verdade e enviar o valor real de
> cada caixa, em vez de um `true` fixo. Versão do consentimento:
> `CONSENTIMENTO_VERSAO_ATUAL = "1.0"` em `backend/app/identidade/schemas.py`
> — é o valor gravado em `conta.consentimento_versao` no cadastro. Se este
> texto mudar de forma relevante, essa constante sobe junto (ela já existe
> pra isso, não é nova).
>
> **Onde isso acontece de fato, e por que o texto abaixo é genérico, não por
> criança:** o consentimento é pedido **na tela de cadastro da conta**
> (`POST /v1/conta`), **antes de qualquer perfil de criança existir** — a
> arquitetura do produto (uma conta pode ter até 3 perfis, cadastrados depois,
> um a um) não permite nomear uma criança específica neste momento. Por isso
> o texto fala em "a(s) criança(s) que você vai cadastrar nesta conta", não
> num apelido específico — diferente de uma primeira versão deste documento,
> que assumia (incorretamente) uma tela de consentimento por criança
> gatilhada em `POST /v1/conta/perfis`. Ver "Decisões que ficaram de fora"
> abaixo pra essa alternativa considerada e descartada.

---

## Antes de criar sua conta

Para criar uma conta no VocabKids e cadastrar perfis de criança nela,
precisamos do seu consentimento específico — não é a mesma coisa que aceitar
os Termos de Uso gerais. A Lei Geral de Proteção de Dados (LGPD, art. 14)
trata dado de criança como categoria especialmente protegida, e por isso
queremos deixar bem claro, antes de qualquer coisa, o que vamos coletar e
por quê.

### O que vamos coletar sobre a(s) criança(s) que você cadastrar

- **Um apelido** — nunca pedimos o nome completo.
- **O ano de nascimento** (não a data completa) — usamos isso só para
  calibrar a dificuldade do conteúdo pela idade certa.
- **O progresso no jogo**: pontos, nível, palavras aprendidas, posição na
  trilha.
- **Os textos das redações**, se você ativar essa funcionalidade — eles são
  analisados por uma inteligência artificial externa (hoje, a OpenAI) de
  forma anônima: só o texto e a faixa etária vão junto, nunca o nome ou
  qualquer identificação. Detalhe completo na
  [Política de Privacidade](politica_privacidade.md), Seção 6.

### O que NÃO fazemos

- Não vendemos nem compartilhamos dado da criança com empresas de
  publicidade.
- Não usamos SDKs de rastreamento de terceiros dentro do app.
- A criança nunca vê anúncios.
- A criança nunca consegue comprar nada dentro do app — qualquer assinatura
  só pode ser contratada por você, fora do fluxo de jogo.

### Seus direitos como responsável

Você pode, a qualquer momento:
- Ver todos os dados que temos sobre a criança.
- Corrigir o apelido ou o ano de nascimento.
- **Excluir o perfil ou a conta inteira**, diretamente no app — isso apaga
  os dados da criança em até 30 dias.
- Retirar este consentimento (o que, na prática, significa excluir a conta,
  já que sem consentimento não podemos manter nenhum perfil ativo).

Detalhes completos estão na [Política de Privacidade](politica_privacidade.md)
e nos [Termos de Uso](termos_de_uso.md).

---

### Declaração de consentimento

Ao marcar a caixa abaixo, eu declaro que:

1. Sou **maior de idade** e **responsável legal** pela(s) criança(s) que vou
   cadastrar nesta conta;
2. Li e entendi o que será coletado sobre ela(s) e para quê, conforme
   descrito acima;
3. **Consinto especificamente** com o tratamento desses dados, nos termos do
   art. 14 da Lei Geral de Proteção de Dados (Lei nº 13.709/2018);
4. Entendo que posso retirar este consentimento a qualquer momento, excluindo
   a conta.

`[  ] Sou responsável legal e autorizo o tratamento dos dados da(s) criança(s) que vou cadastrar, conforme a LGPD (art. 14).`

*(Esta caixa de marcação é própria e distinta do aceite dos Termos de Uso
gerais — não pode ser a mesma caixa nem estar pré-marcada. O botão "Criar
conta" só segue com as duas marcadas — ver `cadastro_screen.dart`.)*

---

## Decisões que ficaram de fora

**Consentimento por criança específica, no momento de `POST /v1/conta/perfis`:**
considerado e descartado nesta rodada. Seria mais "específico" no sentido
literal do art. 14 §1 (nomear a criança pelo apelido no texto de consentimento),
mas exigiria um segundo gate no backend + schema novo (a consentimento hoje
vive em `conta`, não em `perfil_crianca`) e duplicaria a fricção pra quem
cadastra mais de um filho. Avaliação: o consentimento único na conta,
cobrindo "a(s) criança(s) que você cadastrar", já é mais destacado e
específico que a média do mercado (é uma caixa própria, com texto completo,
não embutida no aceite geral) — evolução futura, não bloqueador do MVP.

## Notas de implementação

- **Registro:** já acontece — `criar_conta_responsavel` em
  `backend/app/identidade/repository.py` grava `consentimento_lgpd_em =
  func.now()` e `consentimento_versao = CONSENTIMENTO_VERSAO_ATUAL` na mesma
  transação que cria a conta.
- **Revalidação:** se este texto mudar de forma relevante (não erro de
  digitação), suba `CONSENTIMENTO_VERSAO_ATUAL` em
  `backend/app/identidade/schemas.py` **e** o texto correspondente em
  `app/lib/features/identidade/legal_texts.dart` no mesmo PR — hoje isso é
  sincronizado manualmente, sem teste automático que os compare. Contas
  existentes continuam funcionando (o consentimento antigo vale pros dados
  já coletados sob ele); não há hoje um mecanismo de "pedir de novo" pra
  conta já existente quando a versão sobe — **pendência**, não implementado.
