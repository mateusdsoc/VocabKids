# Brief para mockup — Home-hub (3 direções)

> **Como usar:** cole este arquivo inteiro no claude design (ou Artifacts).
> Opcional: anexe `imagens/ancora-rio-cristo-redentor.png` — é o **tipo de arte
> colorida** que a UI vai emoldurar (um cartão-postal colecionável). A UI **não**
> deve copiar a cor dela; deve ser sóbria o bastante pra hospedar postais bem
> diferentes (Rio dourado, Paris noturna, lavanda roxa) sem competir.

---

## O que gerar

Gere **3 variantes da MESMA tela (Home-hub)** de um app educacional de
vocabulário para crianças do **Fundamental II brasileiro (~11–14 anos)**.

- Cada variante = **uma estrutura diferente + uma paleta diferente** (variante 1
  usa a Paleta 1, variante 2 a Paleta 2, variante 3 a Paleta 3).
- Formato: **celular, retrato** (mobile portrait). Mostre as 3 lado a lado se der.
- **Microcopy em português.** Use os dados de exemplo abaixo (não invente outros).
- Estilo: **amigável e divertido, mas não bebê** — é pré-adolescente, não
  educação infantil. Limpo, com boa hierarquia, toques de gamificação.
- Mantenha o **chrome sóbrio**: cor saturada reservada para CTA/destaques; fundo
  neutro. (As ilustrações coloridas é que carregam a cor, não a interface.)
- Renderize como mockup visual (HTML/CSS). Não precisa ser funcional.

---

## Conteúdo obrigatório da Home-hub (da spec `design/telas.md`)

A Home é o **hub ao abrir o app** — dá acesso a tudo, com a prática a um toque.
Deve conter, nesta ordem de prioridade:

1. **Status do aluno** (topo): nome/avatar; **nível**; **barra de XP** rumo ao
   próximo nó; **nº de palavras dominadas** (contador); bolha do **nó atual** da
   trilha.
2. **Progresso da meta semanal** — avanço rumo à meta, ex.: "6 de 10 palavras
   dominadas esta semana" (barra/contador discreto, não é colecionável). Não é
   meta diária — é **semanal**.
3. **CTA primário — botão grande "Continuar"** → leva direto à próxima sessão de
   prática. **Deve ser o elemento dominante da tela** (menor fricção pra praticar).
4. **Ação secundária — "Ver trilha / mapa"** (claramente menos proeminente que
   Continuar).
5. **Atalhos** (menores): **Redação**, **Eventos/Ranking**.
6. **Acesso ao Passaporte** pelo avatar/perfil (canto superior).

Regras de produto:
- "Continuar" >> "mapa" na hierarquia visual (não competem).
- **Não** exibir percentual de acerto nem tempo em lugar nenhum.
- O número que importa é **palavras dominadas** (não XP cru) — XP é a barra/nível.

### Dados de exemplo (use estes)
```
nome: Ana
nível: 4
xp_total: 3120
xp_para_proximo_no: 4500
palavras_dominadas: 23              (total acumulado)
no_atual: "Foz do Iguaçu" (Brasil)
meta_semanal: 6 de 10 palavras dominadas esta semana   (em progresso)
```

### NÃO incluir (decisões de produto — não importe da concorrência)
Apps de referência (Duolingo, Brilliant, Speak) ancoram nestes elementos — mas
**este produto decidiu não usá-los**. Não adicione:
- ❌ **Streak diário / chama / contador de dias seguidos.** Não existe streak aqui.
  A mecânica de "acertos seguidos" é o **combo dentro da sessão**, não uma
  sequência de dias na home.
- ❌ **Meta diária.** A meta é **semanal** (palavras dominadas/semana).
- ❌ **Mascote / personagem.** Não há mascote; o tema é **viagem/passaporte**.
- ❌ **Percentual de acerto, tempo ou velocidade** em qualquer lugar.

---

## Paletas (uma por variante)

Todas são **chrome neutro + acento saturado** — pensadas para emoldurar arte
colorida sem brigar com ela.

### Paleta 1 — "Sol & Mar" (calorosa, energética)
- Fundo: `#FFF8F0`  ·  Card/superfície: `#FFFFFF`
- Primária (CTA): `#FF7A59` (coral)  ·  texto sobre primária: `#FFFFFF`
- Secundária/acento: `#18B0A8` (turquesa)
- Destaque de XP/ouro: `#FFC24B`
- Texto: `#2A2A33`  ·  texto suave: `#8A8A99`  ·  sucesso: `#36C76B`
- Personalidade: quente, otimista, brincalhão.

### Paleta 2 — "Céu Limpo" (fresca, confiável)
- Fundo: `#F7F9FC`  ·  Card/superfície: `#FFFFFF`
- Primária (CTA): `#2D9CDB` (azul-céu)  ·  texto sobre primária: `#FFFFFF`
- Acento: `#FFC83D` (amarelo-sol)
- Texto: `#1E2A37`  ·  texto suave: `#7B8794`  ·  sucesso: `#58CC02`
- Personalidade: limpa, leve, confiável (linha Duolingo).

### Paleta 3 — "Diário de Viagem" (premium, vintage)
- Fundo: `#FBF3E4` (papel envelhecido)  ·  Card/superfície: `#FFFDF8`
- Primária (CTA): `#C7522A` (terracota)  ·  texto sobre primária: `#FFFFFF`
- Secundária: `#2C6E6A` (verde-azulado profundo)
- Destaque/ouro: `#D4A017`
- Texto: `#3A2E27`  ·  texto suave: `#9B8B7E`  ·  sucesso: `#3E7C4F`
- Personalidade: passaporte/diário de viajante, sofisticado, aspiracional.

---

## Variação de estrutura (explore 3 layouts distintos)

Mesmo conteúdo, arranjos diferentes — por exemplo:
- **Estrutura A:** status compacto no topo + "Continuar" gigante no centro +
  atalhos em linha embaixo (foco total na prática).
- **Estrutura B:** card de status maior (com o nó atual em destaque visual) +
  "Continuar" logo abaixo + grid 2×2 de atalhos.
- **Estrutura C:** topo com avatar/nível + "Continuar" como card-banner largo +
  trilha/mapa em preview (mini-mapa) + atalhos em lista.

Fique à vontade pra propor melhores arranjos — o importante é as 3 serem
**genuinamente diferentes** em estrutura, mantendo a hierarquia (Continuar
domina) e todo o conteúdo obrigatório.
