import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_icons.dart';
import '../layout/breakpoints.dart';

/// Item de navegação da superfície do professor.
class ProfessorNavItem {
  const ProfessorNavItem({required this.icon, required this.label});
  final IconData icon;
  final String label;
}

/// Casca (chrome) das telas do professor: navegação **lateral** em tela larga,
/// **drawer** em janela estreita, e coluna de conteúdo com largura máxima. Reusa
/// os tokens da marca (`context.colors`, `AppType`) — nenhuma cor hardcoded.
class ProfessorShell extends StatelessWidget {
  const ProfessorShell({
    super.key,
    required this.destinations,
    required this.currentIndex,
    required this.onSelect,
    required this.body,
  });

  final List<ProfessorNavItem> destinations;
  final int currentIndex;
  final ValueChanged<int> onSelect;
  final Widget body;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final wide = ProfessorLayout.isWide(context);

    final content = Center(
      child: ConstrainedBox(
        constraints:
            const BoxConstraints(maxWidth: ProfessorLayout.contentMaxWidth),
        child: body,
      ),
    );

    if (wide) {
      return Scaffold(
        backgroundColor: c.bg,
        body: SafeArea(
          child: Row(
            children: [
              _Sidebar(
                destinations: destinations,
                currentIndex: currentIndex,
                onSelect: onSelect,
              ),
              Expanded(child: content),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        backgroundColor: c.paper,
        surfaceTintColor: Colors.transparent,
        foregroundColor: c.ink,
        title: Text('VocabBR Kids · Professor',
            style: AppType.fredoka(size: 18, color: c.ink)),
      ),
      drawer: Drawer(
        backgroundColor: c.paper,
        child: SafeArea(
          child: _SidebarContent(
            destinations: destinations,
            currentIndex: currentIndex,
            onSelect: (i) {
              Navigator.of(context).pop();
              onSelect(i);
            },
          ),
        ),
      ),
      body: SafeArea(child: content),
    );
  }
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({
    required this.destinations,
    required this.currentIndex,
    required this.onSelect,
  });

  final List<ProfessorNavItem> destinations;
  final int currentIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      width: 248,
      decoration: BoxDecoration(
        color: c.paper,
        border: Border(right: BorderSide(color: c.line)),
      ),
      child: _SidebarContent(
        destinations: destinations,
        currentIndex: currentIndex,
        onSelect: onSelect,
      ),
    );
  }
}

class _SidebarContent extends StatelessWidget {
  const _SidebarContent({
    required this.destinations,
    required this.currentIndex,
    required this.onSelect,
  });

  final List<ProfessorNavItem> destinations;
  final int currentIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
          child: Row(
            children: [
              Icon(AppIcons.globe, color: c.primary, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text('VocabBR Kids',
                    style: AppType.fredoka(size: 18, color: c.ink),
                    overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
        ),
        for (var i = 0; i < destinations.length; i++)
          _NavTile(
            item: destinations[i],
            selected: i == currentIndex,
            onTap: () => onSelect(i),
          ),
        const Spacer(),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text('PAINEL DO PROFESSOR',
              style: AppType.mono(size: 10, color: c.muted)),
        ),
      ],
    );
  }
}

class _NavTile extends StatelessWidget {
  const _NavTile({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final ProfessorNavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final radius = BorderRadius.circular(12);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      child: Material(
        color:
            selected ? c.primary.withValues(alpha: 0.12) : Colors.transparent,
        borderRadius: radius,
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Icon(item.icon, size: 20, color: selected ? c.primary : c.muted),
                const SizedBox(width: 12),
                Text(item.label,
                    style: AppType.nunito(
                        size: 14.5,
                        weight: FontWeight.w700,
                        color: selected ? c.ink : c.muted)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Placeholder das telas ainda não implementadas (Redações, Configurações).
class EmBreveProfessor extends StatelessWidget {
  const EmBreveProfessor({super.key, required this.titulo});
  final String titulo;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(AppIcons.clock, size: 40, color: c.muted),
          const SizedBox(height: 12),
          Text('$titulo — em breve',
              style: AppType.fredoka(size: 18, color: c.ink)),
        ],
      ),
    );
  }
}
