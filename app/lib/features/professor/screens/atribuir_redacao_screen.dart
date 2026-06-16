import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_icons.dart';
import '../../../core/widgets/entrance.dart';
import '../../../core/widgets/surface_card.dart';
import '../professor_data.dart';
import '../professor_providers.dart';
import '../widgets/back_bar.dart';

/// **Atribuir redação** (telas §8.2; produto §4.6) — ação **só do professor**
/// (ver≠configurar, §3.11). O professor define **tema + prazo** e a turma recebe;
/// o **aluno** é quem escreve e envia depois (fecha o loop redação→vocabulário).
///
/// Página empurrada; devolve a [RedacaoAtribuicao] criada via `Navigator.pop` —
/// o painel mostra a confirmação. DEMO simula o sucesso (sem backend).
class AtribuirRedacaoScreen extends ConsumerStatefulWidget {
  const AtribuirRedacaoScreen({
    super.key,
    required this.turmaId,
    required this.turmaNome,
  });

  final int turmaId;
  final String turmaNome;

  static const double _maxWidth = 680;

  static Route<RedacaoAtribuicao> route({
    required int turmaId,
    required String turmaNome,
  }) =>
      MaterialPageRoute<RedacaoAtribuicao>(
        builder: (_) =>
            AtribuirRedacaoScreen(turmaId: turmaId, turmaNome: turmaNome),
      );

  @override
  ConsumerState<AtribuirRedacaoScreen> createState() =>
      _AtribuirRedacaoScreenState();
}

class _AtribuirRedacaoScreenState extends ConsumerState<AtribuirRedacaoScreen> {
  final _tema = TextEditingController();
  DateTime? _prazo;

  @override
  void initState() {
    super.initState();
    // Reabilita o botão conforme o tema deixa de ser vazio.
    _tema.addListener(_aoMudar);
  }

  @override
  void dispose() {
    _tema.removeListener(_aoMudar);
    _tema.dispose();
    super.dispose();
  }

  void _aoMudar() => setState(() {});

  bool get _podeEnviar => _tema.text.trim().isNotEmpty;

  Future<void> _escolherPrazo() async {
    final hoje = DateTime.now();
    final escolhido = await showDatePicker(
      context: context,
      initialDate: _prazo ?? hoje,
      firstDate: hoje,
      lastDate: hoje.add(const Duration(days: 365)),
      helpText: 'Prazo de entrega',
    );
    if (!mounted || escolhido == null) return;
    setState(() => _prazo = escolhido);
  }

  Future<void> _atribuir() async {
    final atribuida = await ref.read(atribuirRedacaoProvider.notifier).atribuir(
          turmaId: widget.turmaId,
          tema: _tema.text,
          prazo: _prazo,
        );
    if (!mounted) return;
    if (atribuida != null) {
      Navigator.of(context).pop(atribuida);
    } else {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
            const SnackBar(content: Text('Não consegui atribuir. Tente de novo.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final enviando = ref.watch(atribuirRedacaoProvider).isLoading;

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
                maxWidth: AtribuirRedacaoScreen._maxWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ProfessorBackBar(
                  onBack:
                      enviando ? () {} : () => Navigator.of(context).maybePop(),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(24, 4, 24, 40),
                    children: [
                      Entrance(child: _Cabecalho(turmaNome: widget.turmaNome)),
                      const SizedBox(height: 20),
                      Entrance(
                        delay: const Duration(milliseconds: 60),
                        child: _Formulario(
                          tema: _tema,
                          prazo: _prazo,
                          habilitado: !enviando,
                          onEscolherPrazo: _escolherPrazo,
                          onLimparPrazo: () => setState(() => _prazo = null),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Entrance(
                        delay: const Duration(milliseconds: 120),
                        child: _BotaoAtribuir(
                          enviando: enviando,
                          onPressed: _podeEnviar && !enviando ? _atribuir : null,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'A atribuição libera o envio para os alunos da turma e '
                        'abre a fonte pessoal de vocabulário (§4.6). O aluno é '
                        'quem escreve e envia.',
                        style: AppType.nunito(
                            size: 12.5,
                            weight: FontWeight.w600,
                            color: c.muted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Cabecalho extends StatelessWidget {
  const _Cabecalho({required this.turmaNome});
  final String turmaNome;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Atribuir redação', style: AppType.fredoka(size: 25, color: c.ink)),
        const SizedBox(height: 4),
        Text('Turma $turmaNome · tema e prazo para a turma',
            style: AppType.nunito(
                size: 14, weight: FontWeight.w600, color: c.muted)),
      ],
    );
  }
}

class _Formulario extends StatelessWidget {
  const _Formulario({
    required this.tema,
    required this.prazo,
    required this.habilitado,
    required this.onEscolherPrazo,
    required this.onLimparPrazo,
  });

  final TextEditingController tema;
  final DateTime? prazo;
  final bool habilitado;
  final VoidCallback onEscolherPrazo;
  final VoidCallback onLimparPrazo;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('TEMA', style: AppType.mono(size: 10, color: c.muted)),
          const SizedBox(height: 8),
          TextField(
            controller: tema,
            enabled: habilitado,
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.done,
            maxLength: 200,
            style: AppType.nunito(size: 15, weight: FontWeight.w600, color: c.ink),
            decoration: InputDecoration(
              hintText: 'Ex.: Um herói brasileiro',
              hintStyle: AppType.nunito(
                  size: 15, weight: FontWeight.w500, color: c.muted),
              counterText: '',
              filled: true,
              fillColor: c.paper,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: c.line),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: c.line),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: c.primary, width: 1.6),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text('PRAZO (OPCIONAL)', style: AppType.mono(size: 10, color: c.muted)),
          const SizedBox(height: 8),
          _CampoPrazo(
            prazo: prazo,
            habilitado: habilitado,
            onEscolher: onEscolherPrazo,
            onLimpar: onLimparPrazo,
          ),
        ],
      ),
    );
  }
}

class _CampoPrazo extends StatelessWidget {
  const _CampoPrazo({
    required this.prazo,
    required this.habilitado,
    required this.onEscolher,
    required this.onLimpar,
  });

  final DateTime? prazo;
  final bool habilitado;
  final VoidCallback onEscolher;
  final VoidCallback onLimpar;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final radius = BorderRadius.circular(12);
    final texto =
        prazo == null ? 'Sem prazo' : 'Entrega até ${_formata(prazo!)}';
    return Material(
      color: c.paper,
      borderRadius: radius,
      child: InkWell(
        borderRadius: radius,
        onTap: habilitado ? onEscolher : null,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(color: c.line),
          ),
          child: Row(
            children: [
              Icon(AppIcons.calendar, size: 19, color: c.muted),
              const SizedBox(width: 10),
              Expanded(
                child: Text(texto,
                    style: AppType.nunito(
                        size: 14.5,
                        weight: FontWeight.w600,
                        color: prazo == null ? c.muted : c.ink)),
              ),
              if (prazo != null && habilitado)
                InkWell(
                  borderRadius: BorderRadius.circular(999),
                  onTap: onLimpar,
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(AppIcons.close, size: 18, color: c.muted),
                  ),
                )
              else
                Text('escolher',
                    style: AppType.nunito(
                        size: 13, weight: FontWeight.w700, color: c.primary)),
            ],
          ),
        ),
      ),
    );
  }

  static String _formata(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/'
      '${d.month.toString().padLeft(2, '0')}/${d.year}';
}

class _BotaoAtribuir extends StatelessWidget {
  const _BotaoAtribuir({required this.enviando, required this.onPressed});
  final bool enviando;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SizedBox(
      height: 52,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: c.primary,
          foregroundColor: c.onPrimary,
          disabledBackgroundColor: c.primary.withValues(alpha: 0.4),
          disabledForegroundColor: c.onPrimary.withValues(alpha: 0.8),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
        ),
        child: enviando
            ? SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                    strokeWidth: 2.4, color: c.onPrimary),
              )
            : Text('Atribuir redação',
                style: AppType.nunito(
                    size: 15.5, weight: FontWeight.w800, color: c.onPrimary)),
      ),
    );
  }
}
