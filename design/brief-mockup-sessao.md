# Brief para mockup — Sessão (núcleo da prática)

> **Como usar:** cole este arquivo inteiro no Claude Design (ou Artifacts).
> Opcional: anexe `imagens/ancora-rio-cristo-redentor.png` como exemplo do tipo
> de arte colorida que a UI emoldura (não copie a cor dela).
>
> **Importante — sistema visual TRAVADO:** a marca já foi decidida no refino da
> Home (`Refino/Vocab - Telas Refinadas.html`). **Não explore novas paletas.**
> Reutilize exatamente os tokens, fontes e o "chrome sóbrio" definidos abaixo,
> para a Sessão sair coerente com a Home.

---

## O que gerar

A **tela de Sessão** de um app de vocabulário para o **Fundamental II brasileiro
(~11–14 anos)** — amigável e divertido, mas **não infantil**. É a tela onde o
aluno pratica: cards de descoberta + questões de múltipla escolha, com feedback
contínuo.

- Formato: **celular, retrato** (mobile portrait), mesmo "phone frame" da Home.
- **Microcopy em português.** Use os dados de exemplo abaixo (não invente outros).
- Renderize como mockup visual (HTML/CSS). Não precisa ser funcional.

### Frames a produzir (mostre lado a lado)

Gere **5 frames** da mesma tela em momentos diferentes do fluxo:

1. **Card de descoberta** (1ª vez de uma palavra nova) — tema **claro**.
2. **Questão / múltipla escolha** (estado neutro, ninguém respondeu) — tema **claro**.
3. **Acerto** (mesma questão, opção certa marcada + feedback de XP/combo) — claro.
4. **Erro** (opção errada marcada, feedback gentil sem punição) — claro.
5. **Questão / múltipla escolha** (estado neutro) — tema **escuro** (Capa do
   Passaporte), para validar a versão dark.

---

## Conteúdo obrigatório (da spec `design/telas.md` §4)

### Topo (em todas as questões e no card)
- **Barra de progresso fina** que enche a cada questão respondida (ex.: 5/12).
- **Botão de sair/voltar** discreto à esquerda.
- **Ferramenta de report**: ícone discreto (ex.: bandeirinha) à direita; ao tocar
  abre uma caixa com **motivos predefinidos** ("a resposta parece errada", "não
  entendi a palavra"). Reportar **não** pula a questão e **não** dá XP.
- **Combo** atual quando houver sequência de acertos de 1ª tentativa (ex.: "🔥
  combo ×3") — discreto, perto do progresso.

### Frame 1 — Card de descoberta
- **Palavra nova em destaque** (grande, Fredoka).
- **Classe gramatical** curta (ex.: "adjetivo").
- **Definição curta e conversacional** (não dicionarística).
- **Exemplo em frase**, com a palavra destacada.
- **Áudio de pronúncia**: ícone de alto-falante (TTS) tocável.
- **CTA** para seguir (ex.: "Entendi" / "Continuar").
- Sem "gancho contextual de redação" nesta fatia (não há redação ainda).

### Frames 2–5 — Questão de múltipla escolha
- **Enunciado** da questão. Há 4 tipos (gere pelo menos um de cada entre os
  frames): **(1) significado**, **(2) sinônimo**, **(3) completar a frase**,
  **(4) julgar o uso**.
- **4 alternativas** em cartões tocáveis, bem legíveis.
- **Destaque inline** da palavra nova dentro do enunciado/alternativas; um affordance
  de que **tocar nela reabre o card** (definição/exemplo/áudio) sem sair da questão.
- **Estado de acerto (frame 3):** alternativa certa fica verde (`success`),
  feedback positivo + **+XP** (ex.: "+100 XP") + sugestão de confete/animação
  curta e **não-bloqueante**; mostra o combo subir.
- **Estado de erro (frame 4):** alternativa escolhida fica **vermelha suavizada**
  (padrão Duolingo: fundo com tint leve ~12% do vermelho, borda e "X" no vermelho
  `error` — nunca vermelho puro nem flash de tela), **feedback gentil** ("Quase!
  Vamos rever isso."), **sem punição**; a resposta certa **não** é revelada;
  deixa claro que a questão **volta mais à frente** (retry no fim da fila), não
  trava aqui.
- **Botão primário** de avançar ("Continuar") aparece **depois** de responder.

---

## Dados de exemplo (use estes)

```
Progresso: questão 5 de 12      Combo: ×3
Palavra nova (card): "vasto"  · adjetivo
  definição: "que ocupa muito espaço; muito grande, amplo."
  exemplo: "O Brasil tem um território vasto, cheio de paisagens diferentes."

Questão (significado) — tipo 1:
  enunciado: "O que significa vasto?"
  alternativas: "Muito grande, amplo" (correta) · "Muito antigo" ·
                "Pouco conhecido" · "Cheio de cores"
  acerto: +100 XP (1ª tentativa)

Questão (completar a frase) — tipo 3 (use no frame dark):
  enunciado: "O oceano é tão ____ que não dá para ver o outro lado."
  alternativas: "vasto" (correta) · "raro" · "breve" · "exato"

Report (caixa): "Por que está reportando?"
  motivos: "A resposta parece errada" · "Não entendi a palavra" ·
           "Tem um erro de digitação" · "Outro"
```

---

## NÃO incluir (decisões de produto — resistir ao reflexo da concorrência)

- ❌ **Percentual de acerto, tempo ou velocidade** em qualquer lugar (vira boletim
  e incentiva chute).
- ❌ **Vidas/corações, penalidade ou tom punitivo** no erro. Errar é aprender:
  o feedback é gentil e a questão reaparece depois. (O erro **é** vermelho —
  decisão revisada — mas na variante suavizada acima, nunca vermelho puro
  agressivo.)
- ❌ **Streak diário / chama / meta diária / mascote.** A mecânica é **combo por
  sessão** + meta semanal; o tema é viagem/passaporte, sem personagem.
- ❌ Mostrar a resposta correta "vazada" antes de responder.

---

## Sistema visual TRAVADO (reutilizar da Home — não alterar)

**Chrome sóbrio:** fundo neutro; cor saturada reservada para CTA, seleção e
feedback. As ilustrações/cores fortes não competem com a interface. Cantos
arredondados generosos, cards "papel" com borda hairline interna, sombras suaves.

**Tipografia**
- **Fredoka** — títulos/números/palavra em destaque (display).
- **Nunito** — corpo, alternativas, rótulos.
- **Caveat** — manuscrito, **só** em acentos de "passaporte" (não usar em questão).
- **Space Mono** — micro-rótulos em CAIXA ALTA (eyebrows), com letter-spacing.

**Paleta CLARA — "Azul Brilhante" (areia + azul vivo)**
```
bg (fundo):        #FBF3E4      paper (card):   #FFFDF8
primária (CTA):    #1E7FD6      sobre primária: #FFFFFF
acento/ouro:       #E0A82E      acento forte:   #B9851A
XP:                #1E7FD6      sucesso/acerto: #16A971
texto:             #33302B      texto suave:    #7A6B5C
linha/trilho:      rgba(120,90,50,.16)
erro (resposta errada): #D23F34 (vermelho terroso suavizado — borda/texto/X;
                        fundo da alternativa = tint ~12% sobre o papel)
atenção gentil (warn): âmbar terroso #C9821C (prazos/validação — NÃO é o erro)
```

**Paleta ESCURA — "Capa do Passaporte" (navy + dourado champanhe)**
```
bg (fundo):        #172A44      paper (card):   #21385A
primária (CTA):    #5FA9E0      sobre primária: #0E2235
acento/ouro:       #D9C083      XP:             #D9C083
texto:             #F2EAD9      texto suave:    #9DB0C8
sucesso/acerto:    #3FB97E
erro (resposta errada): #E8736A (legível sobre o navy; fundo = tint ~10%)
linha:             rgba(255,255,255,.10)   trilho: rgba(255,255,255,.12)
```

Mantenha a hierarquia e o "feel" da Home: barra de progresso fina arredondada,
chips/pílulas, botão primário sólido na cor primária, ícones de linha uniformes.

---

## Saída

Os 5 frames lado a lado, mobile portrait, microcopy PT-BR, usando estritamente o
sistema visual acima. Sem novas paletas. Quando estiver bom, exporto como
**HTML standalone** para o agente de código implementar em Flutter (reaproveitando
o design system já criado: `AppColors`, `AppType`, `SurfaceCard`, `ProgressBar`).
