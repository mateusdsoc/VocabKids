import 'dart:async';
import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_providers.dart';
import '../../core/config.dart';
import '../home/data/trilha_models.dart';
import '../home/home_providers.dart' show trilhaRepositoryProvider;
import '../passaporte/conquista_queue.dart';
import '../passaporte/passaporte_providers.dart'
    show passaporteRepositoryProvider;
import '../resumo/models.dart';
import 'data/sessao_models.dart';
import 'data/sessao_repository.dart';
import 'models.dart';
import 'sessao_mapper.dart';

final sessaoRepositoryProvider = Provider<SessaoRepository>(
  (ref) => SessaoRepository(ref.watch(apiClientProvider)),
);

/// O que a tela lê a cada frame. Imutável; os acumuladores do resumo vivem no
/// controller (não guiam a UI da sessão).
class SessaoEstado {
  const SessaoEstado({
    this.sessaoId,
    required this.fila,
    this.offset = 0,
    this.concluidos = 0,
    this.incrementoPendente = 0,
    this.combo = 0,
    this.feedback,
    this.passoEmFeedback,
    this.cardRevisao,
    this.respondendo = false,
  });

  /// `null` em demo (não há sessão no servidor).
  final int? sessaoId;

  /// Passos pendentes, na ordem do servidor (demo: ordem da amostra).
  final List<SessionStep> fila;

  /// Passos de [fila] já consumidos localmente sem ida ao servidor (cards
  /// dispensados; em demo, também questões). A cada resposta o servidor
  /// devolve a fila nova e o offset volta a zero.
  final int offset;

  /// Slots concluídos — alimenta o "N de M" do topo.
  final int concluidos;

  /// Consumo já confirmado pelo servidor, aplicado a [concluidos] só no
  /// "Continuar": durante o feedback o placar continua no passo respondido.
  final int incrementoPendente;

  /// Combo por sessão — verdade do servidor após cada resposta.
  final int combo;

  /// Resultado da última resposta, exibido até "Continuar". `null` = nenhuma
  /// resposta pendente de feedback.
  final RespostaFeedback? feedback;

  /// A questão respondida, exibida durante o feedback (a fila do servidor já
  /// avançou por baixo).
  final SessionStep? passoEmFeedback;

  /// Card a relembrar antes do próximo passo (2º erro na mesma palavra —
  /// "errar é aprender": material para acertar, sem revelar a resposta).
  final SessionDiscovery? cardRevisao;

  /// Trava anti toque-duplo enquanto a resposta viaja ao servidor.
  final bool respondendo;

  SessionStep? get atual => feedback != null && passoEmFeedback != null
      ? passoEmFeedback
      : (offset < fila.length ? fila[offset] : null);

  int get pendentes => fila.length - offset;

  /// Total exibido: estável durante o feedback e no erro (a questão volta ao
  /// fim da própria fila).
  int get total => concluidos + incrementoPendente + pendentes;

  /// Número do passo em foco (1-based), saturado no total ao fechar a fila.
  int get numeroAtual => concluidos + 1 > total ? total : concluidos + 1;

  SessaoEstado copyWith({
    List<SessionStep>? fila,
    int? offset,
    int? concluidos,
    int? incrementoPendente,
    int? combo,
    RespostaFeedback? feedback,
    bool limparFeedback = false,
    SessionStep? passoEmFeedback,
    SessionDiscovery? cardRevisao,
    bool limparCardRevisao = false,
    bool? respondendo,
  }) =>
      SessaoEstado(
        sessaoId: sessaoId,
        fila: fila ?? this.fila,
        offset: offset ?? this.offset,
        concluidos: concluidos ?? this.concluidos,
        incrementoPendente: incrementoPendente ?? this.incrementoPendente,
        combo: combo ?? this.combo,
        feedback: limparFeedback ? null : (feedback ?? this.feedback),
        passoEmFeedback:
            limparFeedback ? null : (passoEmFeedback ?? this.passoEmFeedback),
        cardRevisao:
            limparCardRevisao ? null : (cardRevisao ?? this.cardRevisao),
        respondendo: respondendo ?? this.respondendo,
      );
}

/// Resultado apresentável de uma resposta (fatos do servidor; em demo,
/// calculado localmente sobre a amostra).
class RespostaFeedback {
  const RespostaFeedback({
    required this.correto,
    required this.xpGanho,
    required this.dominou,
  });

  final bool correto;
  final int xpGanho;
  final bool dominou;
}

/// Ciclo de vida de uma sessão de prática (produto 3.2/3.4), espelhando o
/// contrato server-side:
///
/// 1. [build] abre a sessão (`POST /sessoes`) e captura o snapshot da trilha
///    (contexto do Resumo: cidade/lição/teto de XP);
/// 2. [responder] corrige no servidor e **rende a fila devolvida** — a
///    intercalação do erro é dele, o app só renderiza;
/// 3. [finalizar] fecha (`/fim`) e monta o [SessionSummary].
///
/// Em `AppConfig.demo` tudo roda local sobre [sampleSession], preservando o
/// fluxo de design (combo aceso, conquista do Rio no fim).
class SessaoController extends AutoDisposeAsyncNotifier<SessaoEstado> {
  SessaoRepository get _repo => ref.read(sessaoRepositoryProvider);

  /// Card de cada palavra vista na sessão, para o interstício de revisão.
  /// Palavras de revisão não trazem card na fila — nesse caso não há
  /// interstício (mesmo comportamento da fatia A; pendência nas notas).
  final Map<String, SessionDiscovery> _cards = {};

  /// Erros acumulados por palavra (interstício no 2º erro).
  final Map<String, int> _erros = {};

  /// Progresso por palavra acumulado das respostas (alimenta o Resumo).
  final Map<int, _ProgressoPalavra> _palavras = {};

  /// Colecionáveis ganhos na sessão (teaser do Resumo).
  final List<RecompensaDto> _recompensas = [];

  /// Snapshot da trilha na abertura — contexto do Resumo. A cidade/lição
  /// exibidas são as da lição **jogada**, mesmo se um nó for cruzado no meio.
  Trilha? _trilha;

  @override
  Future<SessaoEstado> build() async {
    if (AppConfig.demo) {
      _guardarCards(sampleSession);
      // Demo começa com combo aceso, como no mockup.
      return SessaoEstado(fila: List.of(sampleSession), combo: 3);
    }

    // Arma a persistência do reveal antes de qualquer conquista desta sessão:
    // o caminho Resumo → teaser → Modo Conquista pode tocar sem nunca passar
    // pelo Passaporte, e ainda assim o "visto" precisa chegar ao servidor.
    ref.read(passaporteRepositoryProvider);

    // Uma viagem só de cada lado, em paralelo: a fila vem em lote e a trilha
    // dá o contexto do Resumo sem chamada extra no fim.
    final (aberta, trilha) = await (
      _repo.abrir(),
      ref.read(trilhaRepositoryProvider).carregar(),
    ).wait;

    _trilha = trilha;
    final fila = SessaoMapper.stepsDe(aberta.slots);
    _guardarCards(fila);
    return SessaoEstado(sessaoId: aberta.sessaoId, fila: fila);
  }

  void _guardarCards(List<SessionStep> passos) {
    for (final passo in passos) {
      if (passo is DiscoveryStep) _cards[passo.card.word] = passo.card;
    }
  }

  /// Card de descoberta lido ("Entendi"): consumo local, sem ida ao servidor —
  /// o backend poda o card da fila na resposta da 1ª questão da palavra.
  void avancarCard() {
    final s = state.requireValue;
    if (s.atual is! DiscoveryStep) return;
    state = AsyncData(
        s.copyWith(offset: s.offset + 1, concluidos: s.concluidos + 1));
  }

  /// Dispensa o interstício de revisão (2º erro) e segue a fila.
  void dispensarCardRevisao() {
    state = AsyncData(state.requireValue.copyWith(limparCardRevisao: true));
  }

  /// Responde a questão atual com a opção de índice [opcaoIndex].
  /// Lança [ApiException] em falha de rede — a tela mantém a seleção e
  /// oferece tentar de novo (a resposta não foi registrada).
  Future<void> responder(int opcaoIndex) async {
    final s = state.requireValue;
    final passo = s.atual;
    if (passo is! QuestionStep || s.respondendo || s.feedback != null) return;
    final questao = passo.question;

    if (AppConfig.demo) {
      _responderDemo(s, questao, opcaoIndex);
      return;
    }

    state = AsyncData(s.copyWith(respondendo: true));
    final RespostaDto r;
    try {
      r = await _repo.responder(
        sessaoId: s.sessaoId!,
        questaoId: questao.questaoId!,
        opcao: questao.options[opcaoIndex].text,
      );
    } catch (_) {
      state = AsyncData(s.copyWith(respondendo: false));
      rethrow;
    }

    _acumular(questao, r);
    state = AsyncData(s.copyWith(
      // A fila devolvida é a verdade: cards vistos podados e, no erro, o
      // retry já reposicionado no fim.
      fila: SessaoMapper.stepsDe(r.fila),
      offset: 0,
      incrementoPendente: math.max(0, s.pendentes - r.fila.length),
      combo: r.comboAtual,
      respondendo: false,
      feedback: RespostaFeedback(
        correto: r.correto,
        xpGanho: r.xpGanho,
        dominou: r.dominou,
      ),
      passoEmFeedback: passo,
      limparCardRevisao: r.correto,
      cardRevisao: r.correto ? null : _cardAposErro(questao),
    ));
  }

  /// Pós-feedback ("Continuar"): aplica o consumo confirmado e limpa o
  /// resultado (em demo, consome o passo localmente).
  void continuar() {
    final s = state.requireValue;
    if (s.feedback == null) return;
    if (AppConfig.demo) {
      state = AsyncData(s.copyWith(
        limparFeedback: true,
        offset: s.offset + 1,
        concluidos: s.concluidos + 1,
      ));
      return;
    }
    state = AsyncData(s.copyWith(
      limparFeedback: true,
      concluidos: s.concluidos + s.incrementoPendente,
      incrementoPendente: 0,
    ));
  }

  /// Fecha a sessão no servidor e monta o Resumo (produto 3.7).
  Future<SessionSummary> finalizar() async {
    if (AppConfig.demo) {
      const summary = SessionSummary.sampleWithAchievement;
      final conquista = summary.achievement?.conquista;
      if (conquista != null) ConquistaQueue.instance.enfileirar(conquista);
      return summary;
    }

    final s = state.requireValue;
    final fim = await _repo.finalizar(s.sessaoId!);
    return SessaoMapper.summaryDe(
      fim: fim,
      trilha: _trilha!,
      combo: s.combo,
      palavras: [for (final p in _palavras.values) p.paraResumo()],
      recompensas: _recompensas,
    );
  }

  /// Reporta a questão atual (motivo predefinido). Melhor esforço: em demo ou
  /// sem questão em foco, não faz nada.
  Future<void> reportar(String motivo) async {
    final passo = state.valueOrNull?.atual;
    if (AppConfig.demo || passo is! QuestionStep) return;
    final questaoId = passo.question.questaoId;
    if (questaoId == null) return;
    await _repo.reportar(questaoId: questaoId, motivo: motivo);
  }

  // ────────────────────────── internos ──────────────────────────

  void _acumular(SessionQuestion questao, RespostaDto r) {
    // Progresso por palavra: só quando a resposta avançou o estado (o nível
    // exibido do estado novo é o nível da questão + 1) ou dominou.
    final palavraId = questao.palavraId;
    if (palavraId != null && (r.dominou || _avancou(questao, r))) {
      final p = _palavras.putIfAbsent(
        palavraId,
        () => _ProgressoPalavra(questao.word ?? '',
            nivelAntes: _nivelDe(questao)),
      );
      p.registrar(
        nivelQuestao: _nivelDe(questao),
        nivelDepois: SessaoMapper.nivelDoEstado(r.estadoPalavra),
        dominou: r.dominou,
      );
    }

    _recompensas.addAll(r.recompensas);
    // Postais entram na fila de reveal já aqui: se o aluno sair sem passar
    // pelo Resumo, o Modo Conquista ainda toca ao abrir o Passaporte.
    final trilha = _trilha;
    if (trilha != null) {
      for (final recompensa in r.recompensas) {
        final conquista = SessaoMapper.conquistaDe(recompensa, trilha);
        if (conquista != null) ConquistaQueue.instance.enfileirar(conquista);
      }
    }
  }

  bool _avancou(SessionQuestion questao, RespostaDto r) =>
      r.correto &&
      SessaoMapper.nivelDoEstado(r.estadoPalavra) == _nivelDe(questao) + 1;

  static int _nivelDe(SessionQuestion q) => switch (q.kind) {
        QuestionKind.significado => 1,
        QuestionKind.sinonimo => 2,
        QuestionKind.completar => 3,
        QuestionKind.julgarUso => 4,
      };

  SessionDiscovery? _cardAposErro(SessionQuestion questao) {
    final palavra = questao.effectiveWord;
    if (palavra == null) return null;
    final erros = (_erros[palavra] = (_erros[palavra] ?? 0) + 1);
    if (erros < 2) return null;
    _erros[palavra] = 0; // recomeça a contagem após rever o card
    return _cards[palavra];
  }

  void _responderDemo(SessaoEstado s, SessionQuestion questao, int opcaoIndex) {
    final correto = questao.options[opcaoIndex].correct;
    final xp = correto ? questao.xp : 0;
    state = AsyncData(s.copyWith(
      combo: correto ? s.combo + 1 : 0,
      feedback: RespostaFeedback(correto: correto, xpGanho: xp, dominou: false),
      cardRevisao: correto ? null : _cardAposErro(questao),
    ));
  }
}

final sessaoControllerProvider =
    AsyncNotifierProvider.autoDispose<SessaoController, SessaoEstado>(
        SessaoController.new);

/// Acumulador mutável do progresso de uma palavra na sessão; vira
/// [WordProgress] no Resumo.
class _ProgressoPalavra {
  _ProgressoPalavra(this.lema, {required int nivelAntes})
      : _de = nivelAntes,
        _para = nivelAntes;

  final String lema;
  int _de;
  int _para;
  bool _dominou = false;

  void registrar({
    required int nivelQuestao,
    required int nivelDepois,
    required bool dominou,
  }) {
    if (nivelQuestao < _de) _de = nivelQuestao;
    if (nivelDepois > _para) _para = nivelDepois;
    if (dominou) _dominou = true;
  }

  WordProgress paraResumo() => _dominou
      ? WordProgress(word: lema, change: WordChange.dominated)
      : WordProgress(
          word: lema,
          change: WordChange.levelUp,
          fromLevel: _de,
          toLevel: _para,
        );
}
