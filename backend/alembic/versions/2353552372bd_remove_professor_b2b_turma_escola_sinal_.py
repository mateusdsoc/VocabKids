"""remove professor b2b: turma, escola, sinal_turma, turma_config

Revision ID: 2353552372bd
Revises: 326aa898d291
Create Date: 2026-08-25 11:23:47.484562

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

# revision identifiers, used by Alembic.
revision: str = '2353552372bd'
down_revision: Union[str, Sequence[str], None] = '326aa898d291'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Upgrade schema."""
    # Ordem à mão (autogenerate não resolve dependências entre DROPs):
    # 1) CHECKs/FKs que referenciam turma/associacao ANTES das tabelas/colunas;
    # 2) associacao_turma/sinal_turma/turma_config ANTES de turma (todas têm FK
    #    pra turma); turma ANTES de escola.
    op.drop_constraint(op.f('ck_redacao_atribuicao_turma_xor_usuario'), 'redacao_atribuicao', type_='check')
    op.drop_constraint(op.f('ck_redacao_atribuicao_origem_valida'), 'redacao_atribuicao', type_='check')
    op.drop_constraint(op.f('fk_redacao_atribuicao_professor_associacao_id_associacao'), 'redacao_atribuicao', type_='foreignkey')
    op.drop_constraint(op.f('fk_redacao_atribuicao_turma_id_turma'), 'redacao_atribuicao', type_='foreignkey')
    op.drop_constraint(op.f('fk_associacao_escola_id_escola'), 'associacao', type_='foreignkey')

    op.drop_table('associacao_turma')
    op.drop_table('sinal_turma')
    op.drop_table('turma_config')
    op.drop_table('turma')
    op.drop_table('escola')

    op.drop_column('associacao', 'escola_id')
    op.alter_column('redacao_atribuicao', 'usuario_id',
               existing_type=sa.BIGINT(),
               nullable=False)
    op.alter_column('redacao_atribuicao', 'origem',
               existing_type=sa.TEXT(),
               nullable=False)
    op.drop_column('redacao_atribuicao', 'professor_associacao_id')
    op.drop_column('redacao_atribuicao', 'turma_id')

    # CHECKs restantes — mesmo motivo, à mão.
    op.create_check_constraint(
        op.f('ck_redacao_atribuicao_origem_valida'), 'redacao_atribuicao', "origem IN ('automatica','sob_demanda')"
    )
    op.drop_constraint(op.f('ck_associacao_papel_valido'), 'associacao', type_='check')
    op.create_check_constraint(
        op.f('ck_associacao_papel_valido'), 'associacao', "papel IN ('aluno','responsavel')"
    )
    op.drop_constraint(op.f('ck_aluno_palavra_origem_valida'), 'aluno_palavra', type_='check')
    op.create_check_constraint(
        op.f('ck_aluno_palavra_origem_valida'), 'aluno_palavra', "origem IN ('pessoal_redacao','banco_base')"
    )


def downgrade() -> None:
    """Downgrade schema. Ordem à mão: escola → turma → (turma_config,
    sinal_turma, associacao_turma) → colunas/FKs que apontam pra elas."""
    op.drop_constraint(op.f('ck_aluno_palavra_origem_valida'), 'aluno_palavra', type_='check')
    op.create_check_constraint(
        op.f('ck_aluno_palavra_origem_valida'),
        'aluno_palavra',
        "origem IN ('pessoal_redacao','sinal_turma','banco_base')",
    )
    op.drop_constraint(op.f('ck_associacao_papel_valido'), 'associacao', type_='check')
    op.create_check_constraint(
        op.f('ck_associacao_papel_valido'),
        'associacao',
        "papel IN ('aluno','responsavel','professor','coordenador','admin')",
    )
    op.drop_constraint(op.f('ck_redacao_atribuicao_origem_valida'), 'redacao_atribuicao', type_='check')

    op.create_table('escola',
    sa.Column('id', sa.BIGINT(), sa.Identity(always=True, start=1, increment=1, minvalue=1, maxvalue=9223372036854775807, cycle=False, cache=1), autoincrement=True, nullable=False),
    sa.Column('nome', sa.TEXT(), autoincrement=False, nullable=False),
    sa.Column('created_at', postgresql.TIMESTAMP(timezone=True), server_default=sa.text('now()'), autoincrement=False, nullable=False),
    sa.PrimaryKeyConstraint('id', name=op.f('pk_escola'))
    )
    op.create_table('turma',
    sa.Column('id', sa.BIGINT(), sa.Identity(always=True, start=1, increment=1, minvalue=1, maxvalue=9223372036854775807, cycle=False, cache=1), autoincrement=True, nullable=False),
    sa.Column('escola_id', sa.BIGINT(), autoincrement=False, nullable=False),
    sa.Column('nome', sa.TEXT(), autoincrement=False, nullable=False),
    sa.Column('ano_escolar', sa.INTEGER(), autoincrement=False, nullable=False),
    sa.Column('codigo_turma', sa.TEXT(), autoincrement=False, nullable=False),
    sa.Column('created_at', postgresql.TIMESTAMP(timezone=True), server_default=sa.text('now()'), autoincrement=False, nullable=False),
    sa.CheckConstraint('ano_escolar >= 6 AND ano_escolar <= 9', name=op.f('ck_turma_ano_escolar_range')),
    sa.ForeignKeyConstraint(['escola_id'], ['escola.id'], name=op.f('fk_turma_escola_id_escola'), ondelete='CASCADE'),
    sa.PrimaryKeyConstraint('id', name=op.f('pk_turma')),
    sa.UniqueConstraint('codigo_turma', name=op.f('uq_turma_codigo_turma'), postgresql_include=[], postgresql_nulls_not_distinct=False)
    )
    op.create_table('turma_config',
    sa.Column('turma_id', sa.BIGINT(), autoincrement=False, nullable=False),
    sa.Column('meta_semanal', sa.INTEGER(), autoincrement=False, nullable=True),
    sa.Column('preset_rigor', postgresql.JSONB(astext_type=sa.Text()), autoincrement=False, nullable=True),
    sa.Column('created_at', postgresql.TIMESTAMP(timezone=True), server_default=sa.text('now()'), autoincrement=False, nullable=False),
    sa.ForeignKeyConstraint(['turma_id'], ['turma.id'], name=op.f('fk_turma_config_turma_id_turma'), ondelete='CASCADE'),
    sa.PrimaryKeyConstraint('turma_id', name=op.f('pk_turma_config'))
    )
    op.create_table('sinal_turma',
    sa.Column('id', sa.BIGINT(), sa.Identity(always=True, start=1, increment=1, minvalue=1, maxvalue=9223372036854775807, cycle=False, cache=1), autoincrement=True, nullable=False),
    sa.Column('turma_id', sa.BIGINT(), autoincrement=False, nullable=False),
    sa.Column('palavra_id', sa.BIGINT(), autoincrement=False, nullable=False),
    sa.Column('periodo', sa.TEXT(), autoincrement=False, nullable=False),
    sa.Column('pct', sa.NUMERIC(precision=5, scale=2), autoincrement=False, nullable=False),
    sa.Column('computado_em', postgresql.TIMESTAMP(timezone=True), server_default=sa.text('now()'), autoincrement=False, nullable=False),
    sa.Column('created_at', postgresql.TIMESTAMP(timezone=True), server_default=sa.text('now()'), autoincrement=False, nullable=False),
    sa.ForeignKeyConstraint(['palavra_id'], ['palavra.id'], name=op.f('fk_sinal_turma_palavra_id_palavra'), ondelete='CASCADE'),
    sa.ForeignKeyConstraint(['turma_id'], ['turma.id'], name=op.f('fk_sinal_turma_turma_id_turma'), ondelete='CASCADE'),
    sa.PrimaryKeyConstraint('id', name=op.f('pk_sinal_turma')),
    sa.UniqueConstraint('turma_id', 'palavra_id', 'periodo', name=op.f('sinal_turma_unico'), postgresql_include=[], postgresql_nulls_not_distinct=False)
    )

    op.add_column('associacao', sa.Column('escola_id', sa.BIGINT(), autoincrement=False, nullable=True))
    op.create_foreign_key(op.f('fk_associacao_escola_id_escola'), 'associacao', 'escola', ['escola_id'], ['id'], ondelete='CASCADE')

    op.create_table('associacao_turma',
    sa.Column('associacao_id', sa.BIGINT(), autoincrement=False, nullable=False),
    sa.Column('turma_id', sa.BIGINT(), autoincrement=False, nullable=False),
    sa.Column('created_at', postgresql.TIMESTAMP(timezone=True), server_default=sa.text('now()'), autoincrement=False, nullable=False),
    sa.ForeignKeyConstraint(['associacao_id'], ['associacao.id'], name=op.f('fk_associacao_turma_associacao_id_associacao'), ondelete='CASCADE'),
    sa.ForeignKeyConstraint(['turma_id'], ['turma.id'], name=op.f('fk_associacao_turma_turma_id_turma'), ondelete='CASCADE'),
    sa.PrimaryKeyConstraint('associacao_id', 'turma_id', name=op.f('pk_associacao_turma'))
    )

    op.add_column('redacao_atribuicao', sa.Column('turma_id', sa.BIGINT(), autoincrement=False, nullable=True))
    op.add_column('redacao_atribuicao', sa.Column('professor_associacao_id', sa.BIGINT(), autoincrement=False, nullable=True))
    op.create_foreign_key(op.f('fk_redacao_atribuicao_turma_id_turma'), 'redacao_atribuicao', 'turma', ['turma_id'], ['id'], ondelete='CASCADE')
    op.create_foreign_key(op.f('fk_redacao_atribuicao_professor_associacao_id_associacao'), 'redacao_atribuicao', 'associacao', ['professor_associacao_id'], ['id'], ondelete='SET NULL')
    op.alter_column('redacao_atribuicao', 'origem',
               existing_type=sa.TEXT(),
               nullable=True)
    op.alter_column('redacao_atribuicao', 'usuario_id',
               existing_type=sa.BIGINT(),
               nullable=True)

    op.create_check_constraint(
        op.f('ck_redacao_atribuicao_origem_valida'),
        'redacao_atribuicao',
        "origem IS NULL OR origem IN ('automatica','sob_demanda')",
    )
    op.create_check_constraint(
        op.f('ck_redacao_atribuicao_turma_xor_usuario'),
        'redacao_atribuicao',
        '(turma_id IS NOT NULL) <> (usuario_id IS NOT NULL)',
    )
