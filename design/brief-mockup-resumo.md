# Brief para mockup — Resumo de sessão

> **Como usar:** cole este arquivo inteiro no Claude Design (ou Artifacts).
>
> **Sistema visual TRAVADO:** a marca já foi fechada (Home + Sessão). **Não
> explore novas paletas.** Reutilize os tokens, fontes e o "chrome sóbrio" do
> fim deste documento, para o Resumo sair coerente com as telas já feitas.

---

## O que é esta tela

O **Resumo de sessão** (produto 3.7): o feedback **leve** que aparece ao terminar
uma sessão de prática. **NÃO é um boletim** — é uma comemoração curta e gentil do
progresso. Aparece **depois** da última questão e leva o aluno de volta à
**Trilha (mapa)**.

App de vocabulário para o **Fundamental II brasileiro (~11–14 anos)** — amigável,
não infantil. Celular, retrato (mesmo "phone frame" das outras telas). Microcopy
em PT-BR. Mockup visual (HTML/CSS), não precisa ser funcional.

---

## O que gerar — 3 frames (lado a lado)

1. **Resumo padrão** — tema **claro**. Sessão concluída, XP ganho e a progressão
   das palavras. Sem item novo de coleção.
2. **Resumo com conquista** — tema **claro**. Igual ao 1, mas **há um item novo**
   no Passaporte: inclui um **bloco/teaser de conquista** ("Novo no Passaporte!")
   que antecede a abertura do Passaporte. Deve ser claramente celebratório, mas
   sem virar a tela inteira.
3. **Resumo padrão** — tema **escuro** (Capa do Passaporte).

---

## Conteúdo obrigatório

### Cabeçalho (comemoração calma)
- Um **selo/título** de conclusão (ex.: "Sessão concluída!") — tom leve, festivo
  mas sóbrio. Pode ter um ícone (bandeira de chegada, estrela, carimbo).
- **Destino/contexto** opcional e discreto (ex.: "Rio de Janeiro · Lição 3").

### XP da sessão (número-herói)
- **XP ganho nesta sessão** em destaque (ex.: **+480 XP**). É o número grande da
  tela.
- Abaixo, de forma **discreta**, o progresso do nível: a barrinha de XP avançando
  rumo ao próximo nó (ex.: "Nível 4 · 3.120 → 3.600"). **Sem** texto de "faltam X".
- Pode mostrar o **melhor combo** da sessão como um chip pequeno (ex.: "🔥 melhor
  combo ×5") — opcional, secundário.

### Progressão das palavras (o que mais importa)
- Lista curta das **palavras trabalhadas** e como evoluíram. Dois estados:
  - **Dominada** ✅ — a palavra "graduou" (ex.: **vasto** · *Dominada!*) — destaque
    em verde (success), com selo de check.
  - **Subiu de nível** ↑ — avançou mas ainda não dominou (ex.: **relevante** ·
    *Nível 2 → 3*) — barrinha/seta, cor primária.
- Mostrar **2–3 palavras** (não a sessão inteira). É a unidade que importa
  (palavras dominadas), não acertos.

### Bloco de conquista (apenas no frame 2)
- Um card celebratório: **"Novo no Passaporte!"** com a prévia do item (ex.: um
  **cartão-postal do Rio** ou um **carimbo do Brasil**) parcialmente revelado/
  brilhando, e um CTA "Ver no Passaporte". Dourado/ouro como cor da conquista.

### Ação (rodapé)
- **CTA primário: "Ver trilha"** → leva ao mapa (é para onde o aluno aterrissa
  ao sair da sessão, não para a Home).
- Ação secundária discreta opcional: "Voltar ao início".

---

## Dados de exemplo (use estes)

> ⚠️ **Valores ilustrativos (mockup):** os números abaixo servem só ao layout.
> A economia real de XP é definida pelo backend (servidor autoritativo) e deve
> sustentar o ritmo de **~2–4 sessões por nó** (~4.500 XP/nó) — não calibrar
> expectativa de progresso pelos valores deste brief.

```
Título: "Sessão concluída!"     Contexto: "Rio de Janeiro · Lição 3"
XP da sessão: +480 XP
Nível: 4   ·   XP: 3.120 → 3.600 / 4.500   (barra avançando)
Melhor combo: ×5

Palavras trabalhadas:
  • vasto      → Dominada!        (✅ verde)
  • relevante  → Nível 2 → 3      (↑ primária)
  • âmbito     → Nível 1 → 2      (↑ primária)

Frame 2 (conquista): "Novo no Passaporte!" → Cartão-postal: Rio de Janeiro
```

---

## NÃO incluir (decisões de produto)

- ❌ **Percentual de acerto** (X/Y certas, "80%") — vira boletim, contra "errar é
  aprender".
- ❌ **Tempo / velocidade** da sessão — incentivaria chute.
- ❌ **Streak diário / chama / meta diária / mascote.**
- ❌ Vermelho ou qualquer tom de "reprovação". O resumo é só ganho e progresso.

---

## Sistema visual TRAVADO (reutilizar de Home/Sessão)

Chrome sóbrio: fundo neutro; cor saturada reservada para XP, conquista e CTA.
Cards "papel" com borda hairline interna, cantos arredondados, sombras suaves.
Barra de progresso fina arredondada. Botão primário sólido na cor primária.

**Fontes:** Fredoka (display/números/títulos) · Nunito (corpo/listas) · Caveat
(só acento "Passaporte") · Space Mono (micro-rótulos CAIXA ALTA).

**Paleta CLARA — "Azul Brilhante" (areia + azul vivo)**
```
fundo:       #FBF3E4 (ou Fundo A #F4F0E7 com leve brilho azul no topo)
card/papel:  #FFFDF8
primária:    #1E7FD6   (texto sobre primária: #FFFFFF)
XP:          #1E7FD6
sucesso/dominada: #16A971
ouro/conquista:   #E0A82E  ·  ouro forte: #B9851A
texto:       #33302B   ·  texto suave: #7A6B5C
linha/trilho: rgba(120,90,50,.16)
```

**Paleta ESCURA — "Capa do Passaporte" (navy + dourado champanhe)**
```
fundo:       #172A44   ·  card/papel: #21385A
primária:    #5FA9E0   (texto sobre primária: #0E2235)
XP / ouro:   #D9C083
sucesso/dominada: #3FB97E
texto:       #F2EAD9   ·  texto suave: #9DB0C8
linha:       rgba(255,255,255,.10)   ·  trilho: rgba(255,255,255,.12)
```

Mantenha o "feel" das telas já feitas: chips/pílulas, ícones de linha uniformes,
hierarquia clara (XP em destaque, palavras como lista, CTA dominando o rodapé).

---

## Saída

Os 3 frames lado a lado, mobile portrait, PT-BR, estritamente no sistema acima.
Quando estiver bom, exportar como **HTML standalone** para o agente implementar em
Flutter (reaproveitando `AppColors`, `AppType`, `SurfaceCard`, `ProgressBar`).
