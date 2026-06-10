# VocabKids — guia para agentes e devs

App de vocabulário (Flutter) + backend FastAPI para o Fundamental II brasileiro.
Tema: viagem/passaporte (3 países → 20 destinos → 80 nós). Cliente fino,
servidor autoritativo.

## Mapa dos documentos

| Documento | Papel |
|---|---|
| `docs/rascunho_product.md` | Produto — fonte da verdade das decisões de produto |
| `docs/arquitetura.md` | Arquitetura — modelo de dados, pipelines, API, app |
| `design/telas.md` | **Contrato** de conteúdo/comportamento de cada tela |
| `design/brief-mockup-*.md` | **Contrato** visual por tela (sistema travado) |
| `design/notas-implementacao.md` | Registro vivo: feito, adiado, decisões revisadas |
| `HANDOFF.md` | Estado de trabalho entre sessões (histórico) |

## ⚠️ Regra das decisões revisadas (obrigatória)

**Uma decisão revisada só vale quando os documentos contratuais forem editados
junto, no mesmo commit/PR.** Ao mudar uma decisão de produto/design:

1. Registrar a decisão (com data) em `design/notas-implementacao.md`;
2. **No mesmo commit**, atualizar `design/telas.md` e os briefs afetados
   (`design/brief-mockup-*.md`) — e `docs/arquitetura.md` se tocar
   modelo/API;
3. Se o backend/app já implementa o comportamento antigo, a mudança de código
   (com testes) entra no mesmo PR ou vira pendência explícita nas notas.

Racional: já regredimos por docs "travados" e desatualizados (erro âmbar→
vermelho, selo "você está aqui", combo por dia→por sessão). Um documento que
se declara travado e está errado é pior que nenhum documento.

## Decisões de produto que NÃO mudam sem o dono

- Sem streak diário, meta diária, mascote, % de acerto ou tempo/velocidade.
- Erro de resposta = vermelho suavizado (tint + borda/texto), nunca punitivo.
- Combo é **por sessão** (zera ao abrir sessão). Meta é **semanal** (professor).
- Colecionáveis são puramente colecionáveis (sem bônus de gameplay);
  reveal nítido só no Passaporte; determinístico, sem loot box.
- O cliente nunca calcula pontuação nem recebe a resposta correta antecipada.

## Convenções de código

- **Flutter** (`app/`): feature-first; cores via `context.colors` (tokens em
  `core/theme/app_colors.dart`), nunca hardcoded. Dependências com **versão
  exata** no `pubspec.yaml`; `pubspec.lock` commitado — atualizar dep é PR
  deliberado.
- **Backend** (`backend/`): rotas → serviços → repositórios, por domínio.
  Migrations Alembic lineares (uma cadeia única). Testes: `uv run pytest`
  (exige Postgres; ver `tests/conftest.py`).
