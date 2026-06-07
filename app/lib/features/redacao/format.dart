/// Formatação de datas/prazos da área de Redação.
library;

const _meses = [
  'jan', 'fev', 'mar', 'abr', 'mai', 'jun',
  'jul', 'ago', 'set', 'out', 'nov', 'dez',
];

/// "20 jun" — data curta para chips e linhas.
String dataCurta(DateTime d) => '${d.day} ${_meses[d.month - 1]}';

/// Texto + urgência do prazo, do ponto de vista de hoje. [urgente] aciona a cor
/// de atenção (âmbar gentil) quando falta pouco ou já passou.
({String texto, bool urgente}) prazoStatus(DateTime? prazo) {
  if (prazo == null) return (texto: 'Sem prazo', urgente: false);
  final agora = DateTime.now();
  final hoje = DateTime(agora.year, agora.month, agora.day);
  final dias = prazo.difference(hoje).inDays;
  if (dias < 0) return (texto: 'Prazo encerrado', urgente: true);
  if (dias == 0) return (texto: 'Vence hoje', urgente: true);
  if (dias == 1) return (texto: 'Vence amanhã', urgente: true);
  return (texto: 'Faltam $dias dias', urgente: dias <= 2);
}
