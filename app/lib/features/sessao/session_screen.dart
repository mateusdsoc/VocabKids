import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_exception.dart';
import '../../core/platform/adaptive.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_icons.dart';
import '../../core/widgets/primary_button.dart';
import '../resumo/resumo_screen.dart';
import 'models.dart';
import 'sessao_controller.dart';
import 'widgets/discovery_card.dart';
import 'widgets/feedback_bar.dart';
import 'widgets/option_tile.dart';
import 'widgets/question_panel.dart';
import 'widgets/report_popover.dart';
import 'widgets/session_background.dart';
import 'widgets/session_top_bar.dart';

/// Sessão — núcleo da prática (produto 3.2 / 3.4).
///
/// Cliente fino de verdade: a fila, a correção, o XP e o combo vêm do
/// [SessaoController] (servidor autoritativo; em `DEMO`, a amostra local).
/// Aqui vive só o estado efêmero de interação — alternativa selecionada e o
/// popover de report.
class SessionScreen extends ConsumerStatefulWidget {
  const SessionScreen({super.key});

  @override
  ConsumerState<SessionScreen> createState() => _SessionScreenState();
}

class _SessionScreenState extends ConsumerState<SessionScreen> {
  /// Rótulos do popover (brief visual) → motivo do contrato de report.
  static const _reasons = [
    ('A resposta parece errada', 'resposta_errada'),
    ('Não entendi a palavra', 'nao_entendi'),
    ('Tem um erro de digitação', 'outro'),
    ('Outro', 'outro'),
  ];

  int? _selected;
  bool _reportOpen = false;
  bool _finalizando = false;
  bool _erroFinalizar = false;

  SessaoController get _controller =>
      ref.read(sessaoControllerProvider.notifier);

  Future<void> _confirm() async {
    final selected = _selected;
    if (selected == null) return;
    try {
      await _controller.responder(selected);
    } on ApiException catch (e) {
      if (!mounted) return;
      // 409 = estado dessincronizado (resposta perdida que chegou, sessão
      // encerrada por outra abertura): recomeça com uma sessão nova — o
      // servidor encerra a antiga e nada de progresso se perde.
      if (e.statusCode == 409) {
        _selected = null;
        ref.invalidate(sessaoControllerProvider);
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(const SnackBar(
              content: Text('Essa sessão expirou — montamos uma nova.')));
        return;
      }
      _snackTentarDeNovo();
    } catch (_) {
      if (!mounted) return;
      _snackTentarDeNovo();
    }
  }

  /// A resposta não foi registrada: mantém a seleção e deixa tentar de novo.
  void _snackTentarDeNovo() {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(
          content: Text('Sem conexão agora. Toque em Confirmar de novo.')));
  }

  void _advance() {
    _selected = null;
    _controller.continuar();
  }

  /// Fila vazia e sem feedback pendente → fecha no servidor e vai ao Resumo.
  Future<void> _finalizar() async {
    if (_finalizando) return;
    _finalizando = true;
    try {
      final summary = await _controller.finalizar();
      if (!mounted) return;
      // pushReplacement: o botão voltar não retorna a uma sessão encerrada;
      // o Resumo aterrissa na Trilha.
      Navigator.of(context).pushReplacement(
        adaptivePageRoute(builder: (_) => ResumoScreen(summary: summary)),
      );
    } on ApiException catch (e) {
      _finalizando = false;
      if (!mounted) return;
      if (e.code == 'sessao_encerrada') {
        // O /fim anterior chegou mas a resposta se perdeu: a sessão já está
        // fechada e salva — volta para a tela de origem (que recarrega).
        Navigator.of(context).maybePop();
        return;
      }
      // Sem retry automático: falha persistente viraria martelo no servidor.
      setState(() => _erroFinalizar = true);
    } catch (_) {
      _finalizando = false;
      if (!mounted) return;
      setState(() => _erroFinalizar = true);
    }
  }

  void _report(int index) {
    setState(() => _reportOpen = false);
    // Melhor esforço: o agradecimento não depende da rede (mock na fatia A).
    _controller.reportar(_reasons[index].$2).ignore();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
          const SnackBar(content: Text('Obrigado! Vamos revisar essa questão.')));
  }

  @override
  Widget build(BuildContext context) {
    final estado = ref.watch(sessaoControllerProvider);

    return Scaffold(
      body: SessionBackground(
        child: SafeArea(
          child: estado.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) => _erroAbertura(context),
            data: (s) => _sessao(context, s),
          ),
        ),
      ),
    );
  }

  /// Falha ao montar a sessão (rede/servidor): mensagem gentil + tentar de novo.
  Widget _erroAbertura(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Não deu para começar a praticar',
              textAlign: TextAlign.center,
              style: AppType.fredoka(size: 22, color: c.ink)),
          const SizedBox(height: 8),
          Text('Confira sua conexão e tente de novo.',
              textAlign: TextAlign.center,
              style: AppType.nunito(
                  size: 15, weight: FontWeight.w600, color: c.muted)),
          const SizedBox(height: 20),
          PrimaryButton(
            label: 'Tentar de novo',
            onTap: () => ref.invalidate(sessaoControllerProvider),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: () => Navigator.of(context).maybePop(),
            child: Text('Voltar',
                style: AppType.nunito(
                    size: 15, weight: FontWeight.w700, color: c.muted)),
          ),
        ],
      ),
    );
  }

  /// Falha ao fechar a sessão (as respostas já estão salvas; só o resumo não
  /// veio). Sem retry automático — botão explícito.
  Widget _erroFim(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Quase lá!',
              textAlign: TextAlign.center,
              style: AppType.fredoka(size: 22, color: c.ink)),
          const SizedBox(height: 8),
          Text('Suas respostas estão salvas. Confira a conexão para ver o resumo.',
              textAlign: TextAlign.center,
              style: AppType.nunito(
                  size: 15, weight: FontWeight.w600, color: c.muted)),
          const SizedBox(height: 20),
          PrimaryButton(
            label: 'Ver meu resumo',
            onTap: () {
              setState(() => _erroFinalizar = false);
              _finalizar();
            },
          ),
        ],
      ),
    );
  }

  Widget _sessao(BuildContext context, SessaoEstado s) {
    // Fila drenada e nada em exibição → hora do Resumo (agenda pós-frame para
    // não navegar durante o build).
    if (s.atual == null && s.feedback == null && s.cardRevisao == null) {
      if (_erroFinalizar) return _erroFim(context);
      WidgetsBinding.instance.addPostFrameCallback((_) => _finalizar());
      return const Center(child: CircularProgressIndicator());
    }

    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 18),
          child: Column(
            children: [
              SessionTopBar(
                current: s.numeroAtual,
                total: s.total,
                combo: s.combo > 0 ? s.combo : null,
                reportActive: _reportOpen,
                onClose: () => Navigator.of(context).maybePop(),
                onReport: () => setState(() => _reportOpen = true),
              ),
              const SizedBox(height: 16),
              // Slide/fade curto ao trocar de passo (questão → questão,
              // card → questão). Responder a MESMA questão não troca a
              // chave — o feedback aparece sem transição de tela.
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 280),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0.04, 0),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  ),
                  child: KeyedSubtree(
                    key: ValueKey(_contentKey(s)),
                    child: _buildContent(s),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (_reportOpen)
          ReportPopover(
            reasons: [for (final r in _reasons) r.$1],
            onClose: () => setState(() => _reportOpen = false),
            onSelect: _report,
          ),
      ],
    );
  }

  /// Identidade do conteúdo atual para o AnimatedSwitcher: muda ao avançar de
  /// passo ou ao entrar/sair do card de revisão (2º erro).
  String _contentKey(SessaoEstado s) {
    final review = s.cardRevisao;
    if (review != null && s.feedback == null) {
      return 'review-${s.concluidos}-${review.word}';
    }
    final passo = s.atual;
    final id = switch (passo) {
      QuestionStep(:final question) => 'q-${question.questaoId ?? question.stem.hashCode}',
      DiscoveryStep(:final card) => 'c-${card.word}',
      null => 'fim',
    };
    return 'step-${s.concluidos}-$id';
  }

  Widget _buildContent(SessaoEstado s) {
    // Interstício: relembrar a palavra (2º erro) antes do próximo passo.
    // A fila já avançou no servidor; aqui só se dispensa o card.
    final review = s.cardRevisao;
    if (review != null && s.feedback == null) {
      return _discovery(review, onDone: _controller.dispensarCardRevisao);
    }
    return switch (s.atual) {
      DiscoveryStep(:final card) =>
        _discovery(card, onDone: _controller.avancarCard),
      QuestionStep(:final question) => _question(s, question),
      null => const SizedBox.shrink(),
    };
  }

  Widget _discovery(SessionDiscovery card, {required VoidCallback onDone}) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: DiscoveryCard(card: card),
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

  Widget _question(SessaoEstado s, SessionQuestion q) {
    final answered = s.feedback != null;

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
                      state: _optionState(s, i),
                      showConfetti: answered &&
                          s.feedback!.correto &&
                          i == _selected,
                      onTap: answered || s.respondendo
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
        _questionFoot(s, q),
      ],
    );
  }

  /// No acerto, a escolhida É a correta — destaca. No erro, marca só a
  /// escolhida: a resposta certa NÃO é revelada (a questão volta no fim da
  /// fila, produto 3.4) — e o servidor nem a envia antes disso.
  OptionState _optionState(SessaoEstado s, int i) {
    final feedback = s.feedback;
    if (feedback == null) {
      return i == _selected ? OptionState.selected : OptionState.neutral;
    }
    if (i != _selected) return OptionState.neutral;
    return feedback.correto ? OptionState.correct : OptionState.wrong;
  }

  Widget _questionFoot(SessaoEstado s, SessionQuestion q) {
    final feedback = s.feedback;
    if (feedback == null) {
      return PrimaryButton(
        label: s.respondendo ? 'Enviando…' : 'Confirmar',
        enabled: _selected != null && !s.respondendo,
        onTap: _selected == null || s.respondendo ? null : _confirm,
      );
    }

    final ok = feedback.correto;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FeedbackBar(
          positive: ok,
          title: ok
              ? (feedback.dominou ? 'Palavra dominada!' : 'Boa!')
              : 'Quase! Vamos rever isso.',
          subtitle: ok
              ? (s.combo >= 2 ? 'Combo ×${s.combo} — você está voando' : 'Mandou bem!')
              : (s.cardRevisao != null
                  ? 'Vamos relembrar a palavra antes de seguir.'
                  : 'Esta questão volta no fim da fila.'),
          xp: ok && feedback.xpGanho > 0 ? feedback.xpGanho : null,
        ),
        const SizedBox(height: 11),
        PrimaryButton(
            label: 'Continuar', trailingIcon: AppIcons.arrow, onTap: _advance),
      ],
    );
  }
}
