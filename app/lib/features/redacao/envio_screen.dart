import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/api_exception.dart';
import '../../core/config.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_icons.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/surface_card.dart';
import 'format.dart';
import 'models.dart';
import 'redacao_mapper.dart';
import 'redacao_providers.dart';
import 'widgets/redacao_background.dart';

/// Tela de envio (produto §4.6 manuscrita): o aluno fotografa a redação. Como
/// uma redação à mão tem 1–2 folhas, aceita **várias fotos** por envio (câmera
/// ou galeria), com remover. O caminho digital (PDF) entra ao lado.
///
/// Upload real (`POST /v1/redacoes/{atribuicao}/envio`, multipart): confirma e
/// devolve o item já como "em análise" para a área. OCR/análise vêm nas fatias
/// seguintes. Em `DEMO`, simula o envio como antes.
class EnvioScreen extends ConsumerStatefulWidget {
  const EnvioScreen({super.key, required this.redacao});

  final Redacao redacao;

  @override
  ConsumerState<EnvioScreen> createState() => _EnvioScreenState();
}

class _Pagina {
  _Pagina({required this.nome, required this.bytes});
  final String nome;
  final Uint8List bytes;
}

class _EnvioScreenState extends ConsumerState<EnvioScreen> {
  final _picker = ImagePicker();
  final List<_Pagina> _paginas = [];
  bool _enviando = false;

  Future<void> _tirarFoto() async {
    try {
      final x = await _picker.pickImage(
          source: ImageSource.camera, imageQuality: 85);
      if (x != null) await _adicionar([x]);
    } on Exception {
      _avisar('Não consegui abrir a câmera.');
    }
  }

  Future<void> _daGaleria() async {
    try {
      final xs = await _picker.pickMultiImage(imageQuality: 85);
      if (xs.isNotEmpty) await _adicionar(xs);
    } on Exception {
      _avisar('Não consegui abrir a galeria.');
    }
  }

  Future<void> _adicionar(List<XFile> arquivos) async {
    final novas = <_Pagina>[];
    for (final x in arquivos) {
      novas.add(_Pagina(nome: x.name, bytes: await x.readAsBytes()));
    }
    if (!mounted) return;
    setState(() => _paginas.addAll(novas));
  }

  void _remover(int i) => setState(() => _paginas.removeAt(i));

  Future<void> _enviar() async {
    setState(() => _enviando = true);

    if (AppConfig.demo) {
      await Future.delayed(const Duration(milliseconds: 1100));
      if (!mounted) return;
      Navigator.of(context).pop(widget.redacao.copyWith(
        status: RedacaoStatus.emAnalise,
        enviadaEm: DateTime.now(),
        paginas: _paginas.length,
      ));
      return;
    }

    try {
      final envio = await ref.read(redacaoRepositoryProvider).enviar(
            widget.redacao.atribuicaoId,
            [for (final p in _paginas) (nome: p.nome, bytes: p.bytes)],
          );
      if (!mounted) return;
      Navigator.of(context).pop(RedacaoMapper.aposEnvio(widget.redacao, envio));
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
    final c = context.colors;
    final temPaginas = _paginas.isNotEmpty;

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
                          if (!temPaginas)
                            _DropZone(onFoto: _tirarFoto, onGaleria: _daGaleria)
                          else
                            _Paginas(
                              paginas: _paginas,
                              onRemover: _remover,
                              onFoto: _tirarFoto,
                              onGaleria: _daGaleria,
                            ),
                          const SizedBox(height: 14),
                          Center(
                            child: TextButton.icon(
                              onPressed: () => _avisar('Envio por PDF — em breve.'),
                              icon: Icon(AppIcons.pdf, size: 18, color: c.muted),
                              label: Text('Tenho a redação digital (PDF)',
                                  style: AppType.nunito(
                                      size: 13,
                                      weight: FontWeight.w800,
                                      color: c.muted)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _EnviarButton(
                    paginas: _paginas.length,
                    enviando: _enviando,
                    onTap: temPaginas && !_enviando ? _enviar : null,
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

/// Estado inicial: zona pontilhada convidando a adicionar fotos.
class _DropZone extends StatelessWidget {
  const _DropZone({required this.onFoto, required this.onGaleria});
  final VoidCallback onFoto;
  final VoidCallback onGaleria;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SurfaceCard(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 28),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: c.primary.withValues(alpha: 0.12),
            ),
            child: Icon(AppIcons.camera, size: 30, color: c.primary),
          ),
          const SizedBox(height: 14),
          Text('Fotografe sua redação',
              style: AppType.fredoka(size: 18, color: c.ink)),
          const SizedBox(height: 6),
          Text(
            'Tire uma foto de cada folha. Capriche na luz\ne deixe o texto bem legível.',
            textAlign: TextAlign.center,
            style: AppType.nunito(
                size: 12.5, weight: FontWeight.w600, color: c.muted, height: 1.4),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _ActionButton(
                  icon: AppIcons.camera,
                  label: 'Tirar foto',
                  filled: true,
                  onTap: onFoto,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ActionButton(
                  icon: AppIcons.gallery,
                  label: 'Galeria',
                  filled: false,
                  onTap: onGaleria,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Grade de páginas adicionadas, com botão de "adicionar mais".
class _Paginas extends StatelessWidget {
  const _Paginas({
    required this.paginas,
    required this.onRemover,
    required this.onFoto,
    required this.onGaleria,
  });

  final List<_Pagina> paginas;
  final ValueChanged<int> onRemover;
  final VoidCallback onFoto;
  final VoidCallback onGaleria;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SurfaceCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${paginas.length} ${paginas.length == 1 ? "PÁGINA" : "PÁGINAS"}',
              style: AppType.mono(
                  size: 9.5,
                  weight: FontWeight.w700,
                  letterSpacing: 1.2,
                  color: c.muted)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (var i = 0; i < paginas.length; i++)
                _Thumb(
                  pagina: paginas[i],
                  numero: i + 1,
                  onRemover: () => onRemover(i),
                ),
              _AddTile(onFoto: onFoto, onGaleria: onGaleria),
            ],
          ),
        ],
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({
    required this.pagina,
    required this.numero,
    required this.onRemover,
  });
  final _Pagina pagina;
  final int numero;
  final VoidCallback onRemover;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SizedBox(
      width: 92,
      height: 116,
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.memory(
              pagina.bytes,
              width: 92,
              height: 116,
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: c.line, width: 1),
              ),
            ),
          ),
          Positioned(
            left: 6,
            bottom: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(7),
              ),
              child: Text('$numero',
                  style: AppType.mono(
                      size: 10, weight: FontWeight.w700, color: Colors.white)),
            ),
          ),
          Positioned(
            right: 4,
            top: 4,
            child: GestureDetector(
              onTap: onRemover,
              child: Container(
                width: 24,
                height: 24,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black.withValues(alpha: 0.55),
                ),
                child: const Icon(AppIcons.close, size: 15, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddTile extends StatelessWidget {
  const _AddTile({required this.onFoto, required this.onGaleria});
  final VoidCallback onFoto;
  final VoidCallback onGaleria;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return InkWell(
      onTap: () => _menu(context),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 92,
        height: 116,
        decoration: BoxDecoration(
          color: c.primary.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: c.primary.withValues(alpha: 0.30), width: 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(AppIcons.add, size: 26, color: c.primary),
            const SizedBox(height: 4),
            Text('Adicionar',
                style: AppType.nunito(
                    size: 11, weight: FontWeight.w800, color: c.primary)),
          ],
        ),
      ),
    );
  }

  void _menu(BuildContext context) {
    final c = context.colors;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: c.paper,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            ListTile(
              leading: Icon(AppIcons.camera, color: c.primary),
              title: Text('Tirar foto',
                  style: AppType.nunito(
                      size: 15, weight: FontWeight.w800, color: c.ink)),
              onTap: () {
                Navigator.pop(ctx);
                onFoto();
              },
            ),
            ListTile(
              leading: Icon(AppIcons.gallery, color: c.primary),
              title: Text('Escolher da galeria',
                  style: AppType.nunito(
                      size: 15, weight: FontWeight.w800, color: c.ink)),
              onTap: () {
                Navigator.pop(ctx);
                onGaleria();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

/// Botão de ação (preenchido = primário, contorno = secundário).
class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.filled,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final bool filled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final radius = BorderRadius.circular(14);
    final fg = filled ? c.onPrimary : c.ink;
    return Material(
      color: filled ? c.primary : Colors.transparent,
      borderRadius: radius,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 13),
          decoration: BoxDecoration(
            borderRadius: radius,
            border: filled ? null : Border.all(color: c.line, width: 1),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: fg),
              const SizedBox(width: 8),
              Text(label,
                  style: AppType.fredoka(
                      size: 14.5, weight: FontWeight.w500, color: fg)),
            ],
          ),
        ),
      ),
    );
  }
}

/// CTA de envio: desabilitado sem páginas; spinner enquanto "envia".
class _EnviarButton extends StatelessWidget {
  const _EnviarButton({
    required this.paginas,
    required this.enviando,
    required this.onTap,
  });
  final int paginas;
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
            Text('Enviando…',
                style: AppType.fredoka(
                    size: 17, weight: FontWeight.w500, color: c.onPrimary)),
          ],
        ),
      );
    }
    final label = paginas == 0
        ? 'Enviar'
        : 'Enviar $paginas ${paginas == 1 ? "página" : "páginas"}';
    return PrimaryButton(
      label: label,
      leadingIcon: AppIcons.sent,
      enabled: onTap != null,
      onTap: onTap,
    );
  }
}
