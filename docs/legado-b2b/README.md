# Legado B2B (pré-pivô, 24/08/2026)

Estes quatro documentos descrevem o produto **antes** do pivô de B2B (venda
por escola, professor no centro) para B2C (assinatura direto pra família).
O código que eles descrevem (`app/professor/`, `features/professor/`,
`main_professor.dart`, tabelas `turma`/`escola`/`associacao_turma`/
`turma_config`/`sinal_turma`) foi **deletado do repositório na Fase 6**
(`docs/produto/plano_b2c.md` §09, 25/08/2026) — `git log` tem o código se
essa frente reabrir um dia.

**Não são a fonte da verdade do produto hoje.** Isso é `docs/produto/plano_b2c.md`.
Nenhum destes quatro arquivos foi reescrito por inteiro pro B2C — o custo de
reescrever ~2000 linhas de prosa B2B não se pagava frente a ter o plano B2C
como spec paralela e completa (decisão registrada em
`design/notas-implementacao.md` § "Fase 6").

**O que ainda vale, filtrado por bom senso:**

| Documento | O que ainda é válido | O que não é (ver plano B2C) |
|---|---|---|
| `rascunho_product.md` | Mecânica de vocabulário/XP/combo/trilha/diagnóstico (seções 3.1–3.10, 3.8) | Público, monetização, papéis/permissões (3.11), tudo sobre professor/escola/turma |
| `arquitetura.md` | Princípios gerais (cliente fino/servidor autoritativo), pipeline de redação (Bloco 2b, exceto OCR) | Bloco 1 (identidade por turma), stack de OCR (Google Vision + R2 — o B2C usa ML Kit on-device), domínio `professor` do Bloco 3 |
| `analise_riscos.md` | Riscos gerais de produto/conteúdo que não dependem do modelo de venda | Toda a análise de stack/escopo B2B (dashboards de professor, OCR em nuvem) |
| `pesquisa_ferramentas.md` | Pesquisa de modelos de LLM para análise de redação (a decisão final foi Claude, não registrada aqui) | Pesquisa de OCR em nuvem (Vision/Azure/Document AI) — descartada; estimativas de custo "por escola" |

Se algo aqui contradiz `docs/produto/plano_b2c.md`, **vale o plano B2C**.
