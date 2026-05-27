# DECIDIR IMEDIATAMENTE — Trilha, nós, pontos turísticos, cidades e recompensas

> **Status:** decisão pendente, para ser discutida em sessão dedicada (contexto zerado).
> **Objetivo:** dimensionar a trilha (nós → pontos turísticos → cidades), definir o ritmo de progressão, o custo de recompensas/arte, e decidir se a trilha é a tela inicial (home).
> **Ao terminar:** mesclar as decisões de volta em `rascunho_product.md` (seções 3.7, 3.10, 3.5 e a tabela de decisões fechadas) e **apagar este arquivo**.
>
> Este documento é autossuficiente de propósito — quem pegar isto não precisa do histórico de conversa.

---

## 1. Contexto mínimo

O **VocabBR Kids** é um app de vocabulário em português para escolas (foco Fundamental II). O aluno pratica vocabulário por questões curtas, ganha XP, sobe de nível e avança numa **trilha temática visual** (tema: viagem por cidades brasileiras). Redações do aluno alimentam as palavras praticadas.

Fonte da verdade do produto: **`docs/rascunho_product.md`**. Seções relevantes para esta decisão:
- **3.7** — XP, níveis e trilha temática (estrutura cidade → ponto turístico → nó; progressão por XP).
- **3.10** — Sistema de recompensas (os três baldes; passaporte; está "a revisar" por causa do custo de arte).
- **3.4** — Estrutura da sessão (mecânica de domínio).
- **3.5** — Vocabulário adaptativo (diagnóstico, banco de palavras).

---

## 2. O que JÁ está decidido (NÃO rediscutir)

- **Estrutura da trilha** (3.7): três camadas — **Cidade → Ponto turístico → Nó**.
- **Recompensas por camada** (3.10), os três baldes:
  - **Nó** → feedback visual (**confete**), sem item colecionável → **custo de arte ZERO**.
  - **Ponto turístico** → **cartão-postal** colecionável → **precisa de arte**.
  - **Cidade** → **carimbo** no passaporte → **precisa de arte**.
  - **Feitos** (10 acertos seguidos, X dias de sequência, etc.) → **selos** → **precisa de arte**.
  - **Eventos** → troféus + hall da fama (fora do escopo desta decisão).
- **Cidades do MVP**: 3 — **BH, São Paulo, Rio de Janeiro**.
- **Progressão por XP** (3.7): os nós enchem por XP, não por nº de palavras. Limiares na "casa dos milhares".
- **Valores de XP** (3.7): acerto 100 (1ª tentativa) / 70 (2ª) / 50 (3ª+, piso); dominar palavra = +500; bônus de combo por acertos seguidos.
- **Estrutura da sessão** (3.4): ~12 questões, **2 palavras novas por sessão**, nível 4 (avaliação) de cada palavra adiado ~2 sessões.
- **Banco inicial** (3.5): **500–800 palavras**.
- **Passaporte está "a revisar"** (3.10): a parte técnica é simples; o custo real é **arte/ilustração**, que escala com a quantidade de pontos turísticos, cidades e selos.

---

## 3. As perguntas a decidir

### Tópico 4 — A trilha é a home?

**Pergunta:** ao abrir o app, o aluno cai direto na trilha (a trilha É a tela inicial, estilo Duolingo), ou numa home mais enxuta (ex.: um botão "continuar" com a trilha a um toque)?

- **Preocupação do dono do produto:** trilha como home pode jogar informação demais na cara ao abrir.
- **Referência (Duolingo):** o caminho É a home, mas funciona porque há **um único ponto focal** (a bolha "continuar" do próximo nó) e os metadados (ofensiva, XP, meta) ficam numa **barra fina no topo**. Ou seja, o problema não é "trilha na home", é **hierarquia visual**.
- **Status:** o dono não tem certeza; quer revisar. **Nada foi escrito no rascunho sobre isso ainda.**

**Dúvidas a resolver:**
- Trilha-como-home com 1 CTA dominante resolve o medo de "informação demais", ou ainda assim o dono prefere uma home separada?
- Onde ficam meta da semana e combo do dia (barra fina no topo da trilha vs. tela própria)?

### Tópico B — Dimensionamento da trilha e custo de recompensas

**Insight-chave (já alinhado):** o **custo de arte vem dos pontos turísticos (cartão-postal) e cidades (carimbo)** — NÃO dos nós (confete é grátis). Logo, a velocidade do nó é só "sensação" e é barata; o lever real para controlar custo de arte é a **granularidade de pontos turísticos e cidades**.

**Perguntas centrais:**
1. **Quantos pontos turísticos por cidade?** (cada um = 1 cartão-postal de arte)
2. **Quantos nós por ponto turístico?** (controla a frequência do cartão-postal)
3. **Quanto XP por nó / quantas sessões por nó?** (define o ritmo)
4. **Quantos selos no conjunto inicial de feitos?** (também é arte)

**Régua de calibração (aproximações que chegamos — CONFIRMAR com o dono):**
- ~**2 palavras novas/sessão** (decidido em 3.4).
- Suposição: ~**5 sessões/semana** (≈ 1 por dia letivo).
- → ~**10 palavras novas/semana**.
- Banco de **500–800 palavras** → ~**50–80 semanas** ≈ **1 a 1,5 ano** de uso até esgotar o banco base.
- As **3 cidades do MVP devem durar ~esse tempo** (não fazer o aluno "terminar o mapa" muito antes de esgotar o conteúdo).
- **Proposta de partida:** ~**6–8 pontos turísticos por cidade** → **~18–24 cartões-postais + 3 carimbos** no total. Conjunto de arte pequeno e definido, viável para o MVP.

**Minhas dúvidas / pontos em aberto (Claude):**
- As métricas de uso (2 palavras/sessão é firme; 5 sessões/semana é **suposição minha**) precisam ser confirmadas. Quantas sessões/semana o produto realmente espera (uso em sala vs. em casa)?
- Quanto tempo o dono **quer** que o MVP dure antes de precisar de mais conteúdo (mais cidades / expansão do banco)?
- Qual o **orçamento de arte** aceitável para o MVP (quantas peças no total: cartões + carimbos + selos)?
- O que acontece quando o aluno **termina as 3 cidades antes de esgotar o banco** (ou o contrário)? Precisa de um plano (mais cidades? loop temático? "modo livre"?).
- **Inconsistência a reconciliar no rascunho:** a seção 3.7 hoje diz "*o aluno avança um nó por sessão aproximadamente*", mas a subseção "Feedback de progresso na sessão" (3.7) trata a animação de conclusão de nó como algo "mais ocasional" que o resumo de sessão. Essas duas pontas só fecham depois de definir **quantas sessões enchem um nó**. O dono comentou achar a progressão "rápida demais" e teme excesso de recompensas — lembrar que **nó é de graça**; o medo real se resolve no nº de pontos turísticos/cidades, não na velocidade do nó.

---

## 4. Resultado esperado desta sessão

Definir números (ou faixas iniciais ajustáveis) para:
- [ ] Trilha é home? (sim, estilo Duolingo / não, home separada) — e a hierarquia visual.
- [ ] Pontos turísticos por cidade.
- [ ] Nós por ponto turístico.
- [ ] XP por nó / sessões por nó (e reconciliar a frase "um nó por sessão" da 3.7).
- [ ] Tamanho do conjunto inicial de selos.
- [ ] Plano para quando o conteúdo (3 cidades / banco) se esgotar.

Depois: mesclar em `rascunho_product.md`, atualizar a tabela de decisões fechadas e **apagar este arquivo**.
