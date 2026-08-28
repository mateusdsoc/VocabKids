# Plano de Resposta a Incidente de Segurança — VocabKids

> ⚠️ Documento interno (LGPD art. 48 + Resolução CD/ANPD nº 15/2024, que
> regulamenta o prazo e o formato da comunicação de incidente). Sem revisão
> de advogado — decisão do dono. Dado o público (crianças), o padrão
> adotado é o prazo mais curto que a lei permite pro nosso porte, não o
> prazo dobrado a que teríamos direito (ver §4) — tratamos isso como piso
> de segurança pra criança, não teto de conforto pra nós.

## 1. O que conta como incidente

Qualquer evento que comprometa a confidencialidade, integridade ou
disponibilidade de dado pessoal tratado pelo VocabKids. Exemplos concretos
pro nosso caso:

- Vazamento do banco de dados (Neon) — exposição de e-mails, senhas
  (mesmo em hash), textos de redação, apelidos/ano de nascimento de crianças.
- Comprometimento da conta de algum responsável (ex.: credencial vazada em
  outro serviço reutilizada aqui) — mesmo que não seja falha nossa, exige
  resposta.
- Falha na pseudonimização do envio à OpenAI (Política de Privacidade, Seção
  6.2) — se algum identificador vazar junto ao texto por bug, é incidente
  mesmo sem vazamento externo, porque quebra uma garantia específica dada ao
  responsável.
- Acesso indevido de um perfil de criança aos dados de outro (falha de
  isolamento entre contas).
- Vazamento de credenciais de infraestrutura (chave de API da OpenAI, do
  RevenueCat, segredo do JWT) que permita acesso não autorizado a dados.

## 2. Papéis (equipe pequena — hoje é uma pessoa só)

| Papel | Responsável hoje |
|---|---|
| Detecção e triagem inicial | [Fundador — mesma pessoa que é o DPO] |
| Decisão de notificar ANPD/titulares | [Fundador, idealmente com apoio jurídico antes de notificar] |
| Comunicação com os titulares | [Fundador] |
| Correção técnica | [Fundador / quem estiver desenvolvendo no momento] |

Nota: **concentrar tudo numa pessoa é um risco reconhecido**, não uma
recomendação — revisar essa tabela à medida que o time crescer.

## 3. Passo a passo ao identificar um incidente

1. **Conter** — isolar a causa imediata (revogar credencial vazada, tirar
   endpoint vulnerável do ar, reverter deploy problemático). Prioridade
   sobre investigação completa: parar o vazamento primeiro.
2. **Avaliar o escopo** — quais tabelas/usuários foram afetados, desde
   quando, se dado de criança está entre os afetados (isso muda a gravidade
   e o prazo de resposta — dado de criança pede resposta mais rápida, não
   igual à de dado de adulto).
3. **Documentar** — data de início (estimada), data de detecção, causa raiz,
   dados afetados, número de titulares. Isso vira a base da comunicação à
   ANPD, se necessária.
4. **Avaliar necessidade de notificação à ANPD (art. 48).** Fatores que
   pesam a favor de notificar: dado de criança envolvido, dado sensível
   envolvido (textos de redação podem revelar informação sensível — ver
   R-RD-7), risco concreto aos titulares. Na dúvida, notificar — o custo de
   uma notificação desnecessária é muito menor que o de omitir uma
   necessária, ainda mais tratando de dado de criança.
5. **Notificar os titulares afetados** — em linguagem simples, o que
   aconteceu, quais dados, o que já foi feito, o que o responsável deveria
   fazer (ex.: trocar senha). **Nunca minimizar o fato de envolver dado de
   criança.**
6. **Corrigir a causa raiz** — não só o sintoma. Registrar a correção como
   um incidente fechado, com data.
7. **Post-mortem interno** — o que falhou, o que teria detectado mais cedo,
   o que muda no processo. Vira insumo pra atualizar este documento e o ROPA.

## 4. Prazos-alvo (Resolução CD/ANPD nº 15/2024)

Diferente do que uma versão anterior deste documento dizia, a LGPD **não**
deixa isso em aberto — a ANPD regulamentou um prazo exato pela Resolução
CD/ANPD nº 15, de 24/04/2024:

- **3 dias úteis**, contados do momento em que o controlador toma
  conhecimento de que o incidente afetou dado pessoal, pra comunicar tanto
  a ANPD quanto os titulares afetados. "Dia útil" exclui sábado, domingo e
  feriado nacional.
- **Esse prazo é dobrado (6 dias úteis) para agente de tratamento de
  pequeno porte** (Resolução CD/ANPD nº 2/2022) — e o VocabKids se
  qualifica automaticamente como pequeno porte enquanto for operado como
  **pessoa física** (a resolução inclui "pessoas naturais" na definição,
  sem depender de faturamento). **Decisão adotada aqui: tratar 3 dias úteis
  como o alvo real, não os 6 a que teríamos direito** — dado o público
  infantil, vale manter o padrão mais rigoroso por disciplina, mesmo sem
  ser estritamente obrigatório.
- Informações podem ser complementadas depois, em até 20 dias úteis da
  comunicação inicial — ou seja, não é preciso ter a investigação 100%
  fechada pra fazer a comunicação inicial dentro do prazo.

Prazos internos que precedem a notificação (não vêm da resolução, são
disciplina própria):

- Contenção: assim que detectado, sem esperar avaliação completa do escopo.
- Avaliação inicial de escopo: até 24h da detecção — pra dar tempo de
  decidir a notificação dentro da janela de 3 dias úteis acima.

## 5. Onde isto se conecta ao código

- Chaves e segredos vivem em variáveis de ambiente (`JWT_SECRET`,
  `REVENUECAT_WEBHOOK_SECRET`, `OPENAI_API_KEY`) — nunca commitados. Se um
  desses vazar (ex.: commit acidental, log exposto), é incidente de dia 1
  deste plano: revogar/regerar a chave é o primeiro passo de contenção.
- Rate limiting (`app/seguranca/rate_limit.py`) e o `require_papel` de auth
  são as principais defesas contra acesso indevido entre contas — um bug
  ali é candidato natural a virar item 4 da lista de exemplos (§1).
- Logs do backend não devem conter texto de redação nem senha/PIN em claro —
  **auditar isso explicitamente** antes do lançamento (verificar
  `app/main.py` e qualquer middleware de log).

## 6. Texto-modelo de comunicação ao titular

Rascunho de e-mail a adaptar pro incidente real (nunca copiar sem revisar os
detalhes concretos do caso):

> **Assunto: Aviso importante de segurança — sua conta VocabKids**
>
> Olá, [nome do responsável],
>
> Em [data], identificamos [descrição factual e direta do que aconteceu —
> ex.: "um acesso não autorizado a parte do nosso banco de dados"]. Isso
> pode ter afetado os seguintes dados da sua conta e/ou do perfil de
> [apelido da criança, se aplicável]: [lista exata dos dados afetados —
> nunca minimizar se dado de criança estiver na lista].
>
> O que já fizemos: [ação de contenção tomada, ex.: "revogamos as
> credenciais afetadas e corrigimos a falha que permitiu o acesso"].
>
> O que recomendamos que você faça: [ação concreta, ex.: "troque sua senha
> do VocabKids e de qualquer outro serviço onde use a mesma senha"].
>
> Se tiver dúvidas, responda este e-mail ou escreva para
> [e-mail do DPO/contato de privacidade].
>
> [Nome do responsável pelo VocabKids]

## 7. Pendências deste documento

- Auditoria de logs (§5, último item) ainda não foi feita.

## 8. Fora de escopo, por decisão do dono (27/08)

O canal formal de reporte às autoridades (Conselho Tutelar / Disque 100 /
SaferNet) que o ECA Digital pede pra sinal de risco grave na redação **não
vai ser construído nem documentado como processo** — decisão explícita: a
operação (uma pessoa) não tem capacidade de manter isso. Isso não faz a
exigência da lei desaparecer, só significa que o risco é aceito
conscientemente, não resolvido: se `redacao.risco_sinalizado = true`
acontecer de verdade, alguém vai ter que decidir na hora, sem processo
escrito, o que fazer. Ver `docs/legal/eca_digital.md` pra esse item ficar
marcado como gap conhecido, não como "endereçado".

---

*Última atualização: 27/08/2026.*
