# Brief para mockup — Trilha (mapa)

> **Como usar:** cole este arquivo inteiro no Claude Design (ou Artifacts).
> Opcional: anexe `imagens/ancora-rio-cristo-redentor.png` e
> `imagens/ancora-paris-torre-eiffel.png` como exemplo da arte dos destinos.
>
> **Sistema visual TRAVADO:** a marca já está fechada (Home, Sessão, Resumo).
> **Não explore novas paletas.** Reutilize os tokens, fontes e o "chrome sóbrio"
> do fim deste documento. Os **nós** devem manter a linguagem da mini-trilha que
> já existe na Home (medalhões circulares com anel + selo de check/cadeado).

---

## O que é esta tela

A **Trilha (mapa)** (produto 3.7): a **aterrissagem ao sair de uma sessão** (não
a Home). É o mapa visual da jornada — dá senso de progresso e mostra o próximo
passo. Aqui o aluno vê onde está ("você está aqui"), o que já concluiu e o que
vem pela frente, agrupado por **país → destino**.

App de vocabulário, Fundamental II brasileiro (~11–14). Celular, retrato. PT-BR.
Mockup visual (HTML/CSS).

Estrutura da jornada: **3 países → 20 destinos → 80 nós** (cada nó ≈ 4.500 XP, 1
nó a cada 2–4 sessões). No mockup, mostre **um recorte navegável** (o país atual
inteiro + o começo do próximo), não os 80 nós.

---

## O que gerar — 3 frames (lado a lado)

1. **Mapa · claro** — trilha sinuosa **vertical** (rola de baixo pra cima),
   com **"você está aqui"** no nó atual (Rio). País **Brasil** em progresso e o
   início da **França** (bloqueado) no topo.
2. **Mapa · escuro** — mesma tela na Capa do Passaporte.
3. **Detalhe de recompensa · claro** — o mesmo mapa com o **popover/realce de um
   destino concluído** revelando o **cartão-postal** ganho (e indício do
   **carimbo** do país ao completar o Brasil). Mostra a ligação trilha → coleção.

---

## Conteúdo obrigatório

### Caminho (o mapa)
- Uma **trilha sinuosa** conectando os nós (caminho pontilhado/sólido serpenteando).
  Trecho **percorrido** preenchido (verde/primária); trecho **futuro** apagado.
- **Nós = destinos (cidades)**, na linguagem da Home: **medalhão circular** com a
  arte do destino, **anel**; **selo de check** (concluído), **pulso/anel
  destacado** (atual = "você está aqui"), **cadeado + dessaturado** (bloqueado).
- Rótulo de cada nó: nome da cidade + micro-status (CONCLUÍDO · VOCÊ ESTÁ AQUI ·
  BLOQUEADO).
- O nó **atual** deve ser o mais evidente (é o foco da tela).

### Agrupamento por país
- **Cabeçalho de país** separando as seções (ex.: faixa "🇧🇷 Brasil" com um
  **carimbo de passaporte** se o país foi concluído, ou progresso "3 de 6
  destinos"). O próximo país aparece **bloqueado** ("desbloqueia ao concluir o
  Brasil").

### Recompensas (sem bônus de gameplay — são colecionáveis)
- **Concluir destino → cartão-postal**; **concluir país → carimbo**. No mapa,
  indique de forma sutil quais destinos já renderam postal (um selinho/cantinho),
  e no **frame 3** mostre a revelação do postal + o atalho "Ver no Passaporte".

### Ações
- **CTA para continuar a sessão** a partir do nó atual (ex.: botão flutuante
  "Continuar" ou o próprio nó atual tocável → abre a Sessão).
- **Acesso ao Passaporte** (ícone/atalho).
- **Barra inferior** de navegação com a aba **"Trilha" ativa** (Início · Trilha ·
  Praticar · Eventos · Perfil), igual à da Home.

---

## Dados de exemplo (use estes)

```
País atual: Brasil  ·  progresso "3 de 6 destinos"
Destinos (de baixo p/ cima, na ordem da trilha):
  • Salvador      — CONCLUÍDO ✅ (postal ganho)
  • Rio de Janeiro — VOCÊ ESTÁ AQUI (atual)        ← foco
  • Foz do Iguaçu  — BLOQUEADO 🔒 (próximo)
  • Brasília       — BLOQUEADO 🔒
  ...
Cabeçalho do próximo país (topo): "França — desbloqueia ao concluir o Brasil"
  • Paris — BLOQUEADO 🔒

Recompensa (frame 3): destino "Salvador" → Cartão-postal do Brasil revelado.
Progresso de nível (se útil no topo): Nível 4 · 3.120 / 4.500 XP
```

> Observação honesta sobre arte: temos ilustração real só de **Rio** e **Paris**.
> Para os outros destinos, use um **placeholder** (medalhão com inicial/ícone) —
> não rotule a foto do Rio como se fosse outra cidade.

---

## NÃO incluir (decisões de produto)

- ❌ **Streak diário / chama / meta diária / mascote.**
- ❌ **Percentual de acerto, tempo ou velocidade.**
- ❌ Tratar colecionáveis como **bônus de jogo** — postais/carimbos são só coleção.
- ❌ Confundir Trilha com Home: aqui o foco é **o mapa e o próximo passo**, não o
  hub. (A Home é outra tela.)

---

## Sistema visual TRAVADO (reutilizar de Home/Sessão/Resumo)

Chrome sóbrio: fundo neutro; cor saturada reservada para o nó atual, trecho
percorrido, recompensa e CTA. Cards "papel" com borda hairline, cantos
arredondados, sombras suaves. Medalhões circulares com anel (igual à Home).

**Fontes:** Fredoka (display/nomes/números) · Nunito (corpo/rótulos) · Caveat
(só acento "Passaporte") · Space Mono (micro-rótulos CAIXA ALTA: status dos nós).

**Paleta CLARA — "Azul Brilhante" (areia + azul vivo)**
```
fundo:       #FBF3E4   ·  card/papel: #FFFDF8
primária:    #1E7FD6   (texto sobre primária: #FFFFFF)  ·  nó atual: primária
percorrido / concluído: #16A971 (verde)
ouro/recompensa (postal/carimbo): #E0A82E  ·  ouro forte: #B9851A
texto:       #33302B   ·  texto suave: #9C8C7D
linha/trilho: rgba(120,90,50,.16)
bloqueado: dessaturado + cadeado (cinza-areia)
```

**Paleta ESCURA — "Capa do Passaporte" (navy + dourado champanhe)**
```
fundo:       #172A44   ·  card/papel: #21385A
primária:    #5FA9E0   (texto sobre primária: #0E2235)
percorrido / concluído: #3FB97E
ouro/recompensa: #D9C083
texto:       #F2EAD9   ·  texto suave: #9DB0C8
linha:       rgba(255,255,255,.10)   ·  trilho: rgba(255,255,255,.12)
```

Mantenha o "feel" das telas já feitas: medalhões com anel, selos de check/cadeado,
barra inferior idêntica, hierarquia clara (nó atual domina; bloqueados recuam).

---

## Saída

Os 3 frames lado a lado, mobile portrait, PT-BR, estritamente no sistema acima.
Quando estiver bom, exportar como **HTML standalone** para o agente implementar em
Flutter (reaproveitando `AppColors`, `AppType`, `SurfaceCard`, `ProgressBar`, e a
linguagem de nós já feita na mini-trilha da Home).
