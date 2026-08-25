/// Modelo de `GET /v1/assinatura`, espelhando `assinatura/schemas.py`.
///
/// Cliente fino: quem decide se o gameplay está liberado é sempre o backend
/// (R-AS-1, docs/plano_b2c.md Fase 3) — este modelo é só para mostrar o
/// status na Área do Responsável, nunca para o app decidir sozinho.
library;

class AssinaturaStatus {
  final bool assinante;
  final String? status;
  final DateTime? expiraEm;
  final bool emTrial;

  AssinaturaStatus({
    required this.assinante,
    required this.status,
    required this.expiraEm,
    required this.emTrial,
  });

  factory AssinaturaStatus.fromJson(Map<String, dynamic> j) => AssinaturaStatus(
        assinante: j['assinante'] as bool,
        status: j['status'] as String?,
        expiraEm: j['expira_em'] == null
            ? null
            : DateTime.parse(j['expira_em'] as String),
        emTrial: j['em_trial'] as bool,
      );
}
