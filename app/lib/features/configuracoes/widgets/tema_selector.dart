import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_icons.dart';
import '../preferencias.dart';

/// Seletor de aparência ao estilo de um **controle de embarque**: três segmentos
/// (Sistema · Claro · Escuro) numa pílula de vidro, com um cartão que desliza
/// sob a opção ativa. É o elemento de destaque da tela de Configurações — a
/// escolha muda o tema do app ao vivo.
class TemaSelector extends StatelessWidget {
  const TemaSelector({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final TemaPref value;
  final ValueChanged<TemaPref> onChanged;

  static const _opcoes = [
    (TemaPref.sistema, AppIcons.temaSistema, 'Sistema'),
    (TemaPref.claro, AppIcons.temaClaro, 'Claro'),
    (TemaPref.escuro, AppIcons.temaEscuro, 'Escuro'),
  ];

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final index = _opcoes.indexWhere((o) => o.$1 == value);
    // Alinhamento horizontal do indicador: 3 opções → -1, 0, +1.
    final align = Alignment(index <= 0 ? -1.0 : (index - 1).toDouble(), 0);

    return Container(
      height: 64,
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: c.glass,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: c.line, width: 1),
      ),
      child: Stack(
        children: [
          // Cartão deslizante sob a opção ativa.
          AnimatedAlign(
            alignment: align,
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
            child: FractionallySizedBox(
              widthFactor: 1 / _opcoes.length,
              heightFactor: 1,
              child: Container(
                decoration: BoxDecoration(
                  color: c.primary,
                  borderRadius: BorderRadius.circular(13),
                  boxShadow: [
                    BoxShadow(
                      color: c.primary.withValues(alpha: 0.40),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                      spreadRadius: -5,
                    ),
                  ],
                ),
              ),
            ),
          ),
          Row(
            children: [
              for (final (tema, icon, rotulo) in _opcoes)
                Expanded(
                  child: _Segmento(
                    icon: icon,
                    rotulo: rotulo,
                    selecionado: tema == value,
                    onTap: () {
                      if (tema == value) return;
                      HapticFeedback.selectionClick();
                      onChanged(tema);
                    },
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Segmento extends StatelessWidget {
  const _Segmento({
    required this.icon,
    required this.rotulo,
    required this.selecionado,
    required this.onTap,
  });

  final IconData icon;
  final String rotulo;
  final bool selecionado;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final cor = selecionado ? c.onPrimary : c.muted;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20, color: cor),
          const SizedBox(height: 4),
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: AppType.nunito(
                size: 11,
                weight: selecionado ? FontWeight.w800 : FontWeight.w700,
                color: cor),
            child: Text(rotulo),
          ),
        ],
      ),
    );
  }
}
