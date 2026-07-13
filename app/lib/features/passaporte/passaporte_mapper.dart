import '../../core/widgets/app_icons.dart';
import '../home/data/trilha_models.dart';
import '../identidade/models.dart';
import 'data/passaporte_models.dart';
import 'models.dart';

/// Resultado do carregamento: a coleção apresentável + a fila de reveals
/// pendentes (Modo Conquista), na ordem em que foram ganhos.
class PassaporteCarregado {
  const PassaporteCarregado({required this.passaporte, required this.pendentes});

  final Passaporte passaporte;
  final List<Conquista> pendentes;
}

/// Traduz `/v1/passaporte` + `/v1/trilha` + `/v1/me` na coleção que a UI
/// consome. Único ponto que conhece os contratos: os itens do servidor trazem
/// `referencia` (`destino:{id}`, `pais:{id}`, `feito:{chave}`); nomes de
/// cidade/país vêm da trilha; título/descrição/ícone dos selos são catálogo
/// do cliente (a arte é assunto do app, não do banco).
abstract final class PassaporteMapper {
  /// Catálogo dos selos por chave de `feito:` — copy do design.
  static const _selos = {
    'redacao_1': ('Primeira carta', 'Enviou a 1ª redação', AppIcons.redacao),
    'combo_10': ('Combo de 10', '10 acertos seguidos', AppIcons.combo),
    'dominadas_25': ('25 palavras', '25 palavras dominadas', AppIcons.palavras),
    'dominadas_100': ('100 palavras', '100 palavras dominadas', AppIcons.palavras),
    'dominadas_250': ('250 palavras', '250 palavras dominadas', AppIcons.star),
  };

  static PassaporteCarregado carregadoDe({
    required Me me,
    required Trilha trilha,
    required PassaporteDto dto,
  }) {
    // Conquistas indexadas por referência (uma linha por colecionável).
    final porReferencia = {for (final i in dto.itens) i.referencia: i};

    // ── Países e cartões-postais (estrutura/nomes: trilha; posse: itens). ──
    final paises = <PaisColecao>[];
    for (final pais in trilha.paises) {
      final paisEnum = paisDe(pais.nome);
      if (paisEnum == null) continue; // fora do catálogo fixo — não exibe
      paises.add(PaisColecao(
        pais: paisEnum,
        carimbo: porReferencia['pais:${pais.id}']?.conquistado ?? false,
        destinos: [
          for (final d in pais.destinos)
            Destino(
              cidade: d.nome,
              conquistado:
                  porReferencia['destino:${d.id}']?.conquistado ?? false,
            ),
        ],
      ));
    }

    // ── Selos, na ordem do catálogo (estável para o grid do reveal). ──
    final selos = <Selo>[];
    final indexPorReferencia = <String, int>{};
    for (final entry in _selos.entries) {
      final referencia = 'feito:${entry.key}';
      final item = porReferencia[referencia];
      if (item == null) continue; // seed ainda sem esse selo
      final (titulo, descricao, icone) = entry.value;
      indexPorReferencia[referencia] = selos.length;
      selos.add(Selo(
        titulo: titulo,
        descricao: descricao,
        icone: icone,
        conquistado: item.conquistado,
      ));
    }

    final passaporte = Passaporte(
      capa: _capa(me, trilha),
      paises: paises,
      selos: selos,
    );

    // ── Fila do Modo Conquista: ganhos ainda não revelados, mais antigo
    // primeiro (acumulou sessões sem abrir o Passaporte → revela em ordem). ──
    final pendentes = dto.itens.where((i) => i.pendenteDeReveal).toList()
      ..sort((a, b) => (a.ganhoEm ?? DateTime(0)).compareTo(b.ganhoEm ?? DateTime(0)));

    return PassaporteCarregado(
      passaporte: passaporte,
      pendentes: [
        for (final item in pendentes)
          ?_conquistaDe(item, trilha, selos, indexPorReferencia),
      ],
    );
  }

  static Capa _capa(Me me, Trilha trilha) {
    final destinos = trilha.destinosEmOrdem;
    final nivel = destinos.fold<int>(0, (s, d) => s + d.nosConcluidos) + 1;
    final turma = me.turma;
    return Capa(
      nome: me.nome,
      nivel: nivel,
      paisAtual: trilha.noAtual?.paisNome ?? trilha.paises.lastOrNull?.nome ?? '',
      xp: trilha.xpTotal,
      palavras: me.progresso.palavrasDominadas,
      escola: me.escola?.nome ?? '',
      turma: turma == null ? '' : '${turma.nome} · ${turma.anoEscolar}º ano',
    );
  }

  /// Item pendente → conquista revelável. `null` quando não dá para resolver
  /// (referência fora da trilha carregada) — o item continua na coleção, só
  /// não toca reveal.
  static Conquista? _conquistaDe(
    ItemPassaporteDto item,
    Trilha trilha,
    List<Selo> selos,
    Map<String, int> indexPorReferencia,
  ) {
    switch (item.tipo) {
      case 'cartao_postal':
        for (final pais in trilha.paises) {
          for (final d in pais.destinos) {
            if ('destino:${d.id}' == item.referencia) {
              final paisEnum = paisDe(pais.nome);
              if (paisEnum == null) return null;
              return ConquistaPostal(
                colecionavelId: item.id,
                destino: Destino(cidade: d.nome, conquistado: true),
                pais: paisEnum,
              );
            }
          }
        }
        return null;
      case 'carimbo':
        for (final pais in trilha.paises) {
          if ('pais:${pais.id}' == item.referencia) {
            final paisEnum = paisDe(pais.nome);
            if (paisEnum == null) return null;
            return ConquistaCarimbo(colecionavelId: item.id, pais: paisEnum);
          }
        }
        return null;
      case 'selo':
        final index = indexPorReferencia[item.referencia];
        if (index == null) return null;
        return ConquistaSelo(
          colecionavelId: item.id,
          todos: selos,
          novoIndex: index,
        );
      default:
        return null;
    }
  }
}
