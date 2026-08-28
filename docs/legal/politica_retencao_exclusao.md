# Política de Retenção e Exclusão de Dados — VocabKids

> ⚠️ Escrito sem revisão de advogado (decisão do dono). Prazos de 24 meses
> (redação) e ≤30 dias (exclusão de conta) vêm de `docs/produto/plano_b2c.md`
> §11.1. Os prazos fiscais/civis abaixo usam os prazos gerais mais comuns do
> direito brasileiro (Código Tributário Nacional art. 173 — decadência de 5
> anos para o Fisco constituir crédito tributário; Código Civil art. 206 —
> prescrição de pretensões cíveis, em geral até 5 anos) como referência
> conservadora — **ajustar quando houver contador/CNPJ formal**, que pode
> indicar prazo mais específico pro regime tributário escolhido.

## 1. Regra geral

Guardamos dado pessoal só pelo tempo necessário à finalidade que justificou
a coleta (LGPD, art. 15) ou pelo prazo mínimo que a lei brasileira exigir
para determinado tipo de registro (ex.: obrigações fiscais).

## 2. Prazos por tipo de dado

| Dado | Prazo | O que acontece depois |
|---|---|---|
| Conta do responsável (nome, e-mail, senha) | Enquanto a conta estiver ativa | Apagado em até **30 dias** após pedido de exclusão |
| Perfis de criança (apelido, ano de nascimento, progresso) | Enquanto a conta estiver ativa | Apagados junto com a conta, em até 30 dias |
| Textos e análises de redação | **24 meses** a partir do envio | Apagado automaticamente, mesmo sem pedido do responsável |
| Consentimento LGPD (data + versão) | Enquanto a conta existir + **5 anos** após exclusão, retendo só o registro mínimo (data + versão + identificador não pessoal), não o restante da conta | Apagado por completo após esse prazo — o valor defensivo de provar que houve consentimento válido decai com o tempo, mas cobrir o prazo de prescrição cível geral (Código Civil art. 206) é uma margem razoável |
| Dados de assinatura/transação | **5 anos** a partir da transação (referência: prazo de decadência tributária, CTN art. 173) | Apagado após esse prazo, exceto o mínimo que a legislação tributária vigente na época exigir |
| Telemetria (`evento`) | **12 meses** a partir do evento — prazo definido nesta revisão (26/08); antes não havia TTL | Apagado automaticamente; não há necessidade de guardar métrica operacional além de um ciclo anual de análise |
| Backups do banco de dados | Ciclo de backup do provedor (Neon) — confirmar o prazo de retenção de snapshot vigente no plano contratado | Um dado "excluído" pode persistir num backup até esse prazo rodar — mencionar isso de forma resumida na Política de Privacidade se o prazo for longo (>30 dias) |

## 3. Como a exclusão de conta funciona tecnicamente

O responsável aciona a exclusão pelo próprio app (Área do Responsável →
Excluir conta — Apple Guideline 5.1.1(v): tem que ser possível de dentro do
app, sem precisar de suporte por e-mail). O backend:

1. Marca a conta para exclusão imediatamente (bloqueia login).
2. Remove os dados pessoais identificáveis em até 30 dias — via `ondelete`
   em cascata nas foreign keys relevantes (`usuario`, `conta`,
   `perfil_crianca` e tabelas dependentes, conforme `backend/app/schema.py`).
3. **Exceção:** dados que a lei exigir manter por mais tempo (ex.:
   comprovação fiscal de uma transação) ficam retidos apenas pelo mínimo
   legal, dissociados do restante da conta sempre que tecnicamente possível.

## 4. Retenção específica da redação (24 meses)

Esse prazo é mais curto que o da conta em geral porque o texto da redação é
o dado mais sensível do produto (Política de Privacidade, Seção 6). Depois
de 24 meses, o texto e a análise são apagados **mesmo que a conta continue
ativa** — o histórico de progresso de vocabulário não depende do texto bruto
da redação para continuar funcionando.

## 5. Pendências deste documento

- Confirmar o prazo real de retenção de snapshot/backup no plano contratado
  da Neon (§2, última linha).
- **Nenhum dos TTLs acima está implementado em código ainda** — hoje são
  regra documental, não enforced por job automático. Isso é aceitável por
  enquanto (ninguém tem 24 meses de uso, muito menos 5 anos), mas vira
  trabalho de backend real assim que a base de usuários justificar:
  - Job de expurgo de redação (24 meses) — o mais prioritário dos três,
    porque é o dado mais sensível.
  - Job de expurgo de telemetria (12 meses).
  - Job de expurgo de registro de consentimento pós-exclusão (5 anos) — o
    menos urgente, prazo longo.

---

*Última atualização: 26/08/2026.*
