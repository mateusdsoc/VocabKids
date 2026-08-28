# Registro de Operações de Tratamento de Dados (ROPA) — VocabKids

> ⚠️ Documento interno (art. 37 da LGPD — a ANPD pode solicitá-lo, mas ele
> não é publicado). Gerado a partir do schema real (`backend/app/schema.py`)
> em 26/08/2026; atualizar sempre que uma tabela/fluxo novo tratar dado
> pessoal. **Nota sobre a coluna de base legal**: pelo Enunciado CD/ANPD nº
> 1/2023, o tratamento de dado de criança pode se apoiar em qualquer base do
> art. 7º/11 da LGPD (não só consentimento), desde que o melhor interesse da
> criança prevaleça caso a caso (art. 14, caput). Este ROPA usa
> **consentimento do responsável** como base declarada pra praticamente tudo
> que envolve a criança — não porque seja a única opção legalmente válida,
> mas porque (a) o produto já tem um gate de consentimento explícito por
> desenho (Termo de Consentimento Parental), tornando o consentimento a base
> mais simples de documentar e mais fácil do titular entender/revogar, e (b)
> é o padrão mais protetivo, o que favorece o "melhor interesse da criança"
> exigido pelo caput do art. 14 em caso de dúvida. Ver `fontes_pesquisa.md`.
>
> **Nota sobre o formato**: a Resolução CD/ANPD nº 2/2022 permite registro
> "simplificado" pra agente de tratamento de pequeno porte (o VocabKids se
> qualifica como pessoa física, sem depender de faturamento). Este documento
> já é mais simples que um ROPA de empresa grande — uma tabela por operação,
> sem processo de aprovação formal — o que é compatível com esse regime.

## Como manter isto atualizado

Regra prática: **toda vez que uma migration adicionar uma tabela ou coluna
que guarde dado pessoal** (não config, não conteúdo pedagógico genérico),
adicionar uma linha aqui no mesmo PR — mesma lógica da "regra das decisões
revisadas" do `CLAUDE.md`, aplicada a dado pessoal.

## 1. Inventário de tratamento

| # | Operação | Dados tratados | Titular | Finalidade | Base legal (LGPD) | Retenção | Onde vive no schema |
|---|---|---|---|---|---|---|---|
| 1 | Cadastro de conta do responsável | Nome, e-mail, senha (hash) | Responsável (adulto) | Autenticação, gestão da conta | Execução de contrato (art. 7º V) | Até exclusão da conta + 30 dias | `usuario`, `conta` |
| 2 | Consentimento parental | Data e versão do consentimento aceito | Responsável | Comprovar consentimento específico (art. 14 §1) | Cumprimento de obrigação legal (art. 7º II) | Enquanto a conta existir + prazo de guarda legal aplicável | `conta.consentimento_lgpd_em`, `conta.consentimento_versao` |
| 3 | Cadastro de perfil de criança | Apelido, ano de nascimento | Criança (via consentimento do responsável) | Personalizar dificuldade/meta por faixa etária | Consentimento do responsável (art. 14 §1) | Até exclusão do perfil/conta | `perfil_crianca` |
| 4 | Portão da Área do Responsável | PIN (hash) | Responsável | Impedir que a criança acesse configurações/resumo do responsável | Legítimo interesse — segurança do próprio produto (art. 7º IX) | Enquanto a conta existir | `conta.pin_hash` |
| 5 | Progresso de jogo | XP, nível, palavras aprendidas, respostas dadas, colecionáveis | Criança | Funcionamento central do produto | Consentimento do responsável (art. 14 §1) | Enquanto a conta existir | `sessao`, `aluno_progresso`, `aluno_palavra`, `aluno_questao`, `aluno_colecionavel` |
| 6 | Envio e análise de redação | Texto da redação, faixa etária, tema | Criança | Feedback pedagógico | Consentimento do responsável (art. 14 §1) | **24 meses**, depois apagado | `redacao`, `redacao_analise` |
| 7 | Triagem de risco da redação | Sinal de risco + motivo (texto livre para adulto) | Criança | Proteção da criança (R-RD-7) | Legítimo interesse — proteção da criança + cumprimento de obrigação legal de cuidado | 24 meses, junto com a redação de origem | `redacao.risco_sinalizado`, `redacao.risco_motivo` |
| 8 | Envio de texto ao provedor de LLM (OpenAI) | Texto da redação, faixa etária, tema — **sem identificador** | Criança (pseudonimizado) | Executar a análise (a IA roda fora do nosso servidor) | Consentimento do responsável, operação em nome do controlador (art. 39 — operador) | ~30 dias na OpenAI (retenção padrão de API, só p/ monitoramento de abuso — não treino, ver `opt_out_llm.md`) | Não persiste no nosso schema; trânsito via `backend/app/redacao/analisador.py` |
| 9 | Assinatura | Status, identificador de transação, ambiente (sandbox/produção) | Responsável | Controlar acesso a conteúdo pago | Execução de contrato (art. 7º V) | Enquanto a conta existir | `assinatura` |
| 10 | Telemetria de produto (server-side, sem SDK de terceiros) | Tipo de evento, payload (sem dado sensível) | Responsável e/ou criança | Métricas de uso, melhoria do produto | Legítimo interesse (art. 7º IX) | **12 meses** (definido em `politica_retencao_exclusao.md` §2, 26/08) | `evento` |

## 2. Fluxos de compartilhamento externo (ver `suboperadores.md` para o detalhe contratual)

| Dado que sai | Vai para | Por quê | Pseudonimizado? |
|---|---|---|---|
| Texto de redação + faixa + tema | OpenAI | Análise pedagógica + triagem de risco | Sim — sem nome/e-mail/apelido |
| Identificador de compra, status | RevenueCat → Apple/Google | Resolver e validar a assinatura | Não se aplica (dado de transação, não pessoal sensível de criança) |
| Todos os dados armazenados | Neon | Hospedagem de infraestrutura (não uso próprio dos dados) | Não se aplica — Neon é operador puro de infraestrutura |

## 3. Pendências deste registro

- Nenhum dos TTLs definidos em `politica_retencao_exclusao.md` está
  implementado como job automático ainda — ver as pendências daquele
  documento (§5) pra prioridade.
- A OpenAI retém dado de API por padrão por um período curto (~30 dias) só
  pra monitoramento de abuso, não treino — ver `opt_out_llm.md` pro detalhe
  e o que ainda depende de checagem manual na conta real.
- Provedor de push ainda não escolhido — quando escolhido, adicionar linha
  (dado que sai: token de dispositivo — mínimo necessário pra entregar a
  notificação).

---

*Última atualização: 26/08/2026.*
