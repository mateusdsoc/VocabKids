/// Modelos do **Passaporte** (produto §3.10) — a coleção de recompensas que é,
/// também, o perfil do aluno (não há tela de perfil separada). Três baldes de
/// colecionáveis seguindo a metáfora de viagem:
///
/// - **Carimbos** — 1 por país concluído (Brasil, França, Japão).
/// - **Cartões-postais** — 1 por destino concluído (20 no total: 5+7+8).
/// - **Selos (feitos)** — 5 conquistas individuais.
///
/// Itens ainda não conquistados aparecem como silhueta/cadeado (mostra o que
/// falta — motivador). Aqui só o que a UI precisa; a arte (28 peças) é trabalho
/// à parte, então os itens conquistados são placeholders estilizados por ora.
library;

import 'package:flutter/material.dart';

import '../../core/widgets/app_icons.dart';

enum Pais { brasil, franca, japao }

/// Resolve o enum a partir do nome vindo do servidor (`/v1/trilha`).
/// `null` para nomes fora do catálogo fixo do produto (3 países).
Pais? paisDe(String nome) {
  final n = nome.toLowerCase();
  if (n.startsWith('brasil')) return Pais.brasil;
  if (n.startsWith('fran')) return Pais.franca;
  if (n.startsWith('jap')) return Pais.japao;
  return null;
}

extension PaisX on Pais {
  String get nome => switch (this) {
        Pais.brasil => 'Brasil',
        Pais.franca => 'França',
        Pais.japao => 'Japão',
      };

  /// Nome com preposição, para títulos ("Carimbo do Brasil" / "da França").
  String get comPreposicao => switch (this) {
        Pais.brasil => 'do Brasil',
        Pais.franca => 'da França',
        Pais.japao => 'do Japão',
      };

  /// Inicial usada no miolo do carimbo quando não há arte.
  String get inicial => switch (this) {
        Pais.brasil => 'BR',
        Pais.franca => 'FR',
        Pais.japao => 'JP',
      };
}

/// Um destino (cidade) — vira um cartão-postal quando conquistado.
class Destino {
  const Destino({required this.cidade, required this.conquistado});
  final String cidade;
  final bool conquistado;
}

/// A coleção de um país: o carimbo (país concluído?) e seus destinos.
class PaisColecao {
  const PaisColecao({
    required this.pais,
    required this.carimbo,
    required this.destinos,
  });

  final Pais pais;
  final bool carimbo;
  final List<Destino> destinos;

  int get total => destinos.length;
  int get conquistados => destinos.where((d) => d.conquistado).length;
  bool get completo => conquistados == total;
}

/// Um selo de feito (conquista individual).
class Selo {
  const Selo({
    required this.titulo,
    required this.descricao,
    required this.icone,
    required this.conquistado,
  });

  final String titulo;
  final String descricao;
  final IconData icone;
  final bool conquistado;
}

/// Capa do passaporte = identidade + status do aluno.
class Capa {
  const Capa({
    required this.nome,
    required this.nivel,
    required this.paisAtual,
    required this.xp,
    required this.palavras,
    required this.escola,
    required this.turma,
  });

  final String nome;
  final int nivel;
  final String paisAtual;
  final int xp;
  final int palavras;
  final String escola;
  final String turma;

  String get inicial => nome.trim().isEmpty ? '?' : nome.trim()[0].toUpperCase();
}

/// Item recém-conquistado — alimenta o **Modo Conquista** (reveal que dispara
/// uma única vez). Vem das recompensas de `POST /respostas` (caminho quente,
/// via `SessaoMapper`) e da fila pendente de `GET /v1/passaporte`
/// (`conquistado && !revelado`, via `PassaporteMapper`).
sealed class Conquista {
  const Conquista({this.colecionavelId});

  /// Id do colecionável no servidor — o reveal persiste o "visto" por ele
  /// (`POST /v1/passaporte/{id}/revelado`). Nulo nas amostras/demo e quando a
  /// recompensa chegou sem correspondência na coleção (só não persiste).
  final int? colecionavelId;

  /// Amostra: o cartão-postal do Rio (casa com o teaser do Resumo).
  static const Conquista sampleRio = ConquistaPostal(
    destino: Destino(cidade: 'Rio de Janeiro', conquistado: true),
    pais: Pais.brasil,
  );

  /// Amostra: selo "100 palavras" caindo no grid (não wireada no fluxo; útil
  /// para exercitar o reveal de selo).
  static const Conquista sampleSelo = ConquistaSelo(
    novoIndex: 3,
    todos: [
      Selo(
        titulo: 'Primeira carta',
        descricao: 'Enviou a 1ª redação',
        icone: AppIcons.redacao,
        conquistado: true,
      ),
      Selo(
        titulo: 'Combo de 10',
        descricao: '10 acertos seguidos',
        icone: AppIcons.combo,
        conquistado: true,
      ),
      Selo(
        titulo: '25 palavras',
        descricao: '25 palavras dominadas',
        icone: AppIcons.palavras,
        conquistado: true,
      ),
      Selo(
        titulo: '100 palavras',
        descricao: '100 palavras dominadas',
        icone: AppIcons.palavras,
        conquistado: true,
      ),
      Selo(
        titulo: '250 palavras',
        descricao: '250 palavras dominadas',
        icone: AppIcons.star,
        conquistado: false,
      ),
    ],
  );
}

/// Cartão-postal novo (destino concluído): 1 por página, só ele anima.
class ConquistaPostal extends Conquista {
  const ConquistaPostal({
    required this.destino,
    required this.pais,
    super.colecionavelId,
  });
  final Destino destino;
  final Pais pais;
}

/// Carimbo novo (país concluído): o carimbo bate na página, embaçado até o
/// toque — mesma coreografia do postal, com o widget [Carimbo] da coleção.
class ConquistaCarimbo extends Conquista {
  const ConquistaCarimbo({required this.pais, super.colecionavelId});
  final Pais pais;
}

/// Selo novo (feito): grid com os antigos estáticos; só [novoIndex] anima
/// (cai, pulsa e encaixa).
class ConquistaSelo extends Conquista {
  const ConquistaSelo({
    required this.todos,
    required this.novoIndex,
    super.colecionavelId,
  });

  /// O grid completo, na ordem de exibição.
  final List<Selo> todos;
  final int novoIndex;
}

/// O passaporte completo.
class Passaporte {
  const Passaporte({
    required this.capa,
    required this.paises,
    required this.selos,
  });

  final Capa capa;
  final List<PaisColecao> paises;
  final List<Selo> selos;

  int get carimbosConquistados => paises.where((p) => p.carimbo).length;
  int get postaisConquistados =>
      paises.fold<int>(0, (s, p) => s + p.conquistados);
  int get selosConquistados => selos.where((s) => s.conquistado).length;

  int get totalPecas =>
      paises.length +
      paises.fold<int>(0, (s, p) => s + p.total) +
      selos.length;
  int get pecasConquistadas =>
      carimbosConquistados + postaisConquistados + selosConquistados;

  /// Amostra do apresentável: estado parcial realista (Brasil completo, França
  /// em andamento, Japão por começar) para exercitar conquistado + bloqueado.
  static const Passaporte sample = Passaporte(
    capa: Capa(
      nome: 'Manu Oliveira',
      nivel: 3,
      paisAtual: 'França',
      xp: 3120,
      palavras: 48,
      escola: 'EM Cecília Meireles',
      turma: 'Turma 7A · 7º ano',
    ),
    paises: [
      PaisColecao(
        pais: Pais.brasil,
        carimbo: true,
        destinos: [
          Destino(cidade: 'Rio de Janeiro', conquistado: true),
          Destino(cidade: 'Salvador', conquistado: true),
          Destino(cidade: 'Manaus', conquistado: true),
          Destino(cidade: 'Brasília', conquistado: true),
          Destino(cidade: 'Recife', conquistado: true),
        ],
      ),
      PaisColecao(
        pais: Pais.franca,
        carimbo: false,
        destinos: [
          Destino(cidade: 'Paris', conquistado: true),
          Destino(cidade: 'Lyon', conquistado: true),
          Destino(cidade: 'Nice', conquistado: true),
          Destino(cidade: 'Bordeaux', conquistado: false),
          Destino(cidade: 'Marselha', conquistado: false),
          Destino(cidade: 'Estrasburgo', conquistado: false),
          Destino(cidade: 'Cannes', conquistado: false),
        ],
      ),
      PaisColecao(
        pais: Pais.japao,
        carimbo: false,
        destinos: [
          Destino(cidade: 'Tóquio', conquistado: false),
          Destino(cidade: 'Kyoto', conquistado: false),
          Destino(cidade: 'Osaka', conquistado: false),
          Destino(cidade: 'Hiroshima', conquistado: false),
          Destino(cidade: 'Nara', conquistado: false),
          Destino(cidade: 'Sapporo', conquistado: false),
          Destino(cidade: 'Nagoya', conquistado: false),
          Destino(cidade: 'Yokohama', conquistado: false),
        ],
      ),
    ],
    selos: [
      Selo(
        titulo: 'Primeira carta',
        descricao: 'Enviou a 1ª redação',
        icone: AppIcons.redacao,
        conquistado: true,
      ),
      Selo(
        titulo: 'Combo de 10',
        descricao: '10 acertos seguidos',
        icone: AppIcons.combo,
        conquistado: true,
      ),
      Selo(
        titulo: '25 palavras',
        descricao: '25 palavras dominadas',
        icone: AppIcons.palavras,
        conquistado: true,
      ),
      Selo(
        titulo: '100 palavras',
        descricao: '100 palavras dominadas',
        icone: AppIcons.palavras,
        conquistado: false,
      ),
      Selo(
        titulo: '250 palavras',
        descricao: '250 palavras dominadas',
        icone: AppIcons.star,
        conquistado: false,
      ),
    ],
  );
}
