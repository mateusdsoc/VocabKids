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
import '../sessao/widgets/option_tile.dart';

/// Onboarding (produto 3.5): o primeiro voo do aluno depois do embarque.
///
/// Conduz boas-vindas → como funciona → demonstração (acerto/erro) →
/// diagnóstico → primeira palavra. As **perguntas do diagnóstico ficam como
/// placeholder de propósito**: o conteúdo pedagógico será definido com calma
/// (e com apoio de um professor), então aqui mostramos só a *estrutura* da
/// etapa, marcada como "em preparação". Tudo é mockado — nenhuma rede.
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
    setState(() => _step--);
  }

  void _irParaApp() {
    Navigator.of(context).pushReplacement(
      adaptivePageRoute(builder: (_) => const HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ultima = _step == _total - 1;

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
        3 => const _Diagnostico(),
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

/// Passo 3 — demonstração de acerto e erro (estática). Mostra ao aluno o
/// retorno visual antes de valer: verde no acerto, vermelho (com X) no erro.
class _Demo extends StatelessWidget {
  const _Demo();

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
        const OptionTile(
          option: QuestionOption(key: 'A', text: 'Muito grande, amplo', correct: true),
          state: OptionState.correct,
        ),
        const SizedBox(height: 10),
        const OptionTile(
          option: QuestionOption(key: 'B', text: 'Muito antigo'),
          state: OptionState.wrong,
        ),
      ],
    );
  }
}

/// Passo 4 — diagnóstico. Estrutura visível, **conteúdo em preparação**: as
/// perguntas serão definidas depois (com apoio de um professor). Aqui fica só
/// o esqueleto, marcado, para a demo mostrar a etapa sem inventar questões.
class _Diagnostico extends StatelessWidget {
  const _Diagnostico();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
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
                  _ChipPreparo(c: c),
                ],
              ),
              const SizedBox(height: 12),
              ProgressBar(value: 0.0, color: c.primary),
              const SizedBox(height: 16),
              // Esqueleto de uma questão — sem texto real (conteúdo a definir).
              _SkeletonLine(c: c, widthFactor: 0.85),
              const SizedBox(height: 8),
              _SkeletonLine(c: c, widthFactor: 0.55),
              const SizedBox(height: 16),
              for (var i = 0; i < 3; i++) ...[
                _SkeletonOption(c: c),
                const SizedBox(height: 9),
              ],
              const SizedBox(height: 4),
              Text(
                'As perguntas do diagnóstico serão definidas com cuidado, junto '
                'a um professor. Por enquanto, seguimos para sua primeira palavra.',
                style: AppType.nunito(
                    size: 12, weight: FontWeight.w600, color: c.muted, height: 1.4),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ChipPreparo extends StatelessWidget {
  const _ChipPreparo({required this.c});
  final AppColors c;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: Color.alphaBlend(c.warn.withValues(alpha: 0.16), c.paper),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(AppIcons.clock, size: 12, color: c.warn),
          const SizedBox(width: 4),
          Text('em preparação',
              style: AppType.nunito(
                  size: 10.5, weight: FontWeight.w800, color: c.warn)),
        ],
      ),
    );
  }
}

class _SkeletonLine extends StatelessWidget {
  const _SkeletonLine({required this.c, required this.widthFactor});
  final AppColors c;
  final double widthFactor;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: FractionallySizedBox(
        widthFactor: widthFactor,
        child: Container(
          height: 12,
          decoration: BoxDecoration(
            color: c.track,
            borderRadius: BorderRadius.circular(6),
          ),
        ),
      ),
    );
  }
}

class _SkeletonOption extends StatelessWidget {
  const _SkeletonOption({required this.c});
  final AppColors c;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: c.line, width: 1.5),
      ),
      child: Row(
        children: [
          const SizedBox(width: 12),
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: c.track,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              height: 11,
              margin: const EdgeInsets.only(right: 40),
              decoration: BoxDecoration(
                color: c.track,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
        ],
      ),
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
