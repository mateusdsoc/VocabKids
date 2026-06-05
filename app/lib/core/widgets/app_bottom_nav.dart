import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Um destino da barra inferior.
class NavDestination {
  const NavDestination({required this.icon, required this.label});
  final IconData icon;
  final String label;
}

/// Barra de navegação inferior do app — pílula "papel" flutuante sobre um leve
/// degradê que funde com o fundo (como nos mockups). Ícones uniformes, sem FAB.
///
/// Componente puro/reutilizável: recebe destinos, índice atual e callback.
/// Será compartilhada entre Home, Trilha, Praticar, Eventos e Perfil.
class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    super.key,
    required this.destinations,
    required this.currentIndex,
    required this.onSelect,
  });

  final List<NavDestination> destinations;
  final int currentIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [c.bg.withValues(alpha: 0), c.bg],
          stops: const [0, 0.42],
        ),
      ),
      child: Container(
        height: 58,
        decoration: BoxDecoration(
          color: c.paper,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: c.line, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 22,
              offset: const Offset(0, 8),
              spreadRadius: -10,
            ),
          ],
        ),
        child: Row(
          children: [
            for (var i = 0; i < destinations.length; i++)
              Expanded(
                child: _NavItem(
                  destination: destinations[i],
                  selected: i == currentIndex,
                  onTap: () => onSelect(i),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  final NavDestination destination;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final color = selected ? c.primary : c.muted;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(destination.icon, size: 22, color: color),
            const SizedBox(height: 3),
            Text(
              destination.label,
              style: AppType.nunito(size: 9, weight: FontWeight.w800, color: color),
            ),
          ],
        ),
      ),
    );
  }
}
