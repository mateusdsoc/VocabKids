import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:vocabkids/core/token_store.dart';
import 'package:vocabkids/features/identidade/auth_controller.dart';
import 'package:vocabkids/main.dart';

/// TokenStore em memória — evita shared_preferences (e a rede) no teste.
class _FakeTokenStore implements TokenStore {
  String? _token;

  @override
  Future<String?> read() async => _token;
  @override
  Future<void> save(String token) async => _token = token;
  @override
  Future<void> clear() async => _token = null;
}

void main() {
  testWidgets('sem token guardado, abre na tela de entrada', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tokenStoreProvider.overrideWithValue(_FakeTokenStore()),
        ],
        child: const VocabKidsApp(),
      ),
    );
    // Resolve o build() async do AuthController (token == null → deslogado).
    await tester.pumpAndSettle();

    // Tela de embarque (passe de embarque): marca, os dois campos e o CTA.
    expect(find.text('VocabKids'), findsOneWidget);
    expect(find.text('PASSE DE EMBARQUE'), findsOneWidget);
    expect(find.text('CÓDIGO DA TURMA'), findsOneWidget);
    expect(find.text('SEU APELIDO'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(2));
    expect(find.text('Embarcar'), findsOneWidget);
  });
}
