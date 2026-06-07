import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_icons.dart';
import '../../../core/widgets/surface_card.dart';
import '../models.dart';
import 'perforation.dart';

/// Página de identidade do Passaporte: avatar com anel, nome do viajante, papel,
/// e os "campos" (escola, turma) com a assinatura manuscrita ao pé — desenhada
/// como a folha de dados de um passaporte de verdade, dentro da linguagem da
/// marca (vidro fosco no claro, painel navy no escuro).
class IdentityCard extends StatelessWidget {
  const IdentityCard({super.key, required this.me});

  final Me me;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final turma = me.turma;
    return SurfaceCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _Avatar(initial: _initial(me.nome)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('VIAJANTE',
                        style: AppType.mono(
                            size: 9.5,
                            weight: FontWeight.w700,
                            letterSpacing: 1.2,
                            color: c.muted)),
                    const SizedBox(height: 4),
                    Text(me.nome,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppType.fredoka(
                            size: 23, color: c.ink, height: 1.06)),
                    const SizedBox(height: 8),
                    _RolePill(papel: me.papel),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Perforation(),
          const SizedBox(height: 15),
          _DataField(
            icon: AppIcons.school,
            label: 'ESCOLA',
            value: me.escola?.nome ?? '—',
          ),
          const SizedBox(height: 13),
          _DataField(
            icon: AppIcons.pin,
            label: 'TURMA',
            value: turma == null
                ? '—'
                : '${turma.nome} · ${turma.anoEscolar}º ano',
          ),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(me.nome,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style:
                            AppType.caveat(size: 27, color: c.accentStrong)),
                    Container(
                      height: 1.4,
                      width: 130,
                      color: c.muted.withValues(alpha: 0.35),
                    ),
                    const SizedBox(height: 4),
                    Text('ASSINATURA',
                        style: AppType.mono(
                            size: 8.5,
                            weight: FontWeight.w700,
                            letterSpacing: 1.2,
                            color: c.muted)),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              const _Stamp(),
            ],
          ),
        ],
      ),
    );
  }

  static String _initial(String name) {
    final t = name.trim();
    return t.isEmpty ? '?' : t.characters.first.toUpperCase();
  }
}

/// Avatar quadrado-arredondado com gradiente e anel (igual ao da Home).
class _Avatar extends StatelessWidget {
  const _Avatar({required this.initial});
  final String initial;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.all(2.5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.ring, width: 1.5),
      ),
      child: Container(
        width: 62,
        height: 62,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(17),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: c.avatarGradient,
          ),
        ),
        child: Text(initial,
            style: AppType.fredoka(size: 26, color: Colors.white)),
      ),
    );
  }
}

/// Pílula do papel do usuário (Aluno / Professor…).
class _RolePill extends StatelessWidget {
  const _RolePill({required this.papel});
  final String papel;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final label = papel.isEmpty
        ? 'Aluno'
        : papel[0].toUpperCase() + papel.substring(1).toLowerCase();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: c.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: c.primary.withValues(alpha: 0.30), width: 1),
      ),
      child: Text(label,
          style: AppType.nunito(
              size: 11.5, weight: FontWeight.w800, color: c.primary)),
    );
  }
}

/// Linha de campo do passaporte: ícone + rótulo micro + valor.
class _DataField extends StatelessWidget {
  const _DataField({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 17, color: c.muted),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: AppType.mono(
                      size: 9,
                      weight: FontWeight.w700,
                      letterSpacing: 1.2,
                      color: c.muted)),
              const SizedBox(height: 2),
              Text(value,
                  style: AppType.nunito(
                      size: 15, weight: FontWeight.w800, color: c.ink)),
            ],
          ),
        ),
      ],
    );
  }
}

/// Carimbo decorativo (círculo levemente girado, à moda dos selos do passaporte).
class _Stamp extends StatelessWidget {
  const _Stamp();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Transform.rotate(
      angle: -0.22,
      child: Container(
        width: 58,
        height: 58,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
              color: c.accentStrong.withValues(alpha: 0.55), width: 1.6),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(AppIcons.globe,
                size: 17, color: c.accentStrong.withValues(alpha: 0.7)),
            const SizedBox(height: 1),
            Text('VK',
                style: AppType.mono(
                    size: 9.5,
                    weight: FontWeight.w700,
                    letterSpacing: 1.5,
                    color: c.accentStrong.withValues(alpha: 0.7))),
          ],
        ),
      ),
    );
  }
}
