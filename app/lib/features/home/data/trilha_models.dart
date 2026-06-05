/// Modelos da trilha, espelhando `trilha/schemas.py` (`TrilhaOut`).
/// Apenas desserialização — sem lógica de apresentação (essa vive no mapper).
library;

class TrilhaNoAtual {
  final int destinoId;
  final String destinoNome;
  final String paisNome;
  final int noOrdem;
  final int xpInicio;
  final int xpLimiar;

  TrilhaNoAtual({
    required this.destinoId,
    required this.destinoNome,
    required this.paisNome,
    required this.noOrdem,
    required this.xpInicio,
    required this.xpLimiar,
  });

  factory TrilhaNoAtual.fromJson(Map<String, dynamic> j) => TrilhaNoAtual(
        destinoId: j['destino_id'] as int,
        destinoNome: j['destino_nome'] as String,
        paisNome: j['pais_nome'] as String,
        noOrdem: j['no_ordem'] as int,
        xpInicio: j['xp_inicio'] as int,
        xpLimiar: j['xp_limiar'] as int,
      );
}

class TrilhaDestino {
  final int id;
  final String nome;
  final int ordem;
  final int nosTotal;
  final int nosConcluidos;
  final bool concluido;
  final bool atual;

  TrilhaDestino({
    required this.id,
    required this.nome,
    required this.ordem,
    required this.nosTotal,
    required this.nosConcluidos,
    required this.concluido,
    required this.atual,
  });

  factory TrilhaDestino.fromJson(Map<String, dynamic> j) => TrilhaDestino(
        id: j['id'] as int,
        nome: j['nome'] as String,
        ordem: j['ordem'] as int,
        nosTotal: j['nos_total'] as int,
        nosConcluidos: j['nos_concluidos'] as int,
        concluido: j['concluido'] as bool,
        atual: j['atual'] as bool,
      );
}

class TrilhaPais {
  final int id;
  final String nome;
  final int ordem;
  final bool concluido;
  final List<TrilhaDestino> destinos;

  TrilhaPais({
    required this.id,
    required this.nome,
    required this.ordem,
    required this.concluido,
    required this.destinos,
  });

  factory TrilhaPais.fromJson(Map<String, dynamic> j) => TrilhaPais(
        id: j['id'] as int,
        nome: j['nome'] as String,
        ordem: j['ordem'] as int,
        concluido: j['concluido'] as bool,
        destinos: (j['destinos'] as List)
            .map((e) => TrilhaDestino.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

/// Resposta de `GET /v1/trilha`.
class Trilha {
  final int xpTotal;
  final TrilhaNoAtual? noAtual; // null quando a trilha inteira foi concluída
  final List<TrilhaPais> paises;

  Trilha({required this.xpTotal, required this.noAtual, required this.paises});

  factory Trilha.fromJson(Map<String, dynamic> j) => Trilha(
        xpTotal: j['xp_total'] as int,
        noAtual: j['no_atual'] == null
            ? null
            : TrilhaNoAtual.fromJson(j['no_atual'] as Map<String, dynamic>),
        paises: (j['paises'] as List)
            .map((e) => TrilhaPais.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  /// Todos os destinos achatados na ordem país→destino (a "trilha linear").
  List<TrilhaDestino> get destinosEmOrdem => [
        for (final p in paises) ...p.destinos,
      ];
}
