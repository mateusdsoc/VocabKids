import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_icons.dart';
import '../../../core/widgets/surface_card.dart';
import '../models.dart';
import '../widgets/collection_meter.dart';
import '../widgets/postcard_face.dart';
import '../widgets/postmark.dart';
import '../widgets/seal_badge.dart';

/// Variação A — **Caderno de Viagem**. Scrapbook caloroso: capa de booklet,
/// carimbos espalhados com inclinação, cartões-postais como polaroides colados
/// (fita + legenda manuscrita) e selos como medalhas. Muita Caveat, rotações
/// leves e respiro — a sensação de um diário de bordo.
class JournalView extends StatelessWidget {
  const JournalView({super.key, required this.p});

  final Passaporte p;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(17, 6, 17, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Cover(capa: p.capa),
          const SizedBox(height: 16),
          SurfaceCard(
            padding: const EdgeInsets.all(16),
            child: CollectionMeter(
              conquistadas: p.pecasConquistadas,
              total: p.totalPecas,
            ),
          ),
          const SizedBox(height: 26),
          _SectionTitle(label: 'Carimbos', count: '${p.carimbosConquistados}/${p.paises.length}'),
          const SizedBox(height: 12),
          SurfaceCard(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                for (var i = 0; i < p.paises.length; i++)
                  Carimbo(
                    pais: p.paises[i].pais,
                    conquistado: p.paises[i].carimbo,
                    size: 82,
                    tilt: [-0.12, 0.06, -0.05][i % 3],
                  ),
              ],
            ),
          ),
          const SizedBox(height: 26),
          _SectionTitle(label: 'Cartões-postais', count: '${p.postaisConquistados}/20'),
          const SizedBox(height: 6),
          for (final pais in p.paises) ...[
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.only(left: 2, bottom: 4),
              child: Text('${pais.pais.nome}  ·  ${pais.conquistados}/${pais.total}',
                  style: AppType.nunito(
                      size: 12, weight: FontWeight.w800, color: c.muted)),
            ),
            Wrap(
              spacing: 4,
              runSpacing: 14,
              alignment: WrapAlignment.start,
              children: [
                for (var i = 0; i < pais.destinos.length; i++)
                  _Polaroid(
                    destino: pais.destinos[i],
                    pais: pais.pais,
                    tilt: [-0.04, 0.03, -0.02, 0.045][i % 4],
                  ),
              ],
            ),
          ],
          const SizedBox(height: 26),
          _SectionTitle(label: 'Feitos', count: '${p.selosConquistados}/${p.selos.length}'),
          const SizedBox(height: 14),
          SurfaceCard(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 18),
            child: Wrap(
              spacing: 6,
              runSpacing: 18,
              alignment: WrapAlignment.spaceEvenly,
              children: [
                for (final s in p.selos)
                  SizedBox(width: 92, child: SeloBadge(selo: s)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Capa do booklet: emblema, nome do viajante e assinatura.
class _Cover extends StatelessWidget {
  const _Cover({required this.capa});
  final Capa capa;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final cover = dark
        ? const [Color(0xFF1C2F4B), Color(0xFF0F2034)]
        : [c.primary, Color.lerp(c.primary, Colors.black, 0.22)!];

    return Container(
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: cover,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.30),
            blurRadius: 28,
            offset: const Offset(0, 14),
            spreadRadius: -12,
          ),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: c.accent.withValues(alpha: 0.55), width: 1.4),
        ),
        child: Column(
          children: [
            Text('PASSAPORTE',
                style: AppType.mono(
                    size: 11,
                    weight: FontWeight.w700,
                    letterSpacing: 4,
                    color: c.accent)),
            const SizedBox(height: 16),
            _Emblem(gold: c.accent),
            const SizedBox(height: 16),
            Text(capa.nome,
                textAlign: TextAlign.center,
                style: AppType.fredoka(size: 24, color: Colors.white, height: 1.05)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: c.accent.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: c.accent.withValues(alpha: 0.5)),
              ),
              child: Text('Viajante · Nível ${capa.nivel}',
                  style: AppType.nunito(
                      size: 11.5, weight: FontWeight.w800, color: c.accent)),
            ),
            const SizedBox(height: 18),
            Align(
              alignment: Alignment.centerRight,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(capa.nome,
                      style: AppType.caveat(
                          size: 26, color: Colors.white.withValues(alpha: 0.92))),
                  Container(
                    width: 120,
                    height: 1.2,
                    color: Colors.white.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 3),
                  Text('ASSINATURA',
                      style: AppType.mono(
                          size: 8,
                          weight: FontWeight.w700,
                          letterSpacing: 1.4,
                          color: Colors.white.withValues(alpha: 0.5))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Emblem extends StatelessWidget {
  const _Emblem({required this.gold});
  final Color gold;
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 64,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: gold.withValues(alpha: 0.7), width: 1.6),
      ),
      child: Icon(AppIcons.globe, size: 34, color: gold),
    );
  }
}

/// Polaroid colada: face do postal + fita + legenda manuscrita, levemente torta.
class _Polaroid extends StatelessWidget {
  const _Polaroid({required this.destino, required this.pais, required this.tilt});
  final Destino destino;
  final Pais pais;
  final double tilt;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Transform.rotate(
      angle: tilt,
      child: Container(
        width: 158,
        margin: const EdgeInsets.all(4),
        padding: const EdgeInsets.fromLTRB(7, 7, 7, 5),
        decoration: BoxDecoration(
          color: c.paper,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: c.line, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 12,
              offset: const Offset(0, 6),
              spreadRadius: -6,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Stack(
              alignment: Alignment.topCenter,
              clipBehavior: Clip.none,
              children: [
                PostcardFace(
                  destino: destino,
                  pais: pais,
                  width: 144,
                  height: 96,
                  radius: 4,
                ),
                Positioned(
                  top: -10,
                  child: Transform.rotate(
                    angle: -0.05,
                    child: Container(
                      width: 46,
                      height: 16,
                      color: c.accent.withValues(alpha: 0.28),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              destino.conquistado ? destino.cidade : '? ? ?',
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppType.caveat(
                  size: 18,
                  color: destino.conquistado ? c.ink : c.muted),
            ),
          ],
        ),
      ),
    );
  }
}

/// Título de seção manuscrito + contagem.
class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.label, required this.count});
  final String label;
  final String count;
  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(label, style: AppType.caveat(size: 27, color: c.ink)),
        const SizedBox(width: 10),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Container(height: 1.4, color: c.line),
          ),
        ),
        const SizedBox(width: 10),
        Text(count,
            style: AppType.mono(
                size: 11, weight: FontWeight.w700, color: c.muted)),
      ],
    );
  }
}
