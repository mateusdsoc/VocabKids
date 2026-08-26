# VocabKids — App (Flutter)

App do aluno (7–12 anos), B2C. Cliente **fino**: renderiza e captura; toda a
regra (XP, combo, sessão, adaptação, entitlement de assinatura) mora no
backend. Stack: Flutter + Riverpod, feature-first, mobile-only, único
entrypoint (`lib/main.dart`).

> Comandos completos (dart-defines, como rodar, `flutter analyze`/`test`)
> vivem no `CLAUDE.md` da raiz do repo — este README não os duplica, só
> orienta a estrutura. Se os dois divergirem, o `CLAUDE.md` é a fonte da
> verdade.

## Estrutura

```
app/
  lib/
    core/                 # transporte e infraestrutura (sem regra de domínio)
      config.dart         # dart-defines (API_BASE_URL, DEMO, THEME, REVENUECAT_API_KEY)
      api_client.dart      # HTTP sobre /v1: JSON, Bearer, traduz falhas p/ ApiException
      token_store.dart     # token JWT em flutter_secure_storage — só um por vez
      theme/               # tokens de cor/tipografia (app_colors.dart, ...)
    features/
      identidade/          # cadastro/login do responsável, seletor de perfil, criar criança, /me
      assinatura/           # paywall (RevenueCat) — só alcançável pelo responsável
      onboarding/            # boas-vindas, demos, diagnóstico
      home/                  # hub: status, meta semanal, "Continuar"
      sessao/                # prática: cards de descoberta + questões
      resumo/                # resumo de fim de sessão
      trilha/                # mapa da jornada (mapa vertical contínuo)
      passaporte/            # coleção (Modo Conquista / Modo Exploração)
      redacao/               # lista, envio (digitado), resultado analisado
      responsavel/           # portão PIN, resumo semanal por filho, excluir conta
      configuracoes/         # preferências locais do aparelho (SharedPreferences)
    main.dart              # ProviderScope + _Gate (rota por SessaoState)
  test/
```

Padrão de dados em toda feature: DTOs espelham os schemas do backend
(`data/`), um `*Mapper` traduz para modelos de apresentação, providers
Riverpod (GETs em `FutureProvider`, mutações em `AsyncNotifier`).
`AppConfig.demo` serve dados `*.sample` sem backend.

> Havia um segundo entrypoint (`main_professor.dart`, web, venda por escola)
> até o pivô pra assinatura B2C deletar o professor — ver `CLAUDE.md` e
> `docs/produto/plano_b2c.md` §09.

## Rodar e testar

Ver `CLAUDE.md` (seção "Comandos → App") para o passo a passo completo:
backend rodando, dart-defines e `flutter analyze && flutter test`.
