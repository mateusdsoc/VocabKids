import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_icons.dart';
import '../../home/home_mapper.dart';
import '../models.dart';
import '../tones.dart';

/// Cartão-postal de um destino (produto §3.10). Conquistado = a **arte real**
/// do destino quando empacotada (mesma resolução da Home/Trilha/Resumo, via
/// [HomeMapper.assetParaCidade]); destinos ainda sem arte (Versalhes, Japão)
/// caem na cena estilizada: degradê na tinta do país + sol + colina. Nos dois
/// casos, a cidade ao pé e um **selo postal** carimbado no canto.
/// Bloqueado = silhueta com cadeado (o destino ainda por conquistar).
///
/// A face é só o conteúdo; cada variação decide a moldura (polaroid, grade,
/// carrossel) ao redor.
class PostcardFace extends StatelessWidget {
  const PostcardFace({
    super.key,
    required this.destino,
    required this.pais,
    this.width = 150,
    this.height = 104,
    this.radius = 12,
  });

  final Destino destino;
  final Pais pais;
  final double width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final br = BorderRadius.circular(radius);

    if (!destino.conquistado) {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: c.muted.withValues(alpha: 0.10),
          borderRadius: br,
          border: Border.all(
              color: c.muted.withValues(alpha: 0.30),
              width: 1,
              strokeAlign: BorderSide.strokeAlignInside),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(painter: _Hatch(c.muted.withValues(alpha: 0.10))),
            ),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(AppIcons.lock,
                      size: height * 0.22, color: c.muted.withValues(alpha: 0.7)),
                  SizedBox(height: height * 0.06),
                  Text('a conquistar',
                      style: AppType.nunito(
                          size: height * 0.085,
                          weight: FontWeight.w800,
                          color: c.muted.withValues(alpha: 0.8))),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final arte = HomeMapper.assetParaCidade(destino.cidade);
    return ClipRRect(
      borderRadius: br,
      child: SizedBox(
        width: width,
        height: height,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (arte != null)
              Image.asset(arte, fit: BoxFit.cover)
            else ...[
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: paisTone(context, pais).scene,
                  ),
                ),
              ),
              CustomPaint(painter: _Scene(height)),
            ],
            // Scrim para legibilidade do texto.
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.center,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x00000000), Color(0x66000000)],
                ),
              ),
            ),
            // Selo postal no canto superior direito.
            Positioned(
              top: height * 0.08,
              right: width * 0.06,
              child: _PostageStamp(size: height * 0.30),
            ),
            // Cidade + país ao pé.
            Positioned(
              left: width * 0.07,
              right: width * 0.07,
              bottom: height * 0.08,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(pais.nome.toUpperCase(),
                      style: AppType.mono(
                          size: height * 0.075,
                          weight: FontWeight.w700,
                          letterSpacing: 1.0,
                          color: Colors.white.withValues(alpha: 0.85))),
                  SizedBox(height: height * 0.01),
                  Text(destino.cidade,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppType.fredoka(
                          size: height * 0.16,
                          color: Colors.white,
                          height: 1.0)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Sol + colina — um lugar abstrato, suave.
class _Scene extends CustomPainter {
  _Scene(this.h);
  final double h;
  @override
  void paint(Canvas canvas, Size size) {
    final sun = Paint()..color = Colors.white.withValues(alpha: 0.22);
    canvas.drawCircle(
        Offset(size.width * 0.30, size.height * 0.34), h * 0.16, sun);

    final hill = Paint()..color = Colors.white.withValues(alpha: 0.12);
    final path = Path()
      ..moveTo(0, size.height)
      ..lineTo(0, size.height * 0.62)
      ..quadraticBezierTo(size.width * 0.30, size.height * 0.42,
          size.width * 0.55, size.height * 0.60)
      ..quadraticBezierTo(size.width * 0.80, size.height * 0.78, size.width,
          size.height * 0.58)
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(path, hill);
  }

  @override
  bool shouldRepaint(_Scene old) => old.h != h;
}

/// Selo de correio: retângulo branco com borda serrilhada + glifo.
class _PostageStamp extends StatelessWidget {
  const _PostageStamp({required this.size});
  final double size;
  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: 0.12,
      child: SizedBox(
        width: size,
        height: size * 1.15,
        child: CustomPaint(
          painter: _Perf(),
          child: Center(
            child: Icon(AppIcons.pin,
                size: size * 0.5, color: Colors.black.withValues(alpha: 0.5)),
          ),
        ),
      ),
    );
  }
}

class _Perf extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final fill = Paint()..color = Colors.white.withValues(alpha: 0.92);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(2)),
      fill,
    );
    // Perfuração: pontilhado nas quatro bordas (efeito de selo serrilhado).
    final dot = Paint()..color = Colors.black.withValues(alpha: 0.12);
    const step = 4.0;
    for (double x = step / 2; x < size.width; x += step) {
      canvas.drawCircle(Offset(x, 1.5), 0.8, dot);
      canvas.drawCircle(Offset(x, size.height - 1.5), 0.8, dot);
    }
    for (double y = step / 2; y < size.height; y += step) {
      canvas.drawCircle(Offset(1.5, y), 0.8, dot);
      canvas.drawCircle(Offset(size.width - 1.5, y), 0.8, dot);
    }
  }

  @override
  bool shouldRepaint(_Perf old) => false;
}

/// Hachura leve para o slot bloqueado.
class _Hatch extends CustomPainter {
  _Hatch(this.color);
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..strokeWidth = 1;
    for (double x = -size.height; x < size.width; x += 9) {
      canvas.drawLine(Offset(x, size.height), Offset(x + size.height, 0), p);
    }
  }

  @override
  bool shouldRepaint(_Hatch old) => old.color != color;
}
