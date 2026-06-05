import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Camada fina de adaptação por plataforma.
///
/// A identidade visual é própria (não é Material nem Cupertino "de fábrica"),
/// mas alguns **detalhes de interação** denunciam a plataforma. Centralizamos
/// aqui o que adapta o "feel" sem mexer no visual da marca:
///
/// - **Toque sem ripple no iOS** (ver [adaptiveSplashFactory], usado no tema):
///   no Android mantém o ripple; no iOS vira realce/fade, à moda nativa.
/// - **Transição de tela** com *swipe-back* no iOS ([adaptivePageRoute]).
/// - Spinner adaptativo (`CircularProgressIndicator.adaptive`) e haptics ficam
///   nos pontos de uso.
bool get isApplePlatform =>
    defaultTargetPlatform == TargetPlatform.iOS ||
    defaultTargetPlatform == TargetPlatform.macOS;

/// Splash do InkWell por plataforma: ripple no Android, sem onda no iOS
/// (o realce de toque continua, dando o press "à iOS").
InteractiveInkFeatureFactory get adaptiveSplashFactory =>
    isApplePlatform ? NoSplash.splashFactory : InkSparkle.splashFactory;

/// Rota de página adaptativa: [CupertinoPageRoute] no iOS/macOS (com o gesto de
/// arrastar para voltar) e [MaterialPageRoute] no resto.
Route<T> adaptivePageRoute<T>({required WidgetBuilder builder}) {
  return isApplePlatform
      ? CupertinoPageRoute<T>(builder: builder)
      : MaterialPageRoute<T>(builder: builder);
}
