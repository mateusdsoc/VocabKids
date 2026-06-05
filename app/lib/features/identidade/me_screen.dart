import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_controller.dart';
import 'models.dart';

/// Tela crua de perfil/progresso — confirma que `/v1/me` retorna e desserializa.
///
/// UI PROVISÓRIA — vira a Home-hub (seção 3.7) quando o design entrar.
class MeScreen extends ConsumerWidget {
  const MeScreen({super.key, required this.me});

  final Me me;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = me.progresso;
    return Scaffold(
      appBar: AppBar(
        title: Text('Olá, ${me.nome}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sair',
            onPressed: () => ref.read(authControllerProvider.notifier).sair(),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _linha('Papel', me.papel),
          _linha('Escola', me.escola?.nome ?? '—'),
          _linha('Turma', me.turma == null
              ? '—'
              : '${me.turma!.nome} (${me.turma!.anoEscolar}º ano)'),
          const Divider(height: 32),
          _linha('XP total', '${p.xpTotal}'),
          _linha('Palavras dominadas', '${p.palavrasDominadas}'),
          _linha('Nível de dificuldade', '${p.nivelDificuldadeAtual}'),
          _linha('Nó atual', p.noAtualId?.toString() ?? '—'),
        ],
      ),
    );
  }

  Widget _linha(String rotulo, String valor) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(rotulo, style: const TextStyle(color: Colors.black54)),
            Text(valor, style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      );
}
