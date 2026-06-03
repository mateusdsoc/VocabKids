# Referência de Arte e Animação — VocabBR Kids

> Catálogo das 28 peças de arte do MVP (cartões-postais, carimbos, selos) + briefing
> do estilo visual e da animação de revelação do passaporte.
>
> Decidido nas discussões de design. Conecta com:
>
> - `rascunho_product.md` seções 3.7 (trilha), 3.10 (recompensas/passaporte), 12 (stack/animação)
> - `arquitetura.md` Bloco 1, tabelas `pais` / `destino` / `colecionavel`
> - `analise_riscos.md` seção 07 (animação em aberto / teste da peça-âncora)
>
> Status: catálogo de arte **fechado**; ferramenta de animação **em aberto** (depende
> do teste da peça-âncora — ver seção final).
>
> Data: 02 de junho de 2026.

---

## 00 - Estilo visual (travado a partir das imagens-âncora)

O estilo está definido pelas duas primeiras imagens geradas (Rio e Paris) e deve ser
mantido nas 28 peças. Características observadas:

- **Paisagem ampla com marco-âncora + ambiente**, não "monumento isolado". A cena come
  cenário: a Torre vem com Sena, ponte, barco, prédios, lua; o Cristo vem com Pão de
  Açúcar, baía, bondinho, praia, palmeiras. **Isto é o que resolve o problema dos
  destinos "sem destaque óbvio"** — o marco pode ser modesto desde que a cena seja
  cheia.
- Ilustração estilo cartoon/editorial, cores saturadas, contornos limpos.
- Iluminação de "hora dourada" / céu dramático (pôr do sol no Rio, noite estrelada com
  lua em Paris) — dá o ar premium e colecionável.
- Composição cheia até as bordas; vegetação/elementos em primeiro plano emoldurando a
  cena.

> **Tipo de lugar a escolher:** marcos + natureza/paisagem. Decidido a partir do estilo:
> ele não exige monumento mundialmente famoso, exige uma cena rica. Castelo, vinhedo,
> dunas, vila litorânea rendem composição tão forte quanto a Torre.

---

## 01 - Cartões-postais (20 peças) — recompensa de destino

Um por destino. Ordem = dificuldade na trilha (Brasil = onboarding/fácil → Japão =
aspiracional). Vira seed da tabela `destino` (`arquitetura.md` Bloco 1), com `ordem`
seguindo a numeração abaixo. Decisão registrada: **um destino por atração** (não por
cidade) — otimiza variedade visual, que sustenta o colecionar.

### 🇧🇷 Brasil — 5 destinos (país de entrada, menor de propósito)

|#|Destino                         |Marco-âncora + cena                                          |Status arte|
|-|--------------------------------|-------------------------------------------------------------|-----------|
|1|Rio de Janeiro — Cristo Redentor|Cristo + Pão de Açúcar + baía + bondinho + praia + pôr do sol|✅ gerada   |
|2|Foz do Iguaçu — Cataratas       |Quedas em leque + mata + névoa/arco-íris                     |✅ gerada   |
|3|Amazônia — Encontro das Águas   |Rio largo + dossel verde + barco regional                    |✅ gerada   |
|4|Fernando de Noronha             |Morro Dois Irmãos saindo do mar + enseada turquesa + barco   |⬜ a gerar  |
|5|Lençóis Maranhenses             |Dunas brancas + lagoas azuis + horizonte limpo               |⬜ a gerar  |

> Fernando de Noronha substituiu a sugestão inicial de Salvador/Pelourinho (descartada).
> Cobre o nicho "mar/ilha icônica" sem repetir o Rio. Segunda opção considerada: Ouro
> Preto (se preferir construção/história em vez de natureza).

### 🇫🇷 França — 7 destinos (intermediário)

|# |Destino                            |Marco-âncora + cena                          |Status arte|
|--|-----------------------------------|---------------------------------------------|-----------|
|6 |Paris — Torre Eiffel               |Torre + Sena + ponte + barco + prédios + lua |✅ gerada   |
|7 |Mont-Saint-Michel                  |Abadia sobre a ilha + maré + reflexo         |⬜ a gerar  |
|8 |Provença — campos de lavanda       |Faixas roxas + casa de pedra + sol baixo     |⬜ a gerar  |
|9 |Vale do Loire — Château de Chambord|Castelo com torres + jardim + rio            |⬜ a gerar  |
|10|Costa Azul — Nice/Riviera          |Enseada + casario ocre + mar turquesa        |⬜ a gerar  |
|11|Alpes — Mont Blanc                 |Pico nevado + vila alpina + chalés           |⬜ a gerar  |
|12|Versalhes — palácio e jardins      |Fachada dourada + jardins geométricos + fonte|⬜ a gerar  |

### 🇯🇵 Japão — 8 destinos (aspiracional, maior — recompensa quem chega)

|# |Destino                                  |Marco-âncora + cena                              |Status arte|
|--|-----------------------------------------|-------------------------------------------------|-----------|
|13|Tóquio — skyline moderno                 |Arranha-céus + Torre de Tóquio + letreiros       |⬜ a gerar  |
|14|Monte Fuji                               |Cone nevado + lago + cerejeiras em primeiro plano|⬜ a gerar  |
|15|Kyoto — Fushimi Inari                    |Túnel de torii vermelhos subindo o monte         |⬜ a gerar  |
|16|Kyoto — Kinkaku-ji (Pavilhão Dourado)    |Templo dourado + lago espelhado + outono         |⬜ a gerar  |
|17|Nara — parque e cervos                   |Pagode + cervos + alameda arborizada             |⬜ a gerar  |
|18|Hiroshima — Itsukushima (torii flutuante)|Portal vermelho na maré + montanha ao fundo      |⬜ a gerar  |
|19|Shirakawa-go — vila histórica            |Casas de telhado triangular + neve               |⬜ a gerar  |
|20|Osaka — castelo                          |Castelo branco e verde + cerejeiras + fosso      |⬜ a gerar  |

**Progresso de arte:** 4 de 20 cartões gerados (Rio, Foz, Amazônia, Torre Eiffel).

> **Egito (reserva, fora das 28):** o 4º país está engatilhado como reserva no produto
> (seção 3.7) e **não** entra na contagem do MVP. Se a demanda do 1º cliente justificar,
> seus destinos viram cartões adicionais sem mexer no sistema.

---

## 02 - Carimbos de passaporte (3 peças) — recompensa de país

Ganho ao completar o país inteiro. **Diferente do cartão:** é selo de imigração
estilizado — pequeno, monocromático/2 cores, circular, **não** uma paisagem.

|País    |Motivo                                       |Status   |
|--------|---------------------------------------------|---------|
|🇧🇷 Brasil|Silhueta do Cristo dentro do círculo "BRASIL"|⬜ a gerar|
|🇫🇷 França|Torre Eiffel dentro do círculo "FRANCE"      |⬜ a gerar|
|🇯🇵 Japão |Monte Fuji dentro do círculo "JAPAN"         |⬜ a gerar|

---

## 03 - Selos de feitos (5 peças) — conquista individual

Recompensa por feito, não por lugar. Os feitos já estão fixados no produto
(`rascunho_product.md` 3.10). **Direção visual decidida: tema-viagem** (não
medalha/emblema genérico) — mantém o passaporte como objeto visual coerente; uma
medalha lisa destoaria do estilo ilustrado das outras peças.

|Feito                       |Motivo (tema-viagem)                                                |Status   |
|----------------------------|--------------------------------------------------------------------|---------|
|1ª redação enviada          |Cartão-postal em branco com selo postal e carimbo ("primeira carta")|⬜ a gerar|
|Combo de 10 acertos seguidos|Bússola com a agulha cravada ("no rumo certo")                      |⬜ a gerar|
|25 palavras dominadas       |Mala de viagem com etiquetas                                        |⬜ a gerar|
|100 palavras dominadas      |Globo terrestre                                                     |⬜ a gerar|
|250 palavras dominadas      |Avião / baú de viajante experiente                                  |⬜ a gerar|

> Micro-progressão temática de graça: cartão → bússola → mala → globo → avião. Mesmo sem
> texto, o aluno sente os selos "subindo".

---

## 04 - Animação de revelação do passaporte (briefing)

Comportamento decidido nas discussões. Vale para os **28 itens** — cartões, carimbos e
selos usam a **mesma** lógica de revelação; só o asset muda.

### Decisões

1. **Só um momento de animação: o Modo Conquista.** O "toque no item já ganho" (Modo
   Exploração) foi **descartado** — não há segunda animação ao tocar um item antigo. No
   Modo Exploração o item simplesmente está lá, estático. (Reconcilia com `rascunho_product.md`
   3.10, que antes previa uma "versão curta" da animação ao tocar — removida.)
2. **Página única + flip decorativo na abertura — nunca folhear o histórico.** Ao ganhar
   um item, o passaporte sobe em tela cheia e abre **direto na página daquele item** (não
   há spread/livro nem travessia das páginas anteriores). Um **flip único, decorativo**,
   pode acompanhar a abertura — é autocontido (não precisa que página antiga exista).
   **Por que não folhear:** atravessar até a página atual obrigaria a renderizar todas as
   páginas anteriores mantendo consistência com cada card/selo já ganho — custo que
   **cresce com a coleção** e fica refém da ferramenta de animação. Abrir direto desacopla
   a animação do histórico. (Substitui o "vira até a página correta" do produto 3.10.)
3. **Cartão-postal: um por página, ocupando quase a página inteira.** Um-por-página é
   deliberado: a página nova está sempre **vazia** quando o cartão chega, então a animação
   renderiza só o **item novo, sozinho** — sem acoplar à coleção. Mais de um por página
   exigiria redesenhar/renderizar o card anterior daquela página, reintroduzindo o
   acoplamento; com só 20 cartões, o ganho de espaço não compensa.
4. **Selo: grid de coleção; só o selo novo anima (opção A — carima no próprio grid).** O
   selo é pequeno e **não** preenche uma página — então a página de selos é uma **grid**
   dos selos já conquistados. Na conquista, o passaporte abre na grid com os antigos
   **estáticos, já colados**, e **só o selo novo anima** (cai/pulsa/encaixa no slot
   vazio). Isso preserva o beat motivacional do *"quase completei a coleção!"* (alinhado
   às silhuetas do que falta, 3.10) e é **barato**: os antigos são no máximo 4 assets
   **estáticos** (coleção limitada a 5 selos), sem consistência de animação a manter.
   Cabe em **uma** página no MVP; se um dia passar de uma grid cheia, pagina-se a grid.

> **Princípio unificador (já no espírito do produto):** *a página é dinâmica (reflete o
> histórico do aluno), mas a animação é fixa — só o item novo se mexe.* A única diferença
> entre os casos é o "fundo": no **cartão** é uma página vazia (1 por página); no **selo**
> são os selos antigos já colados na grid. Em nenhum dos dois se anima o histórico.

### Sequência de revelação (Modo Conquista)

```
fim da sessão → resumo leve → [se há item novo]:
  passaporte sobe em tela cheia (flip decorativo único na abertura)
  → abre DIRETO na página do item (cartão: página única | selo: grid de selos)
  → [selo: grid com os antigos já estáticos] o item novo pulsa
  → aluno toca → item revela e encaixa no slot
  → passaporte permanece aberto p/ exploração, ou fecha
```

- Itens ainda não conquistados aparecem como **silhueta/cadeado** (já previsto no
  produto) — o slot vazio espera o item.
- Princípio mantido: **animação curta e não-bloqueante** (não trava o aluno; mesmo
  princípio das animações de sessão).

---

## 05 - Ferramenta de animação (em aberto — teste da peça-âncora)

Esta decisão **não está fechada** e segue o que `rascunho_product.md` (seção 12) e
`analise_riscos.md` (seção 07) já registram: decidir via **teste da peça-âncora**
(prototipar a revelação do passaporte de verdade e ver qual "vende").

### Separação de camadas (importante)

- **Arte estática (as 28 peças):** geração de imagem por IA / ilustração. **Não** é
  Lottie/Rive. Independe da ferramenta de animação — pode ser feita já (em andamento).
- **Movimento (pulsar, encaixar, abrir, grid):** é aqui que entra a escolha de
  ferramenta.

### Leitura técnica da discussão

- **A exigência "selos antigos persistem na grid" praticamente elimina o Lottie** para
  essa tela: arquivo Lottie é animação pré-renderizada e fixa, não lê estado do usuário
  (quantos selos ele tem). Fazer grid dinâmica em Lottie exigiria manipular o JSON em
  runtime — gambiarra que já é programar, perdendo a vantagem do "pronto". Lottie brilha
  em coisa autocontida e sempre igual (confete, check, troféu girando).
- **Código Flutter faz a grid dinâmica naturalmente:** lê `aluno_colecionavel`, monta a
  grid com os existentes, anima só o novo. É movimento de UI — o ponto forte do código
  gerado por IA, e fecha os 3 critérios (premium o suficiente / sem designer / sem
  gastar). Pacotes candidatos: `flutter_animate` (abrir, pulsar, encaixar) e `confetti`
  (celebração), citados na stack (seção 12 do produto).
- **Fluidez não é propriedade da ferramenta:** os três rodam a 60fps. A suavidade vem do
  *easing* e de quem animou. Lottie costuma parecer fluido porque um designer caprichou
  no After Effects — não porque a tecnologia seja superior. Código Flutter com o mesmo
  easing (`Curves.easeOutBack` etc.) sobre o motor Impeller entrega movimento igualmente
  liso.
- **Onde Rive/Lottie genuinamente ganham:** deformação de **personagem ilustrado**
  (squash & stretch, rig orgânico — um mascote ganhando vida). Código Flutter fica duro
  nisso. **Mas** a IA do Rive só gera a *lógica* de state machine, não a arte riggada —
  reintroduz o designer.

### Conclusão provisória (a confirmar pelo teste)

Para o movimento desenhado aqui (abrir, pulsar, encaixar, grid montando) — que é **tudo
movimento de UI** — o caminho natural é **código Flutter escrito por IA**. O Rive só
valeria o custo (e o designer) se a visão mudar para **personagens deformando
organicamente**. A decisão final sai do protótipo, não da intuição.

**Não bloqueia o agora:** a arte das 28 peças é a mesma seja qual for a ferramenta. O
catálogo pode ser produzido em paralelo ao teste da peça-âncora.
