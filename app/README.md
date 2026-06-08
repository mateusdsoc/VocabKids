# VocabBR Kids — App (Flutter)

App do aluno, fatia **A** (apresentável). Cliente **fino**: renderiza e captura;
toda a regra (XP, combo, sessão, adaptação) mora no backend (Bloco 3 da arquitetura).

Stack decidida (arquitetura, Bloco 3): **Flutter + Riverpod**, feature-first,
mobile-only no apresentável. Fala a API `/v1` do backend (REST/JSON, auth-agnóstica).

## Estrutura

```
app/
  lib/
    core/                 # transporte e infraestrutura (sem regra de domínio)
      config.dart         # base da API via --dart-define=API_BASE_URL
      api_client.dart     # HTTP sobre /v1: JSON, Bearer, traduz falhas p/ ApiException
      api_exception.dart  # erro no formato único do backend ({error:{code,message,details}})
      token_store.dart    # token provisório da fatia A (prov_<id>); auth real entra depois
    features/
      identidade/         # acesso por código de turma → /me
        models.dart       # espelha identidade/schemas.py (Pydantic)
        repository.dart   # /v1/acesso/turma, /v1/me
        auth_controller.dart  # AsyncNotifier<Me?> + providers Riverpod
        entrada_screen.dart   # UI PROVISÓRIA (design pendente)
        perfil_screen.dart    # Perfil: identidade + progresso + atalho ao Passaporte + Configurações
      configuracoes/        # preferências locais do aparelho (SharedPreferences)
        preferencias.dart           # modelo (tema/som/vibração/lembretes)
        preferencias_controller.dart # AsyncNotifier persistido; alimenta o themeMode
        configuracoes_screen.dart   # tela de ajustes (aparência ao vivo, som/tato, conta, sobre)
    main.dart             # ProviderScope + _Gate (rota por estado de auth)
  test/
```

Novas features (sessão, trilha, passaporte…) entram como pastas-irmãs de `identidade/`.

> **UI provisória.** As telas de identidade têm layout mínimo só para exercitar o
> fluxo de dados. O **design visual** (tema viagem/passaporte — ver
> `docs/referencia_arte.md`) entra depois, por cima deste fluxo que já funciona.

## Rodar localmente

Pré-requisito: o backend rodando (ver `backend/README.md`) e um
emulador/dispositivo.

```bash
cd app
flutter pub get

# Emulador Android alcança o host por 10.0.2.2 (default do config).
# iOS simulator / desktop: use localhost.
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000
```

Entre com o código da turma de demo **DEMO7A** (seed do backend) e um nome.

## Verificação

```bash
flutter analyze
flutter test
```
