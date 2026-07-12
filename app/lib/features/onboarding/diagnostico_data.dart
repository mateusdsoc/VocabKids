/// Banco de exemplo do **diagnóstico** do onboarding (produto 3.5 / telas §2.3).
///
/// Posiciona o aluno na trilha (nível inicial de dificuldade) — "sem ser prova".
/// Aqui as questões são **dados de exemplo** (`const`, só texto, peso desprezível
/// no APK) para o apresentável: o app percorre a etapa de verdade, mas **não
/// calcula nota** nem revela a alternativa correta (cliente fino — o servidor é
/// autoritativo). O `nivel` de cada questão espelha a escada grosso→fino do
/// backend, para o wiring futuro trocar só a *fonte*, não os widgets.
///
/// Espelha `backend/app/diagnostico/schemas.py` (`QuestaoDiagnostico`).
/// Com backend, o passo usa `POST /v1/onboarding/diagnostico` (ver
/// `diagnostico_controller.dart`); este banco fica **só para o demo**.
library;

import '../sessao/models.dart';

/// Uma questão do diagnóstico: a questão em si (reaproveita o modelo da Sessão,
/// para os mesmos widgets renderizarem) + o `nivel` que ela sonda na escada.
class DiagnosticQuestion {
  const DiagnosticQuestion({required this.nivel, required this.questao});

  /// Nível de dificuldade sondado (1–10), na escala do backend.
  final int nivel;

  final SessionQuestion questao;
}

/// Sequência de exemplo do diagnóstico: dificuldade crescente (grosso→fino),
/// cobrindo os quatro tipos de questão. O `correct` fica nos dados para o wiring
/// futuro, mas **não é revelado** na UI do diagnóstico.
const List<DiagnosticQuestion> sampleDiagnostico = [
  DiagnosticQuestion(
    nivel: 1,
    questao: SessionQuestion(
      kind: QuestionKind.significado,
      stem: 'O que significa enorme?',
      highlightWord: 'enorme',
      options: [
        QuestionOption(key: 'A', text: 'Muito grande', correct: true),
        QuestionOption(key: 'B', text: 'Muito feio'),
        QuestionOption(key: 'C', text: 'Muito rápido'),
        QuestionOption(key: 'D', text: 'Muito escuro'),
      ],
    ),
  ),
  DiagnosticQuestion(
    nivel: 2,
    questao: SessionQuestion(
      kind: QuestionKind.sinonimo,
      stem: 'Qual palavra é sinônimo de alegre?',
      highlightWord: 'alegre',
      options: [
        QuestionOption(key: 'A', text: 'Contente', correct: true),
        QuestionOption(key: 'B', text: 'Triste'),
        QuestionOption(key: 'C', text: 'Cansado'),
        QuestionOption(key: 'D', text: 'Bravo'),
      ],
    ),
  ),
  DiagnosticQuestion(
    nivel: 3,
    questao: SessionQuestion(
      kind: QuestionKind.completar,
      stem: 'O cachorro estava _____ depois de correr no parque o dia todo.',
      blank: true,
      options: [
        QuestionOption(key: 'A', text: 'exausto', correct: true),
        QuestionOption(key: 'B', text: 'curioso'),
        QuestionOption(key: 'C', text: 'distraído'),
        QuestionOption(key: 'D', text: 'orgulhoso'),
      ],
    ),
  ),
  DiagnosticQuestion(
    nivel: 4,
    questao: SessionQuestion(
      kind: QuestionKind.julgarUso,
      stem: 'Em qual frase frágil está bem empregada?',
      highlightWord: 'frágil',
      options: [
        QuestionOption(
            key: 'A',
            text: 'O vaso de vidro é muito frágil.',
            boldWord: 'frágil',
            correct: true),
        QuestionOption(
            key: 'B', text: 'Ele correu de forma frágil.', boldWord: 'frágil'),
        QuestionOption(
            key: 'C', text: 'O sol estava frágil no céu.', boldWord: 'frágil'),
        QuestionOption(
            key: 'D', text: 'Comprei um frágil de pão.', boldWord: 'frágil'),
      ],
    ),
  ),
  DiagnosticQuestion(
    nivel: 5,
    questao: SessionQuestion(
      kind: QuestionKind.significado,
      stem: 'O que significa hostil?',
      highlightWord: 'hostil',
      options: [
        QuestionOption(
            key: 'A', text: 'Pouco acolhedor; que demonstra oposição', correct: true),
        QuestionOption(key: 'B', text: 'Muito divertido'),
        QuestionOption(key: 'C', text: 'Cheio de cores'),
        QuestionOption(key: 'D', text: 'Bastante antigo'),
      ],
    ),
  ),
  DiagnosticQuestion(
    nivel: 6,
    questao: SessionQuestion(
      kind: QuestionKind.sinonimo,
      stem: 'Qual palavra é sinônimo de minucioso?',
      highlightWord: 'minucioso',
      options: [
        QuestionOption(key: 'A', text: 'Detalhado', correct: true),
        QuestionOption(key: 'B', text: 'Apressado'),
        QuestionOption(key: 'C', text: 'Confuso'),
        QuestionOption(key: 'D', text: 'Distante'),
      ],
    ),
  ),
  DiagnosticQuestion(
    nivel: 7,
    questao: SessionQuestion(
      kind: QuestionKind.completar,
      stem: 'O discurso foi tão _____ que prendeu a atenção de toda a plateia.',
      blank: true,
      options: [
        QuestionOption(key: 'A', text: 'eloquente', correct: true),
        QuestionOption(key: 'B', text: 'monótono'),
        QuestionOption(key: 'C', text: 'apressado'),
        QuestionOption(key: 'D', text: 'silencioso'),
      ],
    ),
  ),
  DiagnosticQuestion(
    nivel: 8,
    questao: SessionQuestion(
      kind: QuestionKind.significado,
      stem: 'O que significa efêmero?',
      highlightWord: 'efêmero',
      options: [
        QuestionOption(key: 'A', text: 'Que dura pouco tempo; passageiro', correct: true),
        QuestionOption(key: 'B', text: 'Que dura para sempre'),
        QuestionOption(key: 'C', text: 'Que é muito resistente'),
        QuestionOption(key: 'D', text: 'Que é cheio de cor'),
      ],
    ),
  ),
];
