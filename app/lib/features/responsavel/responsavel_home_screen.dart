import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_exception.dart';
import '../../core/platform/adaptive.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_icons.dart';
import '../../core/widgets/surface_card.dart';
import '../assinatura/assinatura_controller.dart';
import '../assinatura/models.dart';
import '../assinatura/paywall_screen.dart';
import '../identidade/criar_crianca_screen.dart';
import '../identidade/models.dart';
import 'excluir_conta_screen.dart';
import 'responsavel_controller.dart';
import 'resumo_screen.dart';

const _kMaximoPerfis = 3; // espelha LIMITE_PERFIS_POR_CONTA no backend

/// Início da Área do Responsável (produto §08, item 4 + acesso ao resumo por
/// filho): já passou pelo portão do PIN. Reúne os filhos (cada um abre o
/// próprio resumo semanal) e os atalhos de conta — assinatura, adicionar
/// criança, exclusão.
class ResponsavelHomeScreen extends ConsumerWidget {
  const ResponsavelHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(contaProvider);

    final overlay = Theme.of(context).brightness == Brightness.dark
        ? SystemUiOverlayStyle.light
        : SystemUiOverlayStyle.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlay.copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(17, 8, 17, 16),
            child: Column(
              children: [
                _Header(onClose: () => Navigator.of(context).maybePop()),
                Expanded(
                  child: async.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (e, _) => _Erro(
                      mensagem: e is ApiException
                          ? e.message
                          : 'Não deu para carregar a conta.',
                      onRetry: () => ref.invalidate(contaProvider),
                    ),
                    data: (conta) => _Corpo(conta: conta),
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

class _Corpo extends ConsumerWidget {
  const _Corpo({required this.conta});
  final Conta conta;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    return ListView(
      children: [
        SurfaceCard(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: c.accent.withValues(alpha: 0.16),
                ),
                child: Icon(AppIcons.familia, size: 19, color: c.accentStrong),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(conta.nomeResponsavel,
                        style: AppType.nunito(
                            size: 14.5, weight: FontWeight.w800, color: c.ink)),
                    const SizedBox(height: 2),
                    Text(conta.email,
                        style: AppType.nunito(
                            size: 12, weight: FontWeight.w600, color: c.muted)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        _Eyebrow('RESUMO DOS FILHOS'),
        const SizedBox(height: 9),
        for (var i = 0; i < conta.perfis.length; i++) ...[
          if (i > 0) const SizedBox(height: 9),
          _PerfilRow(
            perfil: conta.perfis[i],
            onTap: () => Navigator.of(context).push(
              adaptivePageRoute(
                builder: (_) => ResumoScreen(perfil: conta.perfis[i]),
              ),
            ),
          ),
        ],
        const SizedBox(height: 22),
        _Eyebrow('CONTA'),
        const SizedBox(height: 9),
        _AssinaturaCard(
          onTap: () => Navigator.of(context).push(
            adaptivePageRoute(builder: (_) => const PaywallScreen()),
          ),
        ),
        const SizedBox(height: 9),
        if (conta.perfis.length < _kMaximoPerfis)
          _AtalhoRow(
            icon: AppIcons.add,
            titulo: 'Adicionar criança',
            subtitulo: 'Até $_kMaximoPerfis perfis por conta',
            accent: c.primary,
            onTap: () => Navigator.of(context).push(
              adaptivePageRoute(builder: (_) => const CriarCriancaScreen()),
            ),
          ),
        const SizedBox(height: 9),
        _AtalhoRow(
          icon: AppIcons.delete,
          titulo: 'Excluir conta',
          subtitulo: 'Remove a conta e os dados de todos os perfis',
          accent: c.error,
          onTap: () => Navigator.of(context).push(
            adaptivePageRoute(builder: (_) => const ExcluirContaScreen()),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onClose});
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SizedBox(
      height: 44,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Material(
              color: c.glass,
              shape: CircleBorder(side: BorderSide(color: c.line, width: 1)),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: onClose,
                child: SizedBox(
                  width: 40,
                  height: 40,
                  child: Icon(AppIcons.close, size: 20, color: c.ink),
                ),
              ),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(AppIcons.familia, size: 17, color: c.accentStrong),
              const SizedBox(width: 7),
              Text('Área do Responsável',
                  style: AppType.fredoka(size: 18, color: c.ink)),
            ],
          ),
        ],
      ),
    );
  }
}

class _Erro extends StatelessWidget {
  const _Erro({required this.mensagem, required this.onRetry});
  final String mensagem;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(AppIcons.report, size: 32, color: c.muted),
            const SizedBox(height: 12),
            Text(mensagem,
                textAlign: TextAlign.center,
                style: AppType.nunito(
                    size: 13.5, weight: FontWeight.w700, color: c.muted)),
            const SizedBox(height: 14),
            TextButton(
              onPressed: onRetry,
              child: Text('Tentar de novo',
                  style: AppType.nunito(
                      size: 13.5,
                      weight: FontWeight.w800,
                      color: c.accentStrong)),
            ),
          ],
        ),
      ),
    );
  }
}

class _Eyebrow extends StatelessWidget {
  const _Eyebrow(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Text(text,
          style: AppType.mono(
              size: 9.5,
              weight: FontWeight.w700,
              letterSpacing: 1.2,
              color: c.muted)),
    );
  }
}

class _PerfilRow extends StatelessWidget {
  const _PerfilRow({required this.perfil, required this.onTap});
  final PerfilCrianca perfil;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SurfaceCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: c.avatarGradient,
              ),
            ),
            child: Text(
              perfil.apelido.isEmpty ? '?' : perfil.apelido[0].toUpperCase(),
              style: AppType.fredoka(size: 17, color: Colors.white),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(perfil.apelido,
                    style: AppType.nunito(
                        size: 15, weight: FontWeight.w800, color: c.ink)),
                const SizedBox(height: 2),
                Text('Resumo da semana · ${perfil.faixaEtaria} anos',
                    style: AppType.nunito(
                        size: 11.5, weight: FontWeight.w700, color: c.muted)),
              ],
            ),
          ),
          Icon(AppIcons.chevron, size: 22, color: c.muted),
        ],
      ),
    );
  }
}

class _AssinaturaCard extends ConsumerWidget {
  const _AssinaturaCard({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final async = ref.watch(assinaturaStatusProvider);
    return SurfaceCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: c.goal.withValues(alpha: 0.14),
            ),
            child: Icon(AppIcons.passaporte, size: 19, color: c.goal),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Assinatura',
                    style: AppType.nunito(
                        size: 15, weight: FontWeight.w800, color: c.ink)),
                const SizedBox(height: 2),
                Text(_statusLabel(async),
                    style: AppType.nunito(
                        size: 11.5, weight: FontWeight.w700, color: c.muted)),
              ],
            ),
          ),
          Icon(AppIcons.chevron, size: 22, color: c.muted),
        ],
      ),
    );
  }

  String _statusLabel(AsyncValue<AssinaturaStatus> async) {
    final status = async.value;
    if (async.isLoading || status == null) return 'Carregando…';
    if (!status.assinante) return 'Sem assinatura ativa · toque pra assinar';
    if (status.emTrial) return 'Em período de teste';
    final expira = status.expiraEm;
    return expira == null ? 'Assinatura ativa' : 'Ativa · renova ${_dataCurta(expira)}';
  }
}

class _AtalhoRow extends StatelessWidget {
  const _AtalhoRow({
    required this.icon,
    required this.titulo,
    required this.subtitulo,
    required this.accent,
    required this.onTap,
  });

  final IconData icon;
  final String titulo;
  final String subtitulo;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SurfaceCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accent.withValues(alpha: 0.14),
            ),
            child: Icon(icon, size: 19, color: accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(titulo,
                    style: AppType.nunito(
                        size: 15, weight: FontWeight.w800, color: c.ink)),
                const SizedBox(height: 2),
                Text(subtitulo,
                    style: AppType.nunito(
                        size: 11.5, weight: FontWeight.w700, color: c.muted)),
              ],
            ),
          ),
          Icon(AppIcons.chevron, size: 22, color: c.muted),
        ],
      ),
    );
  }
}

const _meses = [
  'jan', 'fev', 'mar', 'abr', 'mai', 'jun',
  'jul', 'ago', 'set', 'out', 'nov', 'dez',
];

String _dataCurta(DateTime d) => '${d.day} ${_meses[d.month - 1]}';
