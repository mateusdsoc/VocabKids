# Notas de implementação — Flutter

Registro vivo do que **já foi feito**, do que ficou **adiado** (animações por
último, como combinado) e das **decisões/pendências de backend**. Atualizar a
cada tela implementada.

---

## ✅ Feito

### Home-hub (`features/home/`)
- Tela completa nos dois temas (claro "Azul Brilhante" / escuro "Capa do
  Passaporte") a partir do design system (`core/theme`).
- Componentes reutilizáveis: `SurfaceCard`, `ProgressBar`, `AppBottomNav`,
  `AppIcons`, tipografia `AppType`, tokens `AppColors`.
- Dados reais de `/me` + `/trilha` via `HomeMapper`; loading/erro/pull-to-refresh.

### Sessão (`features/sessao/`)
- 5 frames do design implementados como **uma tela com máquina de estados**
  (descoberta → questão → confirmar → feedback → continuar), claro e escuro.
- Componentes: `SessionTopBar` (progresso + combo + report), `DiscoveryCard`,
  `QuestionPanel`, `OptionTile` (neutro/selecionado/correto/erro), `FeedbackBar`,
  `ReportPopover`, `SessionCta`, `SessionBackground` (Fundo A + brilho radial).
- Tokens novos no `AppColors`: `warn` (erro âmbar, **nunca** vermelho) e
  `accentInk` (texto sobre o chip de combo).
- Navegação: card "Continuar" e aba "Praticar" da Home abrem a Sessão.

---

## ⏳ A fazer (adiado de propósito)

### Animações (deixadas por último)
- [ ] **Confete do acerto**: hoje é **estático** (`OptionTile._Confetti`,
      placeholder fiel ao mockup). Trocar por animação curta e **não-bloqueante**.
- [ ] **Transição entre questões** (slide/fade ao avançar).
- [ ] **Pulso do combo** quando incrementa.
- [ ] **Encher da barra de progresso** animado a cada resposta.
- [ ] Micro-animação de entrada do card de descoberta.

### Áudio
- [ ] **Pronúncia (TTS)** no `DiscoveryCard` — botão alto-falante hoje é no-op
      (`onSpeak`). Plugar `flutter_tts` ou áudio do backend.

### Interação
- [ ] **Tocar na palavra marcada** (enunciado/exemplo) reabrir o card de
      descoberta sem sair da questão. Hoje só o sublinhado pontilhado afoorda.
- [ ] **Selos pontilhados** do `QuestionPanel` são círculos sólidos translúcidos
      (aproximação). Dashed real exige `CustomPainter` — cosmético.

---

## 🔌 Pendências de backend (cliente fino)

A Sessão hoje roda com `sampleSession` (dados de exemplo). Wiring real:
- [ ] `POST /v1/sessoes` (montar a fila — entrega híbrida, sem vazar resposta).
- [ ] `GET /v1/sessoes/{id}/proximo`.
- [ ] `POST /v1/sessoes/{id}/respostas` (correção **server-side** → XP/combo/estado).
      Hoje a correção é local (demo); o servidor será autoritativo.
- [ ] `POST /v1/questoes/{id}/report` (mock na fatia A).
- [ ] **Re-queue do erro**: ao errar, a questão volta ao fim da fila (3.4). Hoje
      a tela só avança (a mensagem já avisa o aluno).

### Home — campos ainda não expostos pela API (ver `HomeMapper`)
- [ ] **Meta semanal** (palavras dominadas/semana) — placeholder 6/10.
- [ ] **Arte por destino** na `/v1/trilha` (asset_ref) — hoje só Rio/Paris.

---

## 🎨 Decisões de design fixadas
- Paleta **travada**: claro `#1E7FD6`/areia, escuro navy `#172A44`/dourado
  champanhe. Erro sempre **âmbar**, nunca vermelho.
- Sem streak diário, meta diária, mascote, % de acerto ou tempo (produto).
- Fontes: Fredoka (display) · Nunito (corpo) · Caveat (só "Passaporte") ·
  Space Mono (micro-rótulos).

---

## ▶️ Próxima tela sugerida
**Resumo de sessão** (produto 3.7) — par natural da Sessão: XP ganho + progressão
das palavras (subiu de nível / foi dominada). Sem % de acerto nem tempo. Depois:
Trilha (mapa) e Passaporte.
