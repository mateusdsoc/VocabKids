import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_exception.dart';
import '../../core/config.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_icons.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/surface_card.dart';
import 'format.dart';
import 'models.dart';
import 'redacao_controller.dart';
import 'widgets/redacao_background.dart';

/// Tela de envio (produto §4.6): a criança digita a redação e o app manda o
/// texto pronto pro servidor. `POST /v1/redacoes/{id}/enviar` é **síncrono** —
/// só retorna depois que a triagem de risco e a análise (chamada ao Claude)
/// terminam, então o envio pode levar alguns segundos.
///
/// Manuscrita (fotografar → OCR on-device) fica pra depois: o app ainda não
/// integra ML Kit, então esse caminho aparece desabilitado ("em breve") em
/// vez de fingir que envia algo que não foi lido de verdade.
class EnvioScreen extends ConsumerStatefulWidget {
  const EnvioScreen({super.key, required this.redacao});

  final Redacao redacao;

  @override
  ConsumerState<EnvioScreen> createState() => _EnvioScreenState();
}

class _EnvioScreenState extends ConsumerState<EnvioScreen> {
  final _controller = TextEditingController();
  bool _enviando = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  int get _palavras => _controller.text
      .trim()
      .split(RegExp(r'\s+'))
      .where((w) => w.isNotEmpty)
      .length;

  Future<void> _enviar() async {
    final texto = _controller.text.trim();
    if (texto.isEmpty || _enviando) return;
    setState(() => _enviando = true);

    if (AppConfig.demo) {
      // Sem backend: simula o pipeline síncrono (triagem + análise).
      await Future.delayed(const Duration(milliseconds: 900));
      if (!mounted) return;
      Navigator.of(context).pop('analisada');
      return;
    }

    try {
      final repo = ref.read(redacaoRepositoryProvider);
      final r = await repo.enviar(
        atribuicaoId: widget.redacao.atribuicaoId,
        formato: 'digital',
        textoExtraido: texto,
      );
      if (!mounted) return;
      Navigator.of(context).pop(r.status);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _enviando = false);
      _avisar(e.message);
    }
  }

  void _avisar(String msg) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final temTexto = _controller.text.trim().isNotEmpty;

    final overlay = Theme.of(context).brightness == Brightness.dark
        ? SystemUiOverlayStyle.light
        : SystemUiOverlayStyle.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlay.copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
        body: RedacaoBackground(
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(17, 8, 17, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _Header(onBack: () => Navigator.of(context).maybePop()),
                  const SizedBox(height: 6),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _ContextCard(redacao: widget.redacao),
                          const SizedBox(height: 16),
                          _TextoField(
                            controller: _controller,
                            palavras: _palavras,
                            enabled: !_enviando,
                            onChanged: () => setState(() {}),
                          ),
                          const SizedBox(height: 14),
                          const _ManuscritaEmBreve(),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _EnviarButton(
                    enviando: _enviando,
                    onTap: temTexto && !_enviando ? _enviar : null,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onBack});
  final VoidCallback onBack;

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
                onTap: onBack,
                child: SizedBox(
                  width: 40,
                  height: 40,
                  child: Icon(AppIcons.back, size: 24, color: c.ink),
                ),
              ),
            ),
          ),
          Text('Enviar redação',
              style: AppType.fredoka(size: 19, color: c.ink)),
        ],
      ),
    );
  }
}

/// Contexto: tema + prazo da redação que está sendo respondida.
class _ContextCard extends StatelessWidget {
  const _ContextCard({required this.redacao});
  final Redacao redacao;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final prazo = prazoStatus(redacao.prazo);
    return SurfaceCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('TEMA',
              style: AppType.mono(
                  size: 9,
                  weight: FontWeight.w700,
                  letterSpacing: 1.2,
                  color: c.muted)),
          const SizedBox(height: 4),
          Text(redacao.tema,
              style: AppType.fredoka(size: 18, color: c.ink, height: 1.1)),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(AppIcons.meta,
                  size: 13, color: prazo.urgente ? c.warn : c.muted),
              const SizedBox(width: 6),
              Text(prazo.texto,
                  style: AppType.nunito(
                      size: 12.5,
                      weight: FontWeight.w800,
                      color: prazo.urgente ? c.warn : c.muted)),
            ],
          ),
        ],
      ),
    );
  }
}

/// Campo de digitação da redação, com contagem de palavras (informativa — a
/// rubrica mínima por faixa é validada pelo servidor).
class _TextoField extends StatelessWidget {
  const _TextoField({
    required this.controller,
    required this.palavras,
    required this.enabled,
    required this.onChanged,
  });

  final TextEditingController controller;
  final int palavras;
  final bool enabled;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SurfaceCard(
      padding: const EdgeInsets.all(4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: controller,
            enabled: enabled,
            maxLines: 14,
            minLines: 10,
            onChanged: (_) => onChanged(),
            style: AppType.nunito(
                size: 14.5, weight: FontWeight.w600, color: c.ink, height: 1.5),
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.all(14),
              border: InputBorder.none,
              hintText: 'Escreva sua redação aqui…',
              hintStyle: AppType.nunito(
                  size: 14.5, weight: FontWeight.w600, color: c.muted),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
            child: Align(
              alignment: Alignment.centerRight,
              child: Text('$palavras ${palavras == 1 ? "palavra" : "palavras"}',
                  style: AppType.mono(
                      size: 10.5, weight: FontWeight.w700, color: c.muted)),
            ),
          ),
        ],
      ),
    );
  }
}

/// Caminho manuscrito (fotografar → OCR on-device) — ainda não integrado ao
/// app, então fica visível mas desabilitado em vez de fingir que funciona.
class _ManuscritaEmBreve extends StatelessWidget {
  const _ManuscritaEmBreve();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Center(
      child: TextButton.icon(
        onPressed: () => ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(const SnackBar(
              content: Text(
                  'Enviar foto da redação escrita à mão — em breve.'))),
        icon: Icon(AppIcons.camera, size: 18, color: c.muted),
        label: Text('Prefiro fotografar (em breve)',
            style: AppType.nunito(
                size: 13, weight: FontWeight.w800, color: c.muted)),
      ),
    );
  }
}

/// CTA de envio: desabilitado sem texto; spinner enquanto o servidor analisa.
class _EnviarButton extends StatelessWidget {
  const _EnviarButton({required this.enviando, required this.onTap});
  final bool enviando;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    if (enviando) {
      final radius = BorderRadius.circular(16);
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(15),
        alignment: Alignment.center,
        decoration: BoxDecoration(color: c.primary, borderRadius: radius),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              height: 18,
              width: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2.4,
                valueColor: AlwaysStoppedAnimation(c.onPrimary),
              ),
            ),
            const SizedBox(width: 11),
            Text('Lendo sua redação com carinho…',
                style: AppType.fredoka(
                    size: 15.5, weight: FontWeight.w500, color: c.onPrimary)),
          ],
        ),
      );
    }
    return PrimaryButton(
      label: 'Enviar',
      leadingIcon: AppIcons.sent,
      enabled: onTap != null,
      onTap: onTap,
    );
  }
}
