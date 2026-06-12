/// Análise mockada da redação (telas §8.1 — "dados fictícios" para a demo).
///
/// Simula o que o pipeline real (fatia C: OCR → IA → `redacao_analise`)
/// devolverá ao aluno: a **transcrição** do texto com **anotações por
/// dimensão** (produto §4.2/§4.4), pontos fortes, uma nota de estrutura e as
/// palavras novas que entram na trilha (ciclo §4.5). Nada disso é calculado
/// aqui — é uma amostra estática, como se a IA já tivesse corrigido.
///
/// O formato espelha o contrato futuro de `redacao_analise.anotacoes` (JSONB,
/// arquitetura §6): lá as anotações apontarão offsets sobre `texto_extraido`;
/// aqui os trechos já vêm **pré-resolvidos em segmentos** ([TrechoAnalisado]),
/// que é exatamente o que o app renderiza depois de resolver offsets — o
/// wiring troca a fonte, não os widgets.
///
/// Decisão (12/06): o feedback do aluno é **qualitativo** — texto anotado +
/// notas + palavras novas. Sem nota, sem percentual, sem gráfico (princípio
/// anti-boletim, produto §3.7); dashboards/gráficos são do professor (§8.2).
// TODO(backend): substituir por GET /v1/redacoes/{id}/analise quando o motor
// de correção (fatia C) existir.
library;

/// As quatro dimensões de análise do produto (§4.2). Vocabulário, acentuação e
/// pontuação são marcáveis **no trecho exato** (grifo inline); estrutura/coesão
/// é holística — vira **nota**, nunca grifo.
enum DimensaoAnalise { vocabulario, acentuacao, pontuacao, estrutura }

/// Uma anotação da "IA": o achado, a explicação gentil e as sugestões.
class Anotacao {
  const Anotacao({
    required this.dimensao,
    required this.titulo,
    required this.comentario,
    this.sugestoes = const [],
  });

  final DimensaoAnalise dimensao;

  /// Achado em uma linha (ex.: '"muito" apareceu 3 vezes').
  final String titulo;

  /// Explicação no tom do produto: clara e nunca punitiva.
  final String comentario;

  /// Alternativas/correções em chips (ex.: sinônimos, forma acentuada).
  final List<String> sugestoes;
}

/// Um pedaço do texto transcrito: corrido ([anotacao] nula) ou grifado
/// (aponta o índice da anotação em [AnaliseRedacao.anotacoes]).
class TrechoAnalisado {
  const TrechoAnalisado(this.texto, [this.anotacao]);

  final String texto;
  final int? anotacao;
}

/// Palavra que sai da redação e entra na trilha (ciclo central, §4.5):
/// [gatilho] é a palavra repetida/fraca que motivou a recomendação.
class PalavraNova {
  const PalavraNova({required this.palavra, required this.gatilho});

  final String palavra;
  final String gatilho;
}

/// O pacote completo que o aluno vê na tela de resultado.
class AnaliseRedacao {
  const AnaliseRedacao({
    required this.trechos,
    required this.anotacoes,
    required this.pontosFortes,
    required this.estrutura,
    required this.palavrasNovas,
  });

  /// Transcrição do texto, já segmentada (parágrafos separados por '\n\n').
  final List<TrechoAnalisado> trechos;

  /// Anotações grifáveis (vocabulário/acentuação/pontuação), referenciadas
  /// pelos trechos por índice.
  final List<Anotacao> anotacoes;

  /// O que o aluno mandou bem — abre a tela (elogio antes do ajuste).
  final List<String> pontosFortes;

  /// Nota holística de estrutura/coesão (sem grifo — produto §4.2).
  final Anotacao estrutura;

  /// Palavras que entram na trilha a partir desta redação.
  final List<PalavraNova> palavrasNovas;

  /// Amostra: redação "Um herói brasileiro" (a `analisada` de
  /// [Redacao.sample]), com erros plantados em três dimensões marcáveis.
  static const sample = AnaliseRedacao(
    anotacoes: [
      // 0 — vocabulário repetido ("muito" ×3; todos os grifos apontam aqui).
      Anotacao(
        dimensao: DimensaoAnalise.vocabulario,
        titulo: '“muito” apareceu 3 vezes',
        comentario: 'Repetir a mesma palavra deixa o texto cansado. '
            'Experimente variar com uma destas:',
        sugestoes: ['bastante', 'extremamente', 'imensamente'],
      ),
      // 1 — acentuação (herói).
      Anotacao(
        dimensao: DimensaoAnalise.acentuacao,
        titulo: 'Faltou um acento',
        comentario: '“Heroi” leva acento agudo no “o”.',
        sugestoes: ['herói'],
      ),
      // 2 — vocabulário fraco ("legal").
      Anotacao(
        dimensao: DimensaoAnalise.vocabulario,
        titulo: '“legal” é uma palavra coringa',
        comentario: 'Ela serve para tudo — e por isso diz pouco. Uma palavra '
            'mais precisa deixa a frase mais forte:',
        sugestoes: ['inovador', 'impressionante'],
      ),
      // 3 — pontuação (vírgula antes de "mas").
      Anotacao(
        dimensao: DimensaoAnalise.pontuacao,
        titulo: 'Vírgula antes de “mas”',
        comentario: 'Quando o “mas” liga duas ideias, costuma vir depois de '
            'uma vírgula: “...do seu sonho, mas ele não desistiu.”',
        sugestoes: ['sonho, mas'],
      ),
      // 4 — acentuação (também).
      Anotacao(
        dimensao: DimensaoAnalise.acentuacao,
        titulo: 'Faltou um acento',
        comentario: '“Tambem” leva acento agudo no “e”.',
        sugestoes: ['também'],
      ),
    ],
    trechos: [
      TrechoAnalisado('Meu '),
      TrechoAnalisado('heroi', 1),
      TrechoAnalisado(
          ' brasileiro é Santos Dumont. Ele foi um inventor '),
      TrechoAnalisado('muito', 0),
      TrechoAnalisado(' inteligente e '),
      TrechoAnalisado('muito', 0),
      TrechoAnalisado(' corajoso, que sonhava em voar pelo céu.\n\n'),
      TrechoAnalisado('Santos Dumont criou o 14-Bis, um avião '),
      TrechoAnalisado('muito', 0),
      TrechoAnalisado(' '),
      TrechoAnalisado('legal', 2),
      TrechoAnalisado(
          ' para a época. Muita gente duvidava do seu sonho '),
      TrechoAnalisado('mas', 3),
      TrechoAnalisado(' ele não desistiu.\n\n'),
      TrechoAnalisado(
          'Eu acho que ele é um exemplo para todos nós, porque mostrou que '),
      TrechoAnalisado('tambem', 4),
      TrechoAnalisado(' podemos realizar nossos sonhos.'),
    ],
    pontosFortes: [
      'Você contou uma história com começo, meio e fim',
      'Usou um exemplo de verdade — o 14-Bis!',
      'Terminou defendendo a sua opinião',
    ],
    estrutura: Anotacao(
      dimensao: DimensaoAnalise.estrutura,
      titulo: 'Começo, meio e fim — muito bem!',
      comentario: 'Seu texto apresenta o herói, conta o que ele fez e fecha '
          'com a sua opinião. Para ficar ainda mais forte, experimente ligar '
          'os parágrafos com palavras de transição, como “por isso” ou '
          '“além disso”.',
    ),
    palavrasNovas: [
      PalavraNova(palavra: 'bastante', gatilho: 'muito'),
      PalavraNova(palavra: 'inovador', gatilho: 'legal'),
    ],
  );
}
