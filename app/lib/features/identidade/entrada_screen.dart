import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_controller.dart';

/// Tela de entrada por código de turma (acesso provisório da fatia A).
///
/// UI PROVISÓRIA — layout mínimo só para exercitar o fluxo de dados. O design
/// real (tema viagem/passaporte, ver referencia_arte.md) entra depois, por cima
/// deste fluxo que já funciona.
class EntradaScreen extends ConsumerStatefulWidget {
  const EntradaScreen({super.key});

  @override
  ConsumerState<EntradaScreen> createState() => _EntradaScreenState();
}

class _EntradaScreenState extends ConsumerState<EntradaScreen> {
  final _codigo = TextEditingController();
  final _nome = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _codigo.dispose();
    _nome.dispose();
    super.dispose();
  }

  Future<void> _entrar() async {
    if (!_formKey.currentState!.validate()) return;
    await ref.read(authControllerProvider.notifier).entrar(
          codigoTurma: _codigo.text.trim(),
          nome: _nome.text.trim(),
        );
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final carregando = auth.isLoading;

    // Mostra erro de acesso (código inexistente, sem conexão, etc.).
    ref.listen(authControllerProvider, (_, next) {
      if (next.hasError && !next.isLoading) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.error.toString())),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('VocabBR Kids — entrar')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Form(
            key: _formKey,
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.all(24),
              children: [
                TextFormField(
                  controller: _codigo,
                  decoration: const InputDecoration(
                    labelText: 'Código da turma',
                    hintText: 'ex.: DEMO7A',
                  ),
                  textCapitalization: TextCapitalization.characters,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Informe o código' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nome,
                  decoration: const InputDecoration(labelText: 'Seu nome'),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Informe seu nome' : null,
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: carregando ? null : _entrar,
                  child: carregando
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Entrar'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
