import 'package:flutter_test/flutter_test.dart';
import 'package:vocabkids/features/professor/data/professor_dtos.dart';
import 'package:vocabkids/features/professor/professor_data.dart';
import 'package:vocabkids/features/professor/professor_mapper.dart';

void main() {
  group('ProfessorMapper.painel', () {
    // Espelha o shape de GET /v1/professor/turmas/{id}/painel.
    final dto = PainelDto.fromJson(const {
      'mock': true,
      'turma_id': 1,
      'turma_nome': '7º Ano A',
      'ano_escolar': 7,
      'alunos_ativos': 23,
      'alunos_total': 26,
      'palavras_dominadas_semana': 184,
      'meta_semanal': 5,
      'sinal_turma': ['efêmero', 'perspicaz'],
      'alunos': [
        {
          'id': 1,
          'nome': 'Ana',
          'palavras_semana': 6,
          'meta_semana': 5,
          'palavras_dominadas': 142,
        },
        {
          'id': 2,
          'nome': 'Bruno',
          'palavras_semana': 2,
          'meta_semana': 5,
          'palavras_dominadas': 40,
        },
      ],
    });

    test('mapeia os campos da turma', () {
      final p = ProfessorMapper.painel(dto);
      expect(p.turmaId, 1);
      expect(p.turmaNome, '7º Ano A');
      expect(p.anoEscolar, 7);
      expect(p.alunosAtivos, 23);
      expect(p.alunosTotal, 26);
      expect(p.palavrasDominadasSemana, 184);
      expect(p.metaSemanal, 5);
      expect(p.sinalTurma, ['efêmero', 'perspicaz']);
    });

    test('mapeia alunos e deriva a fração/estado da meta', () {
      final p = ProfessorMapper.painel(dto);
      expect(p.alunos.length, 2);
      expect(p.alunos.first.nome, 'Ana');
      expect(p.alunos.first.metaCumprida, isTrue); // 6 >= 5
      expect(p.alunos[1].metaCumprida, isFalse); // 2 < 5
      expect(p.alunos[1].metaFraction, closeTo(0.4, 1e-9)); // 2 / 5
    });
  });

  group('ProfessorMapper.escola', () {
    // Espelha o shape de GET /v1/professor/escola.
    final dto = EscolaPainelDto.fromJson(const {
      'mock': true,
      'escola_nome': 'Colégio Horizonte',
      'turmas_total': 2,
      'alunos_ativos': 42,
      'alunos_total': 48,
      'palavras_dominadas_semana': 335,
      'sinal_escola': ['efêmero', 'pertinente'],
      'turmas': [
        {
          'id': 1,
          'nome': '7º Ano A',
          'ano_escolar': 7,
          'alunos_ativos': 23,
          'alunos_total': 26,
          'palavras_dominadas_semana': 184,
          'meta_semanal': 5,
        },
        {
          'id': 2,
          'nome': '8º Ano C',
          'ano_escolar': 8,
          'alunos_ativos': 12,
          'alunos_total': 24,
          'palavras_dominadas_semana': 151,
          'meta_semanal': 6,
        },
      ],
    });

    test('mapeia campos e turmas da escola', () {
      final e = ProfessorMapper.escola(dto);
      expect(e.escolaNome, 'Colégio Horizonte');
      expect(e.turmasTotal, 2);
      expect(e.turmas.length, 2);
      expect(e.turmas.first.nome, '7º Ano A');
    });

    test('deriva a fração de alunos ativos por turma', () {
      final e = ProfessorMapper.escola(dto);
      expect(e.turmas[1].ativosFraction, closeTo(0.5, 1e-9)); // 12 / 24
    });
  });

  group('ProfessorMapper.alunoDetalhe', () {
    // Espelha o shape de GET /v1/professor/alunos/{id}.
    final dto = AlunoDetalheDto.fromJson(const {
      'mock': true,
      'id': 4,
      'nome': 'Diego Fernandes',
      'turma_id': 1,
      'turma_nome': '7º Ano A',
      'ano_escolar': 7,
      'palavras_semana': 1,
      'meta_semana': 5,
      'palavras_dominadas': 64,
      'palavras_em_progresso': 4,
      'palavras': [
        {'texto': 'próspero', 'estado': 'dominada', 'origem': 'banco_base'},
        {'texto': 'efêmero', 'estado': 'nivel_1', 'origem': 'sinal_turma'},
        {'texto': 'conciso', 'estado': 'descoberta', 'origem': 'pessoal_redacao'},
      ],
      'redacoes': [
        {
          'id': 1,
          'tema': 'Um herói brasileiro',
          'status': 'pendente',
          'enviada_em': null,
        },
        {
          'id': 2,
          'tema': 'Minhas férias dos sonhos',
          'status': 'analisada',
          'enviada_em': '2026-06-09',
        },
      ],
    });

    test('mapeia campos e counters', () {
      final a = ProfessorMapper.alunoDetalhe(dto);
      expect(a.nome, 'Diego Fernandes');
      expect(a.turmaNome, '7º Ano A');
      expect(a.palavrasDominadas, 64);
      expect(a.palavrasEmProgresso, 4);
      expect(a.palavras.length, 3);
      expect(a.redacoes.length, 2);
    });

    test('traduz estado/origem das palavras para enums', () {
      final a = ProfessorMapper.alunoDetalhe(dto);
      expect(a.palavras[0].estado, EstadoPalavra.dominada);
      expect(a.palavras[0].estado.isDominada, isTrue);
      expect(a.palavras[1].estado, EstadoPalavra.nivel1);
      expect(a.palavras[1].origem, OrigemPalavra.sinalTurma);
      expect(a.palavras[2].estado, EstadoPalavra.descoberta);
      expect(a.palavras[2].origem, OrigemPalavra.pessoalRedacao);
    });

    test('deriva a meta da semana (fração, faltam, cumprida)', () {
      final a = ProfessorMapper.alunoDetalhe(dto);
      expect(a.metaCumprida, isFalse); // 1 < 5
      expect(a.metaFraction, closeTo(0.2, 1e-9)); // 1 / 5
      expect(a.faltamMeta, 4); // 5 - 1
    });

    test('redação: data ISO vira dd/mm; nula fica nula', () {
      final a = ProfessorMapper.alunoDetalhe(dto);
      expect(a.redacoes[0].status, StatusRedacao.pendente);
      expect(a.redacoes[0].dataCurta, isNull); // enviada_em null
      expect(a.redacoes[1].status, StatusRedacao.analisada);
      expect(a.redacoes[1].dataCurta, '09/06');
    });

    test('estado/origem/status desconhecidos caem no default (resiliente)', () {
      expect(EstadoPalavra.parse('xpto'), EstadoPalavra.descoberta);
      expect(OrigemPalavra.parse('xpto'), OrigemPalavra.bancoBase);
      expect(StatusRedacao.parse('xpto'), StatusRedacao.pendente);
    });
  });

  group('AlunoDetalhe.sample', () {
    test('reusa os campos-base do painel e mescla o extra', () {
      final a = AlunoDetalhe.sample(1); // Ana Beatriz (turma 1)
      expect(a.nome, 'Ana Beatriz');
      expect(a.turmaNome, '7º Ano A');
      expect(a.palavrasDominadas, 142); // do painel
      expect(a.metaCumprida, isTrue); // 6 >= 5
      expect(a.palavras, isNotEmpty);
      expect(a.redacoes, isNotEmpty);
    });

    test('id inexistente cai no primeiro aluno (não estoura)', () {
      final a = AlunoDetalhe.sample(99999);
      expect(a.nome, isNotEmpty);
    });
  });

  group('ProfessorMapper.redacaoAtribuicao', () {
    test('mapeia o retorno do POST e formata o prazo', () {
      final dto = RedacaoAtribuicaoDto.fromJson(const {
        'mock': true,
        'id': 101,
        'turma_id': 1,
        'tema': 'Um herói brasileiro',
        'prazo': '2026-06-30',
      });
      final a = ProfessorMapper.redacaoAtribuicao(dto);
      expect(a.id, 101);
      expect(a.turmaId, 1);
      expect(a.tema, 'Um herói brasileiro');
      expect(a.prazoCurto, '30/06');
    });

    test('prazo nulo fica nulo', () {
      final dto = RedacaoAtribuicaoDto.fromJson(const {
        'mock': true,
        'id': 102,
        'turma_id': 2,
        'tema': 'Sem prazo',
        'prazo': null,
      });
      final a = ProfessorMapper.redacaoAtribuicao(dto);
      expect(a.prazoCurto, isNull);
    });
  });

  group('PainelData.comMeta', () {
    test('troca a meta do KPI e a de cada aluno; frações acompanham', () {
      final base = PainelData.sample(1); // meta 5
      final novo = base.comMeta(8);
      expect(novo.metaSemanal, 8);
      expect(novo.turmaId, base.turmaId);
      expect(novo.alunos.length, base.alunos.length);
      expect(novo.alunos.every((a) => a.metaSemana == 8), isTrue);
      // Ana: 6 palavras / meta 8 → deixa de cumprir; fração 0.75 (derivada).
      final ana = novo.alunos.firstWhere((a) => a.nome == 'Ana Beatriz');
      expect(ana.metaCumprida, isFalse);
      expect(ana.metaFraction, closeTo(0.75, 1e-9));
      // Não muta a fonte original.
      expect(base.metaSemanal, 5);
    });
  });
}
