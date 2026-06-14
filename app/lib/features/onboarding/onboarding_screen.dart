import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/platform/adaptive.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_icons.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/progress_bar.dart';
import '../../core/widgets/surface_card.dart';
import '../home/home_screen.dart';
import '../identidade/widgets/passport_background.dart';
import '../sessao/models.dart';
import '../sessao/widgets/feedback_bar.dart';
import '../sessao/widgets/option_tile.dart';
import '../sessao/widgets/question_panel.dart';
import 'diagnostico_data.dart';

/// Onboarding (produto 3.5): o primeiro voo do aluno depois do embarque.
///
/// Conduz boas-vindas → como funciona → demonstração (acerto/erro) →
/// diagnóstico → primeira palavra. O **diagnóstico** roda como um mini-quiz
/// (telas §2.3): posiciona o aluno "sem ser prova" — o app percorre as questões
/// de exemplo (ver `diagnostico_data.dart`), mas **não calcula nota** nem revela
/// a alternativa correta (cliente fino). Tudo é mockado — nenhuma rede.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, this.nome});

  /// Primeiro nome do aluno (vindo do embarque), usado nas saudações. Opcional:
  /// sem ele, as mensagens caem num tom genérico.
  final String? nome;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _step = 0;

  /// O diagnóstico (passo 3) dirige a si mesmo respondendo questão a questão;
  /// o CTA "Continuar" só aparece quando ele termina.
  bool _diagConcluido = false;

  static const _total = 5;

  String get _primeiroNome {
    final n = widget.nome?.trim();
    if (n == null || n.isEmpty) return '';
    return n.split(' ').first;
  }

  void _avancar() {
    if (_step >= _total - 1) {
      _irParaApp();
      return;
    }
    setState(() => _step++);
  }

  void _voltar() {
    if (_step == 0) return;
    // Voltar para o diagnóstico recomeça a etapa (recria o widget); o CTA
    // some de novo até ele ser concluído outra vez.
    setState(() {
      _step--;
      if (_step == 3) _diagConcluido = false;
    });
  }

  void _irParaApp() {
    Navigator.of(context).pushReplacement(
      adaptivePageRoute(
        builder: (_) => const HomeScreen(),
        settings: const RouteSettings(name: HomeScreen.routeName),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ultima = _step == _total - 1;
    // No diagnóstico, o avanço acontece ao responder; o CTA só surge no fim.
    final ctaOculto = _step == 3 && !_diagConcluido;

    return Scaffold(
      body: PassportBackground(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 12, 22, 20),
                child: Column(
                  children: [
                    _TopBar(
                      step: _step,
                      total: _total,
                      onBack: _step == 0 ? null : _voltar,
                      onSkip: ultima ? null : _irParaApp,
                    ),
                    const SizedBox(height: 14),
                    Expanded(
                      child: SingleChildScrollView(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 220),
                          child: KeyedSubtree(
                            key: ValueKey(_step),
                            child: _buildStep(),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    if (ctaOculto)
                      // Mantém a altura do CTA para o layout não "pular" quando
                      // o botão aparecer ao terminar o diagnóstico.
                      const SizedBox(height: 54)
                    else
                      PrimaryButton(
                        label: _ctaLabel,
                        trailingIcon: ultima ? AppIcons.play : AppIcons.arrow,
                        onTap: _avancar,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String get _ctaLabel => switch (_step) {
        0 => 'Vamos lá',
        1 => 'Entendi',
        2 => 'Beleza',
        3 => 'Continuar',
        _ => 'Começar a praticar',
      };

  Widget _buildStep() => switch (_step) {
        0 => _Boas(nome: _primeiroNome),
        1 => const _Como(),
        2 => const _Demo(),
        3 => _Diagnostico(
            onConcluir: () => setState(() => _diagConcluido = true)),
        _ => _Pronto(nome: _primeiroNome),
      };
}

/// Barra superior: voltar, progresso por pontos e "Pular".
class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.step,
    required this.total,
    this.onBack,
    this.onSkip,
  });

  final int step;
  final int total;
  final VoidCallback? onBack;
  final VoidCallback? onSkip;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(
      children: [
        SizedBox(
          width: 40,
          child: onBack == null
              ? null
              : IconButton(
                  onPressed: onBack,
                  icon: Icon(AppIcons.back, color: c.muted),
                  visualDensity: VisualDensity.compact,
                ),
        ),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < total; i++)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: i == step ? 22 : 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: i <= step ? c.primary : c.track,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
            ],
          ),
        ),
        SizedBox(
          width: 56,
          child: onSkip == null
              ? null
              : TextButton(
                  onPressed: onSkip,
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 36),
                  ),
                  child: Text('Pular',
                      style: AppType.nunito(
                          size: 13, weight: FontWeight.w800, color: c.muted)),
                ),
        ),
      ],
    );
  }
}

/// Cabeçalho comum dos passos: emblema redondo + título + subtítulo.
class _StepHeader extends StatelessWidget {
  const _StepHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      children: [
        Container(
          width: 76,
          height: 76,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [c.primary, Color.lerp(c.primary, Colors.white, 0.32)!],
            ),
            boxShadow: [
              BoxShadow(
                color: c.primary.withValues(alpha: 0.45),
                blurRadius: 22,
                offset: const Offset(0, 12),
                spreadRadius: -8,
              ),
            ],
          ),
          child: Icon(icon, size: 36, color: c.onPrimary),
        ),
        const SizedBox(height: 20),
        Text(title,
            textAlign: TextAlign.center,
            style: AppType.fredoka(
                size: 25, weight: FontWeight.w600, color: c.ink, height: 1.12)),
        const SizedBox(height: 10),
        Text(subtitle,
            textAlign: TextAlign.center,
            style: AppType.nunito(
                size: 14.5, weight: FontWeight.w600, color: c.muted, height: 1.4)),
      ],
    );
  }
}

/// Passo 1 — boas-vindas.
class _Boas extends StatelessWidget {
  const _Boas({required this.nome});
  final String nome;

  @override
  Widget build(BuildContext context) {
    final saudacao = nome.isEmpty ? 'Bem-vindo a bordo!' : 'Bem-vindo, $nome!';
    return _StepHeader(
      icon: AppIcons.flight,
      title: saudacao,
      subtitle:
          'Sua viagem pelo mundo das palavras começa agora. A cada palavra que '
          'você domina, avança no mapa e ganha peças para o seu passaporte.',
    );
  }
}

/// Passo 2 — como funciona (três pontos).
class _Como extends StatelessWidget {
  const _Como();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const _StepHeader(
          icon: AppIcons.passaporte,
          title: 'Como funciona',
          subtitle: 'É rápido e leve — três passos que se repetem a cada sessão.',
        ),
        const SizedBox(height: 22),
        const _ComoItem(
          icon: AppIcons.novaPalavra,
          title: 'Descubra',
          body: 'Conheça palavras novas em cartões com significado e exemplo.',
        ),
        const SizedBox(height: 12),
        const _ComoItem(
          icon: AppIcons.praticar,
          title: 'Pratique',
          body: 'Responda perguntas rápidas para fixar cada palavra.',
        ),
        const SizedBox(height: 12),
        const _ComoItem(
          icon: AppIcons.star,
          title: 'Colecione',
          body: 'Feche destinos e ganhe cartões-postais e carimbos no passaporte.',
        ),
      ],
    );
  }
}

class _ComoItem extends StatelessWidget {
  const _ComoItem({required this.icon, required this.title, required this.body});

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SurfaceCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Color.alphaBlend(c.primary.withValues(alpha: 0.12), c.paper),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 22, color: c.primary),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: AppType.fredoka(
                        size: 16, weight: FontWeight.w600, color: c.ink)),
                const SizedBox(height: 2),
                Text(body,
                    style: AppType.nunito(
                        size: 12.5,
                        weight: FontWeight.w600,
                        color: c.muted,
                        height: 1.32)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Passo 3 — demonstração **roteirizada** de acerto e erro (produto 3.5):
/// roda sozinha, como um filme curto, reusando os componentes reais da Sessão.
/// Primeiro seleciona e acerta (confete + faixa com +XP), depois seleciona e
/// erra (shake gentil + faixa avisando que a pergunta volta — sem punição).
/// O aluno só assiste; nada aqui vale ponto. Replays acontecem naturalmente:
/// cada visita ao passo recria o widget (AnimatedSwitcher com chave por passo).
class _Demo extends StatefulWidget {
  const _Demo();

  @override
  State<_Demo> createState() => _DemoState();
}

class _DemoState extends State<_Demo> {
  static const _certa =
      QuestionOption(key: 'A', text: 'Muito grande, amplo', correct: true);
  static const _errada = QuestionOption(key: 'B', text: 'Muito antigo');

  OptionState _stateA = OptionState.neutral;
  OptionState _stateB = OptionState.neutral;
  bool _showAcerto = false;
  bool _showErro = false;
  final List<Timer> _timers = [];

  @override
  void initState() {
    super.initState();
    // Roteiro: pausa → seleciona A → acerta (confete + XP) → pausa →
    // seleciona B → erra (shake + feedback gentil).
    _aos(500, () => _stateA = OptionState.selected);
    _aos(1100, () {
      _stateA = OptionState.correct;
      _showAcerto = true;
    });
    _aos(2500, () => _stateB = OptionState.selected);
    _aos(3100, () {
      _stateB = OptionState.wrong;
      _showErro = true;
    });
  }

  void _aos(int ms, VoidCallback muda) {
    _timers.add(Timer(Duration(milliseconds: ms), () {
      if (mounted) setState(muda);
    }));
  }

  @override
  void dispose() {
    for (final t in _timers) {
      t.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _StepHeader(
          icon: AppIcons.praticar,
          title: 'Como respondemos',
          subtitle:
              'Acertou, fica verde. Errou, fica vermelho — e a pergunta volta '
              'mais pra frente para você tentar de novo.',
        ),
        const SizedBox(height: 22),
        Text('O que significa “vasto”?',
            style: AppType.fredoka(
                size: 16, weight: FontWeight.w600, color: c.ink)),
        const SizedBox(height: 12),
        OptionTile(
          option: _certa,
          state: _stateA,
          showConfetti: _stateA == OptionState.correct,
        ),
        if (_showAcerto) ...[
          const SizedBox(height: 10),
          const FeedbackBar(
            positive: true,
            title: 'Boa!',
            subtitle: 'Mandou bem!',
            xp: 100,
          ),
        ],
        const SizedBox(height: 10),
        OptionTile(option: _errada, state: _stateB),
        if (_showErro) ...[
          const SizedBox(height: 10),
          const FeedbackBar(
            positive: false,
            title: 'Quase! Vamos rever isso.',
            subtitle: 'A pergunta volta mais pra frente — errar faz parte.',
          ),
        ],
      ],
    );
  }
}

/// Passo 4 — diagnóstico jogável (telas §2.3). Mini-quiz que **posiciona** o
/// aluno na trilha "sem ser prova": percorre as questões de exemplo
/// ([sampleDiagnostico]), uma a uma, com barra de progresso fina. Ao escolher
/// uma alternativa, ela fica **selecionada** e a etapa avança sozinha — **a
/// resposta correta não é revelada** (cliente fino; quem corrige é o servidor).
/// No fim, um cartão amigável fecha a etapa e chama [onConcluir], que libera o
/// CTA "Continuar". Tudo mockado — nenhuma rede.
class _Diagnostico extends StatefulWidget {
  const _Diagnostico({required this.onConcluir});

  /// Chamado uma vez quando a última questão é respondida.
  final VoidCallback onConcluir;

  @override
  State<_Diagnostico> createState() => _DiagnosticoState();
}

class _DiagnosticoState extends State<_Diagnostico> {
  static const _questoes = sampleDiagnostico;

  int _index = 0;
  String? _escolhida;
  bool _concluido = false;
  Timer? _avanco;

  void _responder(String key) {
    if (_escolhida != null) return; // trava: uma escolha por questão
    setState(() => _escolhida = key);
    // Pequena pausa para o aluno ver a seleção, depois avança/fecha.
    _avanco = Timer(const Duration(milliseconds: 480), () {
      if (!mounted) return;
      if (_index >= _questoes.length - 1) {
        setState(() => _concluido = true);
        widget.onConcluir();
      } else {
        setState(() {
          _index++;
          _escolhida = null;
        });
      }
    });
  }

  @override
  void dispose() {
    _avanco?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_concluido) return const _DiagResultado();

    final c = context.colors;
    final q = _questoes[_index].questao;
    final total = _questoes.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _StepHeader(
          icon: AppIcons.meta,
          title: 'Seu ponto de partida',
          subtitle:
              'Algumas perguntas rápidas ajustam a dificuldade ao seu nível. '
              'Sem pressão — é só para começar no lugar certo.',
        ),
        const SizedBox(height: 22),
        SurfaceCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Text('DIAGNÓSTICO',
                      style: AppType.mono(
                          size: 10,
                          weight: FontWeight.w700,
                          letterSpacing: 1.4,
                          color: c.muted)),
                  const Spacer(),
                  Text('Pergunta ${_index + 1} de $total',
                      style: AppType.nunito(
                          size: 11.5, weight: FontWeight.w800, color: c.muted)),
                ],
              ),
              const SizedBox(height: 12),
              ProgressBar(value: (_index + 1) / total, color: c.primary),
              const SizedBox(height: 16),
              // Reaproveita o painel e as alternativas da Sessão; troca apenas
              // a questão a cada passo (chave por índice anima a transição).
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: KeyedSubtree(
                  key: ValueKey(_index),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      QuestionPanel(question: q),
                      const SizedBox(height: 14),
                      for (final opt in q.options) ...[
                        OptionTile(
                          option: opt,
                          state: _escolhida == opt.key
                              ? OptionState.selected
                              : OptionState.neutral,
                          onTap: _escolhida == null
                              ? () => _responder(opt.key)
                              : null,
                        ),
                        if (opt != q.options.last) const SizedBox(height: 9),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Fecho do diagnóstico: cartão amigável de "ponto de partida". **Não** mostra
/// nota nem nível numérico — a estimativa real é do servidor (cliente fino).
class _DiagResultado extends StatelessWidget {
  const _DiagResultado();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _StepHeader(
          icon: AppIcons.check,
          title: 'Tudo certo por aqui!',
          subtitle:
              'Encontramos um bom ponto de partida para você. A dificuldade '
              'vai se ajustando sozinha conforme você avança.',
        ),
        const SizedBox(height: 22),
        SurfaceCard(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color:
                      Color.alphaBlend(c.goal.withValues(alpha: 0.14), c.paper),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(AppIcons.meta, size: 22, color: c.goal),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Text(
                  'Sua trilha já está calibrada. Toque em “Continuar” para '
                  'conhecer sua primeira palavra.',
                  style: AppType.nunito(
                      size: 13,
                      weight: FontWeight.w600,
                      color: c.muted,
                      height: 1.4),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Passo 5 — tudo pronto, primeira palavra à espera.
class _Pronto extends StatelessWidget {
  const _Pronto({required this.nome});
  final String nome;

  @override
  Widget build(BuildContext context) {
    final titulo = nome.isEmpty ? 'Tudo pronto!' : 'Tudo pronto, $nome!';
    return _StepHeader(
      icon: AppIcons.novaPalavra,
      title: titulo,
      subtitle:
          'Sua primeira palavra já está te esperando. Bom embarque — e bons '
          'descobrimentos pelo caminho!',
    );
  }
}
