/// Modelos de apresentação da Sessão (núcleo da prática).
///
/// Hoje alimentados por uma sessão de exemplo ([sampleSession]); a estrutura
/// espelha o que `/v1/sessoes` entrega para que o wiring com o backend troque
/// só a fonte, não os widgets. Cliente fino: nenhuma pontuação é calculada aqui
/// (o combo/feedback de demo vive na tela; o servidor será autoritativo).
library;

/// Os quatro tipos fixos de questão (produto 3.2). Não rotulamos na UI — o
/// refino removeu a "tarja" do tipo —, mas o tipo guia o enunciado/condução.
enum QuestionKind { significado, sinonimo, completar, julgarUso }

/// Alternativa de múltipla escolha.
class QuestionOption {
  const QuestionOption({
    required this.key,
    required this.text,
    this.correct = false,
    this.boldWord,
  });

  /// Letra exibida no "key" (A, B, C, D).
  final String key;
  final String text;
  final bool correct;

  /// Palavra a destacar em negrito dentro do texto (ex.: "vasto" nas frases).
  final String? boldWord;
}

/// Card de descoberta — primeira vez de uma palavra nova.
class SessionDiscovery {
  const SessionDiscovery({
    required this.word,
    required this.partOfSpeech,
    required this.definition,
    required this.example,
    required this.exampleHighlight,
  });

  final String word;
  final String partOfSpeech;
  final String definition;
  final String example;

  /// Trecho do exemplo a sublinhar (a palavra nova dentro da frase).
  final String exampleHighlight;
}

/// Questão de múltipla escolha.
class SessionQuestion {
  const SessionQuestion({
    required this.kind,
    required this.stem,
    required this.options,
    this.highlightWord,
    this.blank = false,
    this.xp = 100,
  });

  final QuestionKind kind;
  final String stem;
  final List<QuestionOption> options;

  /// Palavra do enunciado marcada inline (sublinhado pontilhado, reabre o card).
  final String? highlightWord;

  /// Quando o enunciado tem uma lacuna ("_____") destacada em vez de palavra.
  final bool blank;

  final int xp;
}

/// Um passo da fila da sessão: ou um card de descoberta, ou uma questão.
sealed class SessionStep {
  const SessionStep();
}

class DiscoveryStep extends SessionStep {
  const DiscoveryStep(this.card);
  final SessionDiscovery card;
}

class QuestionStep extends SessionStep {
  const QuestionStep(this.question);
  final SessionQuestion question;
}

/// Resultado da avaliação de uma questão (server-side no futuro).
enum AnswerOutcome { correct, wrong }

/// Sessão de exemplo que percorre os cinco frames do design (descoberta →
/// significado → sinônimo → julgar uso → completar).
// TODO(backend): substituir por /v1/sessoes (montar) + /proximo + /respostas.
const List<SessionStep> sampleSession = [
  DiscoveryStep(SessionDiscovery(
    word: 'vasto',
    partOfSpeech: 'adjetivo',
    definition: 'Que ocupa muito espaço; muito grande, amplo.',
    example: 'O Brasil tem um território vasto, cheio de paisagens diferentes.',
    exampleHighlight: 'vasto',
  )),
  QuestionStep(SessionQuestion(
    kind: QuestionKind.significado,
    stem: 'O que significa vasto?',
    highlightWord: 'vasto',
    options: [
      QuestionOption(key: 'A', text: 'Muito grande, amplo', correct: true),
      QuestionOption(key: 'B', text: 'Muito antigo'),
      QuestionOption(key: 'C', text: 'Pouco conhecido'),
      QuestionOption(key: 'D', text: 'Cheio de cores'),
    ],
  )),
  QuestionStep(SessionQuestion(
    kind: QuestionKind.sinonimo,
    stem: 'Qual palavra é sinônimo de vasto?',
    highlightWord: 'vasto',
    options: [
      QuestionOption(key: 'A', text: 'Amplo', correct: true),
      QuestionOption(key: 'B', text: 'Estreito'),
      QuestionOption(key: 'C', text: 'Antigo'),
      QuestionOption(key: 'D', text: 'Colorido'),
    ],
  )),
  QuestionStep(SessionQuestion(
    kind: QuestionKind.julgarUso,
    stem: 'Em qual frase vasto está bem empregada?',
    highlightWord: 'vasto',
    options: [
      QuestionOption(
          key: 'A', text: 'O deserto do Saara é vasto.', boldWord: 'vasto', correct: true),
      QuestionOption(
          key: 'B', text: 'Comprei um vasto de leite.', boldWord: 'vasto'),
      QuestionOption(
          key: 'C', text: 'O filme foi vasto e curto.', boldWord: 'vasto'),
      QuestionOption(
          key: 'D', text: 'Ela tem um sorriso vasto.', boldWord: 'vasto'),
    ],
  )),
  QuestionStep(SessionQuestion(
    kind: QuestionKind.completar,
    stem: 'O oceano é tão _____ que não dá para ver o outro lado.',
    blank: true,
    options: [
      QuestionOption(key: 'A', text: 'vasto', correct: true),
      QuestionOption(key: 'B', text: 'raro'),
      QuestionOption(key: 'C', text: 'breve'),
      QuestionOption(key: 'D', text: 'exato'),
    ],
  )),
];
