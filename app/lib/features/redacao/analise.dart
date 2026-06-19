import 'package:flutter/widgets.dart';

import '../../core/theme/app_colors.dart';

/// Modelo da **redação corrigida** (produto 4.2–4.5).
///
/// Espelha 1:1 o contrato `GET /v1/redacoes/{id}/analise`
/// (`backend/app/redacao/routes.py`, `AnaliseOut`): texto extraído + anotações
/// ancoradas por dimensão + pontos fortes + palavras novas (o gancho do loop
/// redação→vocabulário). Cliente fino: só desserializa e renderiza — quem
/// resolve âncora e calcula o que quer que seja é o servidor.
///
/// Na fatia A o backend devolve dados fixos (mock determinístico) e o app, em
/// modo demo, parte de [AnaliseRedacao.demo]. O *shape* é o mesmo que a fatia C
/// (OCR→LLM) vai preencher, então esta tela não se reescreve depois.
library;

/// Dimensão de análise (produto 4.2). `id` casa com o backend; [rotulo] é o
/// texto da UI; [cor] vem do token de tema (nunca hardcoded).
enum Dimensao {
  vocabulario('vocabulario', 'Vocabulário'),
  acentuacao('acentuacao', 'Acentuação'),
  pontuacao('pontuacao', 'Pontuação'),
  coesaoEstrutura('coesao_estrutura', 'Coesão e estrutura');

  const Dimensao(this.id, this.rotulo);

  final String id;
  final String rotulo;

  static Dimensao fromId(String id) =>
      values.firstWhere((d) => d.id == id, orElse: () => vocabulario);

  /// Cor do grifo desta dimensão no texto anotado (token de marca).
  Color cor(BuildContext context) {
    final c = context.colors;
    return switch (this) {
      Dimensao.vocabulario => c.dimVocabulario,
      Dimensao.acentuacao => c.dimAcentuacao,
      Dimensao.pontuacao => c.dimPontuacao,
      Dimensao.coesaoEstrutura => c.dimCoesao,
    };
  }
}

/// Trecho marcado no texto: `[inicio, fim)` em code points (o servidor já
/// resolveu — o app só recorta).
class Ancora {
  const Ancora({required this.inicio, required this.fim});

  final int inicio;
  final int fim;

  factory Ancora.fromJson(Map<String, dynamic> json) => Ancora(
        inicio: json['inicio'] as int,
        fim: json['fim'] as int,
      );
}

/// Uma observação da correção. Âncoras vazias = **holística** (sem grifo): a
/// tela a mostra como nota geral, não como marca no texto.
class Anotacao {
  const Anotacao({
    required this.id,
    required this.dimensao,
    required this.titulo,
    required this.comentario,
    this.subtipo,
    this.sugestoes = const [],
    this.ancoras = const [],
  });

  final String id;
  final Dimensao dimensao;
  final String? subtipo; // ex.: "superutilizada", "fraca"
  final String titulo;
  final String comentario;
  final List<String> sugestoes;
  final List<Ancora> ancoras;

  bool get holistica => ancoras.isEmpty;

  factory Anotacao.fromJson(Map<String, dynamic> json) => Anotacao(
        id: json['id'] as String,
        dimensao: Dimensao.fromId(json['dimensao'] as String),
        subtipo: json['subtipo'] as String?,
        titulo: json['titulo'] as String,
        comentario: json['comentario'] as String,
        sugestoes: [for (final s in (json['sugestoes'] ?? []) as List) s as String],
        ancoras: [
          for (final a in (json['ancoras'] ?? []) as List)
            Ancora.fromJson(a as Map<String, dynamic>)
        ],
      );
}

/// Palavra nova que a redação "rendeu" ao aluno (produto 3.2): nasce de um
/// gatilho (a palavra fraca/repetida) e entra na fila pessoal da trilha. É o
/// payoff visível do diferencial redação→vocabulário.
class PalavraNova {
  const PalavraNova({
    required this.palavra,
    required this.gatilho,
    required this.anotacaoId,
  });

  final String palavra;
  final String gatilho;
  final String anotacaoId;

  factory PalavraNova.fromJson(Map<String, dynamic> json) => PalavraNova(
        palavra: json['palavra'] as String,
        gatilho: json['gatilho'] as String,
        anotacaoId: json['anotacao_id'] as String,
      );
}

/// A correção completa de uma redação analisada.
class AnaliseRedacao {
  const AnaliseRedacao({
    required this.status,
    required this.textoExtraido,
    required this.dimensoes,
    required this.pontosFortes,
    required this.anotacoes,
    required this.palavrasNovas,
  });

  /// Status do servidor: só `analisada` tem correção; o resto é "em análise".
  final String status;
  final String textoExtraido;
  final List<Dimensao> dimensoes;
  final List<String> pontosFortes;
  final List<Anotacao> anotacoes;
  final List<PalavraNova> palavrasNovas;

  bool get analisada => status == 'analisada';

  /// Anotações com grifo (entram no texto), na ordem em que aparecem no texto.
  List<Anotacao> get ancoradas =>
      anotacoes.where((a) => !a.holistica).toList();

  /// Notas gerais (sem grifo) — comentários holísticos, ex.: coesão.
  List<Anotacao> get holisticas =>
      anotacoes.where((a) => a.holistica).toList();

  /// Quantas marcas (grifos) há nesta dimensão — alimenta o resumo da correção.
  int marcasDe(Dimensao d) => anotacoes
      .where((a) => a.dimensao == d)
      .fold(0, (n, a) => n + a.ancoras.length);

  factory AnaliseRedacao.fromJson(Map<String, dynamic> json) {
    final analise = json['analise'] as Map<String, dynamic>?;
    return AnaliseRedacao(
      status: json['status'] as String,
      textoExtraido: (json['texto_extraido'] as String?) ?? '',
      dimensoes: [
        for (final d in (analise?['dimensoes'] ?? []) as List)
          Dimensao.fromId(d as String)
      ],
      pontosFortes: [
        for (final p in (analise?['pontos_fortes'] ?? []) as List) p as String
      ],
      anotacoes: [
        for (final a in (analise?['anotacoes'] ?? []) as List)
          Anotacao.fromJson(a as Map<String, dynamic>)
      ],
      palavrasNovas: [
        for (final p in (json['palavras_novas'] ?? []) as List)
          PalavraNova.fromJson(p as Map<String, dynamic>)
      ],
    );
  }

  /// Amostra do apresentável (modo demo) — espelha o mock do backend para a
  /// redação "Um herói brasileiro" (id 2). As marcas são declaradas como
  /// (trecho, ocorrência) e resolvidas em offsets aqui mesmo, igual ao servidor,
  /// para os grifos caírem no lugar exato sem números mágicos.
  static AnaliseRedacao? demo(int redacaoId) {
    if (redacaoId != 2) return null; // só a redação 2 está analisada no mock
    return AnaliseRedacao(
      status: 'analisada',
      textoExtraido: _textoHeroi,
      dimensoes: const [
        Dimensao.vocabulario,
        Dimensao.acentuacao,
        Dimensao.pontuacao,
        Dimensao.coesaoEstrutura,
      ],
      pontosFortes: const [
        'Você contou uma história com começo, meio e fim',
        'Usou um exemplo de verdade — o 14-Bis!',
        'Terminou defendendo a sua opinião',
      ],
      anotacoes: [
        for (final a in _anotacoesHeroi)
          Anotacao(
            id: a.id,
            dimensao: a.dimensao,
            subtipo: a.subtipo,
            titulo: a.titulo,
            comentario: a.comentario,
            sugestoes: a.sugestoes,
            ancoras: _resolver(_textoHeroi, a.marcas),
          ),
      ],
      palavrasNovas: const [
        PalavraNova(palavra: 'bastante', gatilho: 'muito', anotacaoId: 'an_1'),
        PalavraNova(palavra: 'inovador', gatilho: 'legal', anotacaoId: 'an_3'),
      ],
    );
  }
}

/// (trecho, n-ésima ocorrência) → offsets — espelha `_resolver_ancoras` do
/// backend. Marca não encontrada é descartada (a anotação vira holística).
List<Ancora> _resolver(String texto, List<(String, int)> marcas) {
  final ancoras = <Ancora>[];
  for (final (trecho, ocorrencia) in marcas) {
    var pos = -1, achados = 0;
    while (achados < ocorrencia) {
      pos = texto.indexOf(trecho, pos + 1);
      if (pos == -1) break;
      achados++;
    }
    if (pos != -1) ancoras.add(Ancora(inicio: pos, fim: pos + trecho.length));
  }
  return ancoras;
}

const _textoHeroi =
    'Meu heroi brasileiro é Santos Dumont. Ele foi um inventor muito '
    'inteligente e muito corajoso, que sonhava em voar pelo céu.\n\n'
    'Santos Dumont criou o 14-Bis, um avião muito legal para a época. Muita '
    'gente duvidava do seu sonho mas ele não desistiu.\n\nEu acho que ele é um '
    'exemplo para todos nós, porque mostrou que tambem podemos realizar nossos '
    'sonhos.';

/// Dado-fonte do mock demo (marcas como trecho+ocorrência, resolvidas acima).
class _AnotacaoMock {
  const _AnotacaoMock({
    required this.id,
    required this.dimensao,
    required this.titulo,
    required this.comentario,
    this.subtipo,
    this.sugestoes = const [],
    this.marcas = const [],
  });
  final String id;
  final Dimensao dimensao;
  final String? subtipo;
  final String titulo;
  final String comentario;
  final List<String> sugestoes;
  final List<(String, int)> marcas;
}

const _anotacoesHeroi = <_AnotacaoMock>[
  _AnotacaoMock(
    id: 'an_1',
    dimensao: Dimensao.vocabulario,
    subtipo: 'superutilizada',
    titulo: '“muito” apareceu 3 vezes',
    comentario: 'Repetir a mesma palavra deixa o texto cansado. '
        'Experimente variar com uma destas:',
    sugestoes: ['bastante', 'extremamente', 'imensamente'],
    marcas: [('muito', 1), ('muito', 2), ('muito', 3)],
  ),
  _AnotacaoMock(
    id: 'an_2',
    dimensao: Dimensao.acentuacao,
    titulo: 'Faltou um acento',
    comentario: '“Heroi” leva acento agudo no “o”.',
    sugestoes: ['herói'],
    marcas: [('heroi', 1)],
  ),
  _AnotacaoMock(
    id: 'an_3',
    dimensao: Dimensao.vocabulario,
    subtipo: 'fraca',
    titulo: '“legal” é uma palavra coringa',
    comentario: 'Ela serve para tudo — e por isso diz pouco. Uma palavra '
        'mais precisa deixa a frase mais forte:',
    sugestoes: ['inovador', 'impressionante'],
    marcas: [('legal', 1)],
  ),
  _AnotacaoMock(
    id: 'an_4',
    dimensao: Dimensao.pontuacao,
    titulo: 'Vírgula antes de “mas”',
    comentario: 'Quando o “mas” liga duas ideias, costuma vir depois de '
        'uma vírgula: “...do seu sonho, mas ele não desistiu.”',
    sugestoes: ['sonho, mas'],
    marcas: [('mas', 1)],
  ),
  _AnotacaoMock(
    id: 'an_5',
    dimensao: Dimensao.acentuacao,
    titulo: 'Faltou um acento',
    comentario: '“Tambem” leva acento agudo no “e”.',
    sugestoes: ['também'],
    marcas: [('tambem', 1)],
  ),
  _AnotacaoMock(
    id: 'an_6',
    dimensao: Dimensao.coesaoEstrutura,
    titulo: 'Começo, meio e fim — muito bem!',
    comentario: 'Seu texto apresenta o herói, conta o que ele fez e fecha '
        'com a sua opinião. Para ficar ainda mais forte, experimente ligar os '
        'parágrafos com palavras de transição, como “por isso” ou “além disso”.',
    marcas: [], // holística: sem grifo
  ),
];
