# Brief para mockup — Trilha (mapa) · versão com PROFUNDIDADE (3D estilizado)

> **Como usar:** cole este arquivo inteiro no Claude Design (ou Artifacts).
> Opcional: anexe `imagens/ancora-rio-cristo-redentor.png` e
> `imagens/ancora-paris-torre-eiffel.png` (arte dos destinos).
>
> **Sistema visual TRAVADO:** marca já fechada (Home, Sessão, Resumo). **Não
> explore novas paletas.** Reutilize tokens/fontes/chrome do fim do documento.
> **Mudança desta versão:** a tela anterior ficou **chapada (2D)**. Queremos um
> visual com **profundidade/relevo (estilo Duolingo), porém sóbrio** — "passaporte
> com volume", não doce neon. Tudo deve ser **3D *estilizado* via CSS** (gradientes,
> sombras em camadas, relevo, leve perspectiva) — **nada de modelo 3D real**.

---

## O que é esta tela

A **Trilha (mapa)** (produto 3.7): aterrissagem ao **sair de uma sessão**. Mapa
visual da jornada — "você está aqui", concluído e o que vem, agrupado por
**país → destino**. Fundamental II (~11–14), celular retrato, PT-BR, mockup HTML/CSS.
Jornada: **3 países → 20 destinos → 80 nós** (~4.500 XP/nó). Mostre um recorte
navegável (país atual + começo do próximo), não os 80 nós.

---

## ⭐ Direção de PROFUNDIDADE (o foco deste refino)

Pense em **objetos com volume sobre uma superfície**, com luz vindo de cima:

- **Nós = "fichas/medalhões 3D"**, não círculos chapados:
  - disco com **espessura**: uma **borda inferior mais escura** (3–5px) dando a
    impressão de altura, como um botão físico;
  - **brilho/realce no topo** (highlight sutil) e **sombra de contato no chão**
    (drop shadow macia, deslocada pra baixo);
  - leve **gradiente radial** na face (mais claro no topo-esquerda).
  - **Nó atual:** maior, "flutuando" (sombra mais espalhada), anel destacado e um
    selo "VOCÊ ESTÁ AQUI" como **etiqueta com relevo**; sugira um leve *bob*.
  - **Concluído:** medalhão com a arte + **selo de check em relevo**.
  - **Bloqueado:** aпарência **embutida/gravada** (estilo pedra/baixo-relevo),
    dessaturado, com cadeado **afundado** (inner shadow).
- **Caminho:** uma **trilha com volume** — um "caminho" levemente elevado ou
  pedras/etapas com sombra, serpenteando. Trecho percorrido com cor cheia +
  brilho; futuro apagado e "rebaixado".
- **CTA "Continuar":** o **botão chunky** do Duolingo — cor sólida com **aba
  inferior mais escura** (a espessura que "afunda" ao apertar) + brilho no topo.
- **Cartão-postal / carimbo (recompensa):** **cartõezinhos com perspectiva** —
  leve `rotate`/`skew`, borda branca, sombra projetada, um brilho diagonal
  (glossy discreto). O carimbo do país parece **carimbado em relevo** no papel.
- **Cabeçalho de país:** faixa como **carimbo de passaporte em baixo-relevo**
  (inset shadow no papel), não um retângulo plano.
- **Cena geral:** fundo com **leve vinheta/textura de papel** e sombras ambientes
  para dar palco aos objetos. Profundidade por **camadas de sombra**, não por cor
  berrante — mantenha o chrome sóbrio.

> Importante: **sem mascote/personagem** (decisão de produto). O volume vem dos
> objetos (nós, postais, carimbos, botão), não de um bichinho.

---

## Conteúdo obrigatório

- **Caminho** serpenteando, conectando os nós (percorrido preenchido/verde;
  futuro apagado).
- **Nós = cidades** com o tratamento 3D acima; rótulo nome + micro-status
  (CONCLUÍDO · VOCÊ ESTÁ AQUI · BLOQUEADO). Nó atual domina.
- **Cabeçalho de país** (carimbo em relevo) com progresso "3 de 6 destinos";
  próximo país bloqueado ("desbloqueia ao concluir o Brasil").
- **Recompensas** (colecionáveis, **sem bônus de jogo**): destino → postal;
  país → carimbo. Indique destinos que já renderam postal; **frame 3** revela o
  postal com volume + atalho "Ver no Passaporte".
- **Ações:** CTA chunky para continuar a sessão a partir do nó atual; acesso ao
  Passaporte; **barra inferior** com aba **"Trilha" ativa** (Início · Trilha ·
  Praticar · Eventos · Perfil), igual à da Home.

---

## O que gerar — 3 frames (lado a lado)

1. **Mapa · claro** — trilha sinuosa vertical (rola de baixo p/ cima), "você está
   aqui" no Rio, Brasil em progresso, França (bloqueada) no topo. **Com toda a
   profundidade descrita.**
2. **Mapa · escuro** (Capa do Passaporte) — mesmo relevo; no escuro, o highlight
   é mais sutil e o dourado dá o brilho.
3. **Detalhe de recompensa · claro** — popover revelando o **cartão-postal** com
   volume/perspectiva + atalho "Ver no Passaporte".

---

## Dados de exemplo (use estes)

```
País: Brasil · "3 de 6 destinos"
  Salvador — CONCLUÍDO ✅ (postal ganho)
  Rio de Janeiro — VOCÊ ESTÁ AQUI ← foco
  Foz do Iguaçu — BLOQUEADO 🔒 (próximo)
  Brasília — BLOQUEADO 🔒
Topo: "França — desbloqueia ao concluir o Brasil" → Paris 🔒
Frame 3: Salvador → Cartão-postal do Brasil revelado
Nível 4 · 3.120 / 4.500 XP (se útil no topo)
```
> Arte real só de **Rio** e **Paris**. Outros destinos → **placeholder** (medalhão
> 3D com inicial/ícone). Não rotular a foto do Rio como outra cidade.

---

## NÃO incluir

❌ streak/chama/meta diária/mascote · ❌ % de acerto/tempo/velocidade · ❌
colecionável como bônus de jogo · ❌ confundir Trilha com Home · ❌ **3D real /
glossy candy berrante** (queremos relevo sóbrio, não plástico neon).

---

## Sistema visual TRAVADO

Chrome sóbrio; cor saturada reservada para nó atual, percorrido, recompensa e CTA.
Cards "papel" com borda hairline. **Profundidade por gradientes + sombras em
camadas + relevo**, mantendo a paleta abaixo.

**Fontes:** Fredoka (display/nomes/números) · Nunito (corpo/rótulos) · Caveat (só
"Passaporte") · Space Mono (micro-rótulos CAIXA ALTA: status dos nós).

**Paleta CLARA — "Azul Brilhante"**
```
fundo: #FBF3E4 · card/papel: #FFFDF8
primária / nó atual: #1E7FD6 (texto sobre primária: #FFFFFF)
percorrido / concluído: #16A971
ouro/recompensa: #E0A82E · ouro forte: #B9851A
texto: #33302B · suave: #9C8C7D · linha/trilho: rgba(120,90,50,.16)
bloqueado: dessaturado, baixo-relevo (cinza-areia), cadeado afundado
```

**Paleta ESCURA — "Capa do Passaporte"**
```
fundo: #172A44 · card/papel: #21385A
primária: #5FA9E0 (texto sobre primária: #0E2235)
percorrido / concluído: #3FB97E · ouro/recompensa: #D9C083
texto: #F2EAD9 · suave: #9DB0C8 · linha: rgba(255,255,255,.10) · trilho: rgba(255,255,255,.12)
```

---

## Nota para o handoff (desempenho no Flutter)

Para o app **não pesar**, prefira profundidade que porta barato:
- **Relevo/sombra/gradiente/bevel** → vira `BoxDecoration` (gradiente + várias
  `BoxShadow`) e botão com aba inferior. Custo desprezível.
- **Arte "herói"** (medalhão da cidade, postal, carimbo) pode ser **PNG/WebP
  pré-renderizado** com cara 3D — é só imagem.
- Animações (pulso do nó atual, revelar postal) → **Rive/Lottie**, depois.
- **Evitar** 3D em tempo real (glTF/engine).

## Saída

3 frames lado a lado, mobile portrait, PT-BR, no sistema acima, **com profundidade**.
Exportar como **HTML standalone** ao final.
