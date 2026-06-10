import 'package:flutter/material.dart';

import '../../core/platform/adaptive.dart';
import '../../core/widgets/app_icons.dart';
import '../../core/widgets/primary_button.dart';
import '../resumo/models.dart';
import '../resumo/resumo_screen.dart';
import 'models.dart';
import 'widgets/discovery_card.dart';
import 'widgets/feedback_bar.dart';
import 'widgets/option_tile.dart';
import 'widgets/question_panel.dart';
import 'widgets/report_popover.dart';
import 'widgets/session_background.dart';
import 'widgets/session_top_bar.dart';

/// Sessão — núcleo da prática (produto 3.2 / 3.4).
///
/// Hoje roda uma sessão de exemplo ([sampleSession]) com uma máquina de estados
/// local (selecionar → confirmar → feedback → continuar), para validar todos os
/// estados do design. O wiring com `/v1/sessoes` (correção server-side, fila,
/// re-queue do erro) entra depois — ver `design/notas-implementacao.md`.
class SessionScreen extends StatefulWidget {
  const SessionScreen({super.key, this.steps = sampleSession});

  final List<SessionStep> steps;

  @override
  State<SessionScreen> createState() => _SessionScreenState();
}

class _SessionScreenState extends State<SessionScreen> {
  static const _reasons = [
    'A resposta parece errada',
    'Não entendi a palavra',
    'Tem um erro de digitação',
    'Outro',
  ];

  int _index = 0;
  int? _selected;
  AnswerOutcome? _outcome;
  int _combo = 3; // demo: começa com combo aceso, como no mockup
  bool _reportOpen = false;

  /// Erros acumulados por palavra na sessão. No 2º erro da mesma palavra, o
  /// card de descoberta reabre antes da próxima tentativa ("errar é aprender":
  /// dá material para acertar de verdade, sem revelar a resposta).
  final Map<String, int> _wrongByWord = {};

  /// Card a reexibir ao continuar (setado no 2º erro da palavra).
  SessionDiscovery? _reviewCard;

  SessionStep get _step => widget.steps[_index];

  /// Card de descoberta da palavra, procurado nos passos da própria sessão.
  SessionDiscovery? _cardOf(String word) {
    for (final step in widget.steps) {
      if (step is DiscoveryStep && step.card.word == word) return step.card;
    }
    return null;
  }

  void _confirm(SessionQuestion q) {
    final correctIndex = q.options.indexWhere((o) => o.correct);
    final ok = _selected == correctIndex;
    setState(() {
      _outcome = ok ? AnswerOutcome.correct : AnswerOutcome.wrong;
      if (ok) {
        _combo += 1;
      } else {
        _combo = 0;
        final word = q.effectiveWord;
        if (word != null) {
          final wrongs = (_wrongByWord[word] = (_wrongByWord[word] ?? 0) + 1);
          if (wrongs >= 2) {
            _reviewCard = _cardOf(word);
            _wrongByWord[word] = 0; // recomeça a contagem após rever o card
          }
        }
      }
    });
  }

  void _advance() {
    if (_index >= widget.steps.length - 1) {
      // Fim da sessão → Resumo (3.7). pushReplacement: o botão voltar não
      // retorna a uma sessão já encerrada; o Resumo aterrissa na Trilha.
      Navigator.of(context).pushReplacement(
        adaptivePageRoute(
          builder: (_) => const ResumoScreen(summary: SessionSummary.sample),
        ),
      );
      return;
    }
    setState(() {
      _index += 1;
      _selected = null;
      _outcome = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SessionBackground(
        child: SafeArea(
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 18),
                child: Column(
                  children: [
                    SessionTopBar(
                      current: _index + 1,
                      total: widget.steps.length,
                      combo: _combo > 0 ? _combo : null,
                      reportActive: _reportOpen,
                      onClose: () => Navigator.of(context).maybePop(),
                      onReport: () => setState(() => _reportOpen = true),
                    ),
                    const SizedBox(height: 16),
                    Expanded(child: _buildContent()),
                  ],
                ),
              ),
              if (_reportOpen)
                ReportPopover(
                  reasons: _reasons,
                  onClose: () => setState(() => _reportOpen = false),
                  onSelect: (_) {
                    setState(() => _reportOpen = false);
                    ScaffoldMessenger.of(context)
                      ..hideCurrentSnackBar()
                      ..showSnackBar(const SnackBar(
                          content: Text('Obrigado! Vamos revisar essa questão.')));
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    // Interstício: relembrar a palavra (2º erro) antes do próximo passo.
    // O avanço da fila já aconteceu ao sair da questão; aqui só dispensa o card.
    final review = _reviewCard;
    if (review != null && _outcome == null) {
      return _discovery(review,
          onDone: () => setState(() => _reviewCard = null));
    }
    return switch (_step) {
      DiscoveryStep(:final card) => _discovery(card, onDone: _advance),
      QuestionStep(:final question) => _question(question),
    };
  }

  Widget _discovery(SessionDiscovery card, {required VoidCallback onDone}) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: DiscoveryCard(
              card: card,
              onSpeak: () {}, // TODO(áudio): tocar TTS da pronúncia.
            ),
          ),
        ),
        const SizedBox(height: 12),
        PrimaryButton(
          label: 'Entendi',
          leadingIcon: AppIcons.check,
          onTap: onDone,
        ),
      ],
    );
  }

  Widget _question(SessionQuestion q) {
    final answered = _outcome != null;
    final correctIndex = q.options.indexWhere((o) => o.correct);

    return Column(
      children: [
        Expanded(
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  QuestionPanel(question: q),
                  const SizedBox(height: 15),
                  for (var i = 0; i < q.options.length; i++) ...[
                    if (i > 0) const SizedBox(height: 10),
                    OptionTile(
                      option: q.options[i],
                      state: _optionState(i, answered, correctIndex),
                      showConfetti: answered &&
                          _outcome == AnswerOutcome.correct &&
                          i == correctIndex,
                      onTap: answered
                          ? null
                          : () => setState(() => _selected = i),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 13),
        _questionFoot(q, answered),
      ],
    );
  }

  OptionState _optionState(int i, bool answered, int correctIndex) {
    if (!answered) {
      return i == _selected ? OptionState.selected : OptionState.neutral;
    }
    // No acerto, destaca a correta. No erro, marca só a escolhida — a resposta
    // certa NÃO é revelada (a questão volta no fim da fila, produto 3.4).
    if (_outcome == AnswerOutcome.correct) {
      return i == correctIndex ? OptionState.correct : OptionState.neutral;
    }
    return i == _selected ? OptionState.wrong : OptionState.neutral;
  }

  Widget _questionFoot(SessionQuestion q, bool answered) {
    if (!answered) {
      return PrimaryButton(
        label: 'Confirmar',
        enabled: _selected != null,
        onTap: _selected == null ? null : () => _confirm(q),
      );
    }

    final ok = _outcome == AnswerOutcome.correct;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FeedbackBar(
          positive: ok,
          title: ok ? 'Boa!' : 'Quase! Vamos rever isso.',
          subtitle: ok
              ? (_combo >= 2 ? 'Combo ×$_combo — você está voando' : 'Mandou bem!')
              : (_reviewCard != null
                  ? 'Vamos relembrar a palavra antes de seguir.'
                  : 'Esta questão volta no fim da fila.'),
          xp: ok ? q.xp : null,
        ),
        const SizedBox(height: 11),
        PrimaryButton(label: 'Continuar', trailingIcon: AppIcons.arrow, onTap: _advance),
      ],
    );
  }
}
