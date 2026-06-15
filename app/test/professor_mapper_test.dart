import 'package:flutter_test/flutter_test.dart';
import 'package:vocabkids/features/professor/data/professor_dtos.dart';
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
}
