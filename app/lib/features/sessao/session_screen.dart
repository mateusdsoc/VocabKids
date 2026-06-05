import 'package:flutter/material.dart';

import '../../core/widgets/app_icons.dart';
import 'models.dart';
import 'widgets/discovery_card.dart';
import 'widgets/feedback_bar.dart';
import 'widgets/option_tile.dart';
import 'widgets/question_panel.dart';
import 'widgets/report_popover.dart';
import 'widgets/session_background.dart';
import 'widgets/session_cta.dart';
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

  SessionStep get _step => widget.steps[_index];

  void _confirm(SessionQuestion q) {
    final correctIndex = q.options.indexWhere((o) => o.correct);
    final ok = _selected == correctIndex;
    setState(() {
      _outcome = ok ? AnswerOutcome.correct : AnswerOutcome.wrong;
      if (ok) {
        _combo += 1;
      } else {
        _combo = 0;
      }
    });
  }

  void _advance() {
    if (_index >= widget.steps.length - 1) {
      // Fim da sessão → por ora volta. Próximo: Resumo de sessão (3.7).
      Navigator.of(context).maybePop();
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
    return switch (_step) {
      DiscoveryStep(:final card) => _discovery(card),
      QuestionStep(:final question) => _question(question),
    };
  }

  Widget _discovery(SessionDiscovery card) {
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
        SessionCta(
          label: 'Entendi',
          leadingIcon: AppIcons.check,
          onTap: _advance,
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
      return SessionCta(
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
              : 'Esta questão volta no fim da fila.',
          xp: ok ? q.xp : null,
        ),
        const SizedBox(height: 11),
        SessionCta(label: 'Continuar', trailingIcon: AppIcons.arrow, onTap: _advance),
      ],
    );
  }
}
