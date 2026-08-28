import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_icons.dart';
import '../../../core/widgets/surface_card.dart';
import 'passport_background.dart';

/// Tela genérica pra exibir um texto legal dentro do app (Termos de Uso,
/// consentimento LGPD) — aberta por um link a partir das caixas de marcação
/// do cadastro. Sem dependência nova (sem webview/markdown): texto puro,
/// suficiente pro conteúdo condensado de `legal_texts.dart`.
class LegalTextScreen extends StatelessWidget {
  const LegalTextScreen({super.key, required this.titulo, required this.texto});

  final String titulo;
  final String texto;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Scaffold(
      body: PassportBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(17, 8, 17, 0),
                child: SizedBox(
                  height: 44,
                  child: Row(
                    children: [
                      Material(
                        color: c.glass,
                        shape: CircleBorder(side: BorderSide(color: c.line, width: 1)),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: () => Navigator.of(context).maybePop(),
                          child: SizedBox(
                            width: 40,
                            height: 40,
                            child: Icon(AppIcons.back, size: 23, color: c.ink),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          titulo,
                          style: AppType.nunito(
                              size: 15, weight: FontWeight.w800, color: c.ink),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                  child: SurfaceCard(
                    padding: const EdgeInsets.all(18),
                    child: Text(
                      texto,
                      style: AppType.nunito(
                          size: 13.5, weight: FontWeight.w600, color: c.ink, height: 1.5),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
