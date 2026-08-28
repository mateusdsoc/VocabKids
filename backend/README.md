# VocabKids — Backend (FastAPI)

Backend do app B2C: FastAPI + SQLAlchemy Core + Alembic + PostgreSQL.

> Comandos completos (setup, seeds, testes, variáveis obrigatórias) vivem no
> `CLAUDE.md` da raiz do repo — este README não os duplica, só orienta a
> estrutura. Se os dois divergirem, o `CLAUDE.md` é a fonte da verdade.

## Estrutura

```
backend/
  app/
    config.py        # settings via env
    db.py             # engine/sessão async (asyncpg)
    schema.py         # schema único (25 tabelas, SQLAlchemy Core) — fonte das migrations e dos testes
    errors.py         # convenção de erro única: {"error": {"code","message","details"}}
    main.py           # app FastAPI: /health + handlers de erro + router /v1
    seed_vocabulario.py  # banco base de palavras/questões — idempotente
    seed_trilha.py    # trilha MVP (2 países/4 destinos/16 nós) + colecionáveis
    seed_temas.py     # catálogo de temas de redação
    seed_demo.py      # conta+perfis "vitrine" (assinatura ativa) p/ demo — reset a cada rodada
    api/
      v1.py           # agregador das rotas sob /v1
    identidade/       # conta do responsável + perfis de criança (cadastro, login, JWT)
    assinatura/       # gate de entitlement + webhook do RevenueCat
    vocabulario/      # leitura do banco global (card de descoberta)
    sessao/           # montar_sessao, responder (XP/combo/estado), fim (adaptação)
    diagnostico/      # escada grosso→fino → nivel_dificuldade_atual
    progressao/       # regras puras de XP/combo/faixa etária (xp.py, faixa.py, semana.py)
    adaptacao/        # regra pura da adaptação de nível
    trilha/           # mapa, passaporte e loop de recompensa (cartão/carimbo/selo)
    redacao/          # rubrica por faixa, triagem de risco, análise via Claude
    responsavel/      # Área do Responsável: PIN, resumo semanal por perfil
    report/           # POST /v1/questoes/{id}/report — ainda mock (sem fase B2C prevista)
    seguranca/        # rate limiting em memória
  tests/              # pytest + httpx (ASGI), contra um Postgres de teste
  alembic/            # migrations lineares (env.py aponta para app.schema:metadata)
```

Organização **por domínio** (rotas → serviço → repositório). Domínio novo =
pasta nova + uma linha em `app/api/v1.py`.

> O domínio `professor` (venda por escola, B2B) foi **deletado** no pivô pra
> assinatura B2C — ver `CLAUDE.md` e `docs/produto/plano_b2c.md` §09. `git log`
> tem o código se essa frente reabrir.

## Rodar e testar

Ver `CLAUDE.md` (seção "Comandos → Backend") para o passo a passo completo:
Postgres local, variáveis de ambiente obrigatórias (`JWT_SECRET`,
`REVENUECAT_WEBHOOK_SECRET`, `OPENAI_API_KEY`), migrations, seeds e
`uv run pytest`.

Erros saem no formato único: `{ "error": { "code": <snake_case>, "message": <legível>, "details": {} } }`.
