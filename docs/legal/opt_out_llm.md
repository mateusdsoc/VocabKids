# Opt-out de treinamento — provedor de LLM (OpenAI)

> Pesquisado em 26/08/2026 contra a política pública da OpenAI
> ([openai.com/business-data](https://openai.com/business-data/),
> [anúncio de Zero Data Retention](https://openai.com/index/offering-zero-data-retention-for-frontier-models/)
> — ver `fontes_pesquisa.md`). Políticas de provedor de IA mudam com
> frequência — **revisitar a cada 6 meses** ou quando a OpenAI anunciar
> mudança relevante nos termos. Requisito do plano:
> `docs/produto/plano_b2c.md` R-RD-8/R-RD-9 (§14).

## O que já está garantido, sem ação adicional (achado da pesquisa)

O **tráfego de API da OpenAI (o que o VocabKids usa, via `AsyncOpenAI` em
`backend/app/redacao/analisador.py`) já não é usado para treinar modelos por
padrão** — essa é uma política de longa data da OpenAI, distinta do produto
de consumo ChatGPT (onde, em contas gratuitas/Plus, o conteúdo pode ser
usado pra treino a menos que o usuário final desative isso manualmente). Uma
conta de API padrão, como a que o VocabKids usa, já nasce fora desse regime
de treino — **não é preciso pedir nada especial pra essa garantia valer**.

O que a OpenAI retém, por padrão, é o conteúdo da chamada de API por um
período curto (comumente citado como até 30 dias) só para fins de detecção
de abuso — não para treino, não para revisão humana rotineira.

## O que exige ação (e a realidade de escala pra uma operação pequena)

- **Zero Data Retention (ZDR)**: elimina até essa retenção de 30 dias.
  Achado da pesquisa: hoje isso passa por canal de vendas empresarial da
  OpenAI ("contact your OpenAI account team") — não é um botão de
  autoatendimento no painel comum. **Realisticamente, não está acessível a
  uma operação solo/pré-receita como o VocabKids hoje.** Ação: registrar o
  interesse futuro, revisitar quando o volume de uso justificar contato
  comercial com a OpenAI.
- **Data Processing Addendum (DPA)**: documento contratual que formaliza as
  garantias de tratamento de dado (relevante como evidência de conformidade
  com o art. 39 da LGPD — tratamento por operador). Normalmente vinculado a
  contas Business/Enterprise da OpenAI. Ação: ao criar a conta/organização
  na OpenAI, verificar nas configurações da organização (`platform.openai.com`,
  seção de configurações de dados/organização) se um DPA está disponível
  para aceite mesmo em conta padrão — isso mudou nos últimos anos e vale
  conferir diretamente, não assumir que não está disponível.

## Postura de conformidade adotada (padrão de "esforços razoáveis")

A LGPD não exige perfeição, exige **esforço razoável proporcional ao
risco e ao porte da operação** (é o mesmo princípio do art. 14 §5º sobre
verificação de consentimento, aplicado aqui por analogia ao operador). Dado
isso, a postura do VocabKids é:

1. Usar a **API** da OpenAI (não o produto de consumo ChatGPT) — que já
   exclui o texto de treino por padrão, sem ação adicional.
2. Nunca enviar identificador da criança junto ao texto (pseudonimização,
   já implementado em `analisador.py` — a OpenAI recebe texto + faixa etária
   + tema, nunca nome/e-mail/apelido).
3. Verificar, na criação da conta OpenAI, se há DPA disponível para aceite
   mesmo em conta padrão (ação de 10 minutos, sem custo) — fazer isso antes
   do lançamento.
4. Registrar aqui a data em que essa verificação foi feita e o resultado,
   uma vez feita.
5. Reavaliar ZDR quando a operação tiver receita/volume que justifique
   contato comercial com a OpenAI.

## Checklist de ação (antes do lançamento)

- [ ] Confirmar, no painel real da conta OpenAI (`platform.openai.com` →
      Settings → Data controls, ou nome equivalente na versão vigente da
      interface), que a opção de usar dado para melhorar o modelo está
      desligada — mesmo sendo o padrão pra tráfego de API, confirmar
      visualmente e registrar a data aqui.
- [ ] Verificar se um DPA está disponível para aceite direto no painel,
      mesmo em conta não-Enterprise.
- [ ] Atualizar este documento com o resultado real da verificação (data +
      o que foi encontrado) — a seção acima é o entendimento a partir de
      política pública, não uma confirmação de que *esta* conta específica
      já foi checada.
- [ ] Atualizar `politica_privacidade.md` Seção 7 e `ropa.md` linha 8 se o
      resultado da verificação mudar o que está descrito lá.

## Por que isto não pode ser 100% resolvido só com pesquisa

Confirmar a configuração real de uma conta específica exige acessar o painel
daquela conta — algo que só quem tem a credencial consegue fazer. A pesquisa
acima elimina a maior incerteza (se o treino com dado de API é opt-in ou
opt-out — é opt-out, ou seja, já vem desligado), mas o checklist final
depende de uma ação de 10 minutos sua.

---

*Última atualização: 26/08/2026.*
