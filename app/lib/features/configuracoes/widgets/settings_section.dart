import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/surface_card.dart';

/// Um bloco de configurações: rótulo micro em caixa-alta (eyebrow mono, como os
/// "campos" do passaporte) sobre um card "papel" que agrupa as linhas, separadas
/// por uma fina divisória — o mesmo desenho de folha de dados do resto do app.
class SettingsSection extends StatelessWidget {
  const SettingsSection({
    super.key,
    required this.label,
    required this.children,
  });

  final String label;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 9),
          child: Text(
            label,
            style: AppType.mono(
                size: 9.5,
                weight: FontWeight.w700,
                letterSpacing: 1.4,
                color: c.muted),
          ),
        ),
        SurfaceCard(
          padding: EdgeInsets.zero,
          child: Column(children: _comDivisorias(c)),
        ),
      ],
    );
  }

  /// Intercala uma divisória hairline entre as linhas (recuada à esquerda para
  /// alinhar com o texto, deixando o "selo" do ícone respirar).
  List<Widget> _comDivisorias(AppColors c) {
    final out = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      if (i > 0) {
        out.add(Divider(
            height: 1, thickness: 1, indent: 62, color: c.line));
      }
      out.add(children[i]);
    }
    return out;
  }
}
