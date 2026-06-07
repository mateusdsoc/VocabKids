# HANDOFF — telas Flutter (VocabKids)

> Estado do trabalho de **porte das telas do Claude Design → Flutter**.
> Branch: `claude/awesome-lewin-7cdad3` (PR aberto para `main`).
> Próximo passo é abrir no VSCode, **corrigir o bloqueio de build**, rodar e
> conferir as telas visualmente.

---

## ⚠️ PRIMEIRO: bloqueio de build (resolver antes de rodar)

`app/lib/features/home/home_providers.dart:19`
```dart
final me = ref.watch(authControllerProvider).valueOrNull;
```
Erro: `The getter 'valueOrNull' isn't defined for the type 'AsyncValue<Me?>'`.
Surgiu quando o `flutter pub get` resolveu versões mais novas neste worktree.
**Bloqueia o `flutter run` do app inteiro** (por isso as telas novas não foram
verificadas visualmente). É pré-existente — NÃO veio das telas desta branch.

Provável correção: trocar `.valueOrNull` por `.value` (conferir a versão do
`flutter_riverpod` resolvida) ou alinhar a versão do riverpod.

---

## Telas (analyzer-clean, **não** verificadas visualmente)

| Tela | Pasta | Estado |
|---|---|---|
| Home | `features/home/` | Já existia; agora com **cards de vidro** no claro |
| Sessão | `features/sessao/` | Já existia (5 estados) |
| **Resumo de sessão** | `features/resumo/` | **Novo** — claro+escuro, variante "com conquista" |
| **Trilha (mapa)** | `features/trilha/` | **Novo** — v5 escuro · variação B, **estático** (sem bob) |

## Design system (mudanças desta branch)

- **Token `glass`** em `core/theme/app_colors.dart`: cards = vidro fosco no claro
  (`SurfaceCard` e a bottom nav aplicam `BackdropFilter`). `paper` segue **opaco**
  para menus/popovers/alternativas (legibilidade). No escuro `glass == paper`.
- **CTA primário** unificado em `core/widgets/primary_button.dart` (`PrimaryButton`)
  — era `sessao/widgets/session_cta.dart` (removido).
- **`core/format.dart`** (`milhar`) — dedup do separador de milhar.
- **Trilha**: paleta decorativa de relevo em `features/trilha/widgets/trilha_tones.dart`
  (claro = design v4, escuro = design v5).

## Fluxo de navegação / decisões de produto

- **Sessão** → (fim) `pushReplacement` → **Resumo** → "Ver trilha" `pushReplacement`
  → **Trilha**. "Voltar ao início" volta pra Home.
- **Home**: aba "Trilha" / "Ver mapa" → Trilha; "Praticar" / card Continuar → Sessão.
- **Recompensa (colecionável):** a **Resumo** anuncia e dispara o Passaporte; a
  **Trilha NÃO revela** (sem pop-up) — postal fica **embaçado** + selo discreto.
  O reveal nítido é exclusivo do **Passaporte** (ainda não implementado).
- Sem "você está aqui" na Trilha; bloqueados como silhueta/relevo gravado.

---

## A fazer / verificar no próximo chat (VSCode)

1. **Corrigir o bloqueio do riverpod** (acima) → `flutter run`.
2. **Conferir visualmente** cada tela em claro **e** escuro:
   - Trilha: posições dos nós usam coords absolutas no espaço **340×540** — risco
     de overflow/recorte de rótulos em telas estreitas; conferir o aside
     "Continuar" do Rio, os medalhões (atual nítido / concluído embaçado /
     bloqueado fantasma), o portão da França e a fronteira.
   - Resumo (claro+escuro, com e sem conquista) e Home (cards de vidro).
3. **Ícones-fantasma da Trilha** são aproximações do Material (Eiffel →
   `cell_tower`, monumento → `account_balance`). Trocar por SVG do design se
   quiser fidelidade.
4. **Animações deferidas** (hoje estáticas): confete da Sessão, *bob* do nó atual
   da Trilha, reveal do Passaporte.
5. **Telas ainda não feitas:** Passaporte (Modo Conquista / reveal polaroid do
   postal), Onboarding, Entrada/Me (hoje placeholders Material crus),
   Redação/Dashboard (mock).
6. **Backend (cliente fino):** as telas rodam com dados de exemplo (`*.sample`);
   o wiring com `/v1/*` ainda não foi feito (ver `design/notas-implementacao.md`).

## Avisos pré-existentes (não desta branch)

- `home_providers.dart:19` `valueOrNull` (o bloqueio acima).
- `home_mapper.dart:3` import `characters` (info do analyzer).
- `home_top_bar.dart:7` `<...>` em doc comment (info do analyzer).

## Rodar

```bash
cd app
flutter pub get
flutter run   # após corrigir o bloqueio do riverpod
```

> Os designs-fonte (HTML do Claude Design) ficam no bundle exportado; os briefs
> e a paleta travada estão em `design/`. Memória do projeto (auto-lida pelo
> Claude Code) resume o histórico e as decisões.
