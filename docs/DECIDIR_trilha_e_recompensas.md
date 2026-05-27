# DECIDIR — Trilha, nós, pontos turísticos, cidades e recompensas

> **Status:** EM ANDAMENTO — parcialmente resolvido. O **Tópico 4 (a trilha é a home?) está FECHADO** e já mesclado no `rascunho_product.md` (seção 3.7 + tabela de decisões). O **Tópico B (dimensionamento da trilha e custo de recompensas) segue em andamento** — números ainda a confirmar. **Não apagar este arquivo ainda**: ele só some quando o Tópico B fechar.
> **Objetivo:** dimensionar a trilha (nós → pontos turísticos → cidades), definir o ritmo de progressão e o custo de recompensas/arte. (A pergunta "a trilha é a home?" já foi respondida — ver abaixo.)
> **Ao terminar o que falta:** mesclar o dimensionamento em `rascunho_product.md` (seções 3.7 e 3.10) e **apagar este arquivo**.
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
  - **Feitos** (10 acertos seguidos, dominar N palavras, etc.) → **selos** → **precisa de arte**. (Sem ofensiva/streak de dias — decidido não usar.)
  - **Eventos** → troféus + hall da fama (fora do escopo desta decisão).
- **Cidades do MVP**: 3 — **BH, São Paulo, Rio de Janeiro**.
- **Progressão por XP** (3.7): os nós enchem por XP, não por nº de palavras. Limiares na "casa dos milhares".
- **Valores de XP** (3.7): acerto 100 (1ª tentativa) / 70 (2ª) / 50 (3ª+, piso); dominar palavra = +500; bônus de combo por acertos seguidos.
- **Estrutura da sessão** (3.4): ~12 questões, **2 palavras novas por sessão**, nível 4 (avaliação) de cada palavra adiado ~2 sessões.
- **Banco inicial** (3.5): **500–800 palavras**.
- **Passaporte está "a revisar"** (3.10): a parte técnica é simples; o custo real é **arte/ilustração**, que escala com a quantidade de pontos turísticos, cidades e selos.

---

## 3. As perguntas a decidir

### Tópico 4 — A trilha é a home? — ✅ RESOLVIDO (mesclado no rascunho, seção 3.7)

**Decisão:** a trilha **NÃO** é a home. Ao abrir o app, o aluno cai numa **home-hub**; a trilha é uma **seção dedicada**, a um toque da home.

**Raciocínio:** o Duolingo pode ter o caminho como home porque o app *é* só a trilha. O VocabBR Kids orquestra também redação, eventos, leaderboards e dashboards — então uma home-hub que dá acesso a tudo isso faz mais sentido, com a trilha como destino central da prática.

**Como ficou:**
- **Home** = status do aluno (XP/nível, nó atual, **número** de palavras dominadas, métricas básicas) + **"Continuar"** (CTA primário, vai direto à próxima sessão) + acesso ao mapa da trilha (secundário) + atalho de redação + acesso a eventos e leaderboards.
- **Trilha (seção)** = mapa, "você está aqui", próximo nó/ponto turístico, continuar a sessão dali.
- **Ao sair de uma sessão, o aluno aterrissa na trilha (mapa), não na home** — reforça o senso de progresso e puxa para a trilha.
- Hierarquia visual fina dos botões = detalhe de design.

**Bônus resolvido nesta rodada (eventos × trilha/recompensas, pós-MVP — mesclado na seção 3.9):** evento **pausa a trilha** e suas recompensas (cartão-postal/carimbo pausam junto); **a meta semanal continua contando**; recompensa do evento = troféu + hall da fama, com espaço para recompensas mais **temáticas** a explorar. (O app **não terá ofensiva/streak de dias** — decidido nesta rodada.)

**Ficou em aberto (registrado na seção 10 do rascunho):**
- Conteúdo do evento: só revisão de palavras dominadas ou também palavras novas? (afeta a meta semanal durante eventos)
- Recompensas temáticas de evento, além de troféu + hall da fama.

### Tópico B — Dimensionamento da trilha e custo de recompensas — ⏳ EM ANDAMENTO

> **Status:** os números (pontos turísticos por cidade, nós por ponto, XP/sessões por nó, conjunto de selos) ainda **não estão fechados** — ficaram como "em andamento, a discutir". A proposta de partida abaixo é a baseline de trabalho, ainda a confirmar com o dono. Este é o que falta para poder apagar este arquivo.

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
- [x] **Trilha é home?** — RESOLVIDO: não; home-hub separada, trilha é seção dedicada (ver Tópico 4).
- [ ] Pontos turísticos por cidade.
- [ ] Nós por ponto turístico.
- [ ] XP por nó / sessões por nó (e reconciliar a frase "um nó por sessão" da 3.7).
- [ ] Tamanho do conjunto inicial de selos.
- [ ] Plano para quando o conteúdo (3 cidades / banco) se esgotar.

Depois de fechar os itens restantes: mesclar em `rascunho_product.md`, atualizar a tabela de decisões fechadas e **apagar este arquivo**.
