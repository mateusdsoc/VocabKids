"""Esquema do banco — Bloco 1 do `docs/arquitetura.md`.

Fonte única da verdade do schema (SQLAlchemy Core). O Alembic autogera as migrations
a partir deste `metadata`; o app lê/escreve por estas tabelas.

Convenções (Bloco 1):
- PK `BIGINT GENERATED ALWAYS AS IDENTITY` (decisão 1).
- `created_at TIMESTAMPTZ NOT NULL DEFAULT now()` em todas as tabelas.
- Enums via `VARCHAR + CHECK` (fácil de evoluir vs. tipo enum nativo).
- FKs com `ON DELETE` explícito.

Fase: A = existe no apresentável; C = entra no completo (mock/vazia em A — schema único).
"""
from sqlalchemy import (
    BigInteger,
    Boolean,
    CheckConstraint,
    Column,
    Date,
    DateTime,
    ForeignKey,
    Identity,
    Index,
    Integer,
    MetaData,
    Numeric,
    Table,
    Text,
    UniqueConstraint,
    func,
)
from sqlalchemy.dialects.postgresql import JSONB

# Convenção de nomes — deixa a autogeração do Alembic estável e previsível.
NAMING_CONVENTION = {
    "ix": "ix_%(table_name)s_%(column_0_name)s",
    "uq": "uq_%(table_name)s_%(column_0_name)s",
    "ck": "ck_%(table_name)s_%(constraint_name)s",
    "fk": "fk_%(table_name)s_%(column_0_name)s_%(referred_table_name)s",
    "pk": "pk_%(table_name)s",
}

metadata = MetaData(naming_convention=NAMING_CONVENTION)


def _id():
    return Column("id", BigInteger, Identity(always=True), primary_key=True)


def _created_at():
    return Column(
        "created_at", DateTime(timezone=True), nullable=False, server_default=func.now()
    )


# ─────────────────────────── 1. Identidade e organização (A) ───────────────────────────

usuario = Table(
    "usuario",
    metadata,
    _id(),
    Column("nome", Text, nullable=False),
    Column("email", Text, nullable=True),  # aluno sem e-mail é válido
    Column("auth_provider", Text, nullable=True),  # nulo até a janela do 1º cliente
    Column("auth_subject", Text, nullable=True),
    _created_at(),
    UniqueConstraint("auth_provider", "auth_subject", name="auth_identity"),
)
# E-mail único só quando presente (parcial).
Index(
    "uq_usuario_email",
    usuario.c.email,
    unique=True,
    postgresql_where=usuario.c.email.isnot(None),
)

escola = Table(
    "escola",
    metadata,
    _id(),
    Column("nome", Text, nullable=False),
    _created_at(),
)

turma = Table(
    "turma",
    metadata,
    _id(),
    Column("escola_id", BigInteger, ForeignKey("escola.id", ondelete="CASCADE"), nullable=False),
    Column("nome", Text, nullable=False),
    Column("ano_escolar", Integer, nullable=False),
    Column("codigo_turma", Text, nullable=False, unique=True),  # acesso provisório
    _created_at(),
    CheckConstraint("ano_escolar BETWEEN 6 AND 9", name="ano_escolar_range"),
)

associacao = Table(
    "associacao",
    metadata,
    _id(),
    Column("usuario_id", BigInteger, ForeignKey("usuario.id", ondelete="CASCADE"), nullable=False),
    Column("escola_id", BigInteger, ForeignKey("escola.id", ondelete="CASCADE"), nullable=True),  # null p/ admin
    Column("papel", Text, nullable=False),
    _created_at(),
    CheckConstraint(
        "papel IN ('aluno','professor','coordenador','admin')", name="papel_valido"
    ),
)

associacao_turma = Table(
    "associacao_turma",
    metadata,
    Column("associacao_id", BigInteger, ForeignKey("associacao.id", ondelete="CASCADE"), primary_key=True),
    Column("turma_id", BigInteger, ForeignKey("turma.id", ondelete="CASCADE"), primary_key=True),
    _created_at(),
)


# ─────────────────────── 2. Banco de vocabulário — global (A) ───────────────────────

palavra = Table(
    "palavra",
    metadata,
    _id(),
    Column("lema", Text, nullable=False, unique=True),  # chave de busca/dedup (spaCy)
    Column("definicao", Text, nullable=False),
    Column("exemplo_uso", Text, nullable=False),
    Column("nivel_dificuldade", Integer, nullable=False),
    Column("audio_url", Text, nullable=True),
    Column("origem", Text, nullable=False),
    _created_at(),
    CheckConstraint("nivel_dificuldade BETWEEN 1 AND 10", name="nivel_range"),
    CheckConstraint("origem IN ('banco_base','redacao')", name="origem_valida"),
)

palavra_sinonimo = Table(
    "palavra_sinonimo",
    metadata,
    _id(),
    Column("palavra_id", BigInteger, ForeignKey("palavra.id", ondelete="CASCADE"), nullable=False),
    Column("texto", Text, nullable=False),
    _created_at(),
)

questao = Table(
    "questao",
    metadata,
    _id(),
    Column("palavra_id", BigInteger, ForeignKey("palavra.id", ondelete="CASCADE"), nullable=False),
    Column("nivel", Integer, nullable=False),
    Column("variacao", Text, nullable=False),
    Column("enunciado", Text, nullable=False),
    Column("opcoes", JSONB, nullable=False),  # enunciado/distratores
    Column("resposta_correta", Text, nullable=False),
    Column("status", Text, nullable=False, server_default="ativa"),
    _created_at(),
    CheckConstraint("nivel BETWEEN 1 AND 4", name="nivel_range"),
    CheckConstraint(
        "status IN ('ativa','oculta_report','em_revisao','removida')", name="status_valido"
    ),
    UniqueConstraint("palavra_id", "nivel", "variacao", name="variacao_unica"),
)

report_questao = Table(
    "report_questao",
    metadata,
    _id(),
    Column("questao_id", BigInteger, ForeignKey("questao.id", ondelete="CASCADE"), nullable=False),
    Column("usuario_id", BigInteger, ForeignKey("usuario.id", ondelete="CASCADE"), nullable=False),
    Column("motivo", Text, nullable=False),
    Column("veredito", Text, nullable=False, server_default="pendente"),
    Column("resolved_at", DateTime(timezone=True), nullable=True),
    _created_at(),
    CheckConstraint(
        "veredito IN ('pendente','valido','invalido')", name="veredito_valido"
    ),
)


# ─────────────────── 3. Estado de aprendizado — isolado por escola (A) ───────────────────

aluno_palavra = Table(
    "aluno_palavra",
    metadata,
    _id(),
    Column("usuario_id", BigInteger, ForeignKey("usuario.id", ondelete="CASCADE"), nullable=False),
    Column("palavra_id", BigInteger, ForeignKey("palavra.id", ondelete="CASCADE"), nullable=False),
    Column("estado", Text, nullable=False),
    Column("origem", Text, nullable=False),
    Column("palavra_gatilho", Text, nullable=True),  # só origem pessoal
    Column("nivel4_agendado_para", Integer, nullable=True),  # sessão-alvo do N4 adiado
    Column("atribuida_em", DateTime(timezone=True), nullable=False, server_default=func.now()),
    Column("dominada_em", DateTime(timezone=True), nullable=True),
    _created_at(),
    CheckConstraint(
        "estado IN ('descoberta','nivel_1','nivel_2','nivel_3','nivel_4','dominada')",
        name="estado_valido",
    ),
    CheckConstraint(
        "origem IN ('pessoal_redacao','sinal_turma','banco_base')", name="origem_valida"
    ),
    UniqueConstraint("usuario_id", "palavra_id", name="aluno_palavra_unica"),
)

aluno_questao = Table(
    "aluno_questao",
    metadata,
    Column("usuario_id", BigInteger, ForeignKey("usuario.id", ondelete="CASCADE"), primary_key=True),
    Column("questao_id", BigInteger, ForeignKey("questao.id", ondelete="CASCADE"), primary_key=True),
    Column("tentativas", Integer, nullable=False, server_default="0"),
    Column("acertou", Boolean, nullable=False, server_default="false"),
    Column("acertou_primeira", Boolean, nullable=False, server_default="false"),
    Column("respondida_em", DateTime(timezone=True), nullable=True),
    _created_at(),
)


# ─────────────────── 4. Progressão, XP e recompensas — isolado (A) ───────────────────

aluno_progresso = Table(
    "aluno_progresso",
    metadata,
    Column("usuario_id", BigInteger, ForeignKey("usuario.id", ondelete="CASCADE"), primary_key=True),
    Column("xp_total", BigInteger, nullable=False, server_default="0"),
    Column("no_atual_id", BigInteger, ForeignKey("trilha_no.id", ondelete="SET NULL"), nullable=True),
    Column("palavras_dominadas", Integer, nullable=False, server_default="0"),
    Column("combo_atual", Integer, nullable=False, server_default="0"),
    Column("combo_data", Date, nullable=True),
    Column("nivel_dificuldade_atual", Integer, nullable=False, server_default="1"),
    Column("sessoes_total", Integer, nullable=False, server_default="0"),
    Column("nivel_mudou_em_sessao", Integer, nullable=True),  # cooldown da histerese
    _created_at(),
    CheckConstraint(
        "nivel_dificuldade_atual BETWEEN 1 AND 10", name="nivel_range"
    ),
)

aluno_colecionavel = Table(
    "aluno_colecionavel",
    metadata,
    _id(),
    Column("usuario_id", BigInteger, ForeignKey("usuario.id", ondelete="CASCADE"), nullable=False),
    Column("colecionavel_id", BigInteger, ForeignKey("colecionavel.id", ondelete="CASCADE"), nullable=False),
    Column("ganho_em", DateTime(timezone=True), nullable=False, server_default=func.now()),
    _created_at(),
    UniqueConstraint("usuario_id", "colecionavel_id", name="aluno_colecionavel_unico"),
)


# ─────────────────── 5. Trilha e colecionáveis — catálogo global (A) ───────────────────

pais = Table(
    "pais",
    metadata,
    _id(),
    Column("nome", Text, nullable=False),
    Column("ordem", Integer, nullable=False),
    _created_at(),
)

destino = Table(
    "destino",
    metadata,
    _id(),
    Column("pais_id", BigInteger, ForeignKey("pais.id", ondelete="CASCADE"), nullable=False),
    Column("nome", Text, nullable=False),
    Column("ordem", Integer, nullable=False),
    _created_at(),
)

trilha_no = Table(
    "trilha_no",
    metadata,
    _id(),
    Column("destino_id", BigInteger, ForeignKey("destino.id", ondelete="CASCADE"), nullable=False),
    Column("ordem", Integer, nullable=False),
    Column("xp_limiar", Integer, nullable=False),
    _created_at(),
)

colecionavel = Table(
    "colecionavel",
    metadata,
    _id(),
    Column("tipo", Text, nullable=False),
    Column("referencia", Text, nullable=True),  # destino/país/feito
    Column("asset_ref", Text, nullable=True),
    _created_at(),
    CheckConstraint(
        "tipo IN ('cartao_postal','carimbo','selo')", name="tipo_valido"
    ),
)


# ─────────────────── 6. Redações — isolado por escola (C; mock em A) ───────────────────

redacao_atribuicao = Table(
    "redacao_atribuicao",
    metadata,
    _id(),
    Column("turma_id", BigInteger, ForeignKey("turma.id", ondelete="CASCADE"), nullable=False),
    Column("professor_associacao_id", BigInteger, ForeignKey("associacao.id", ondelete="SET NULL"), nullable=True),
    Column("tema", Text, nullable=False),
    Column("prazo", Date, nullable=True),
    _created_at(),
)

redacao = Table(
    "redacao",
    metadata,
    _id(),
    Column("atribuicao_id", BigInteger, ForeignKey("redacao_atribuicao.id", ondelete="CASCADE"), nullable=False),
    Column("usuario_id", BigInteger, ForeignKey("usuario.id", ondelete="CASCADE"), nullable=False),
    Column("formato", Text, nullable=False),
    Column("arquivo_ref", Text, nullable=True),  # R2
    Column("texto_extraido", Text, nullable=True),
    Column("status", Text, nullable=False, server_default="enviada"),
    Column("enviada_em", DateTime(timezone=True), nullable=True),
    Column("analisada_em", DateTime(timezone=True), nullable=True),
    _created_at(),
    CheckConstraint("formato IN ('manuscrita','digital')", name="formato_valido"),
    CheckConstraint(
        "status IN ('enviada','processando','analisada','erro_ingestao','erro_analise')",
        name="status_valido",
    ),
)

redacao_analise = Table(
    "redacao_analise",
    metadata,
    Column("redacao_id", BigInteger, ForeignKey("redacao.id", ondelete="CASCADE"), primary_key=True),
    Column("anotacoes", JSONB, nullable=False),  # por dimensão
    _created_at(),
)

redacao_palavra = Table(
    "redacao_palavra",
    metadata,
    _id(),
    Column("redacao_id", BigInteger, ForeignKey("redacao.id", ondelete="CASCADE"), nullable=False),
    Column("texto", Text, nullable=False),
    Column("lema", Text, nullable=False),
    Column("tipo", Text, nullable=False),
    Column("virou_atribuicao", Boolean, nullable=False, server_default="false"),
    _created_at(),
    CheckConstraint("tipo IN ('fraca','superutilizada')", name="tipo_valido"),
)

sinal_turma = Table(
    "sinal_turma",
    metadata,
    _id(),
    Column("turma_id", BigInteger, ForeignKey("turma.id", ondelete="CASCADE"), nullable=False),
    Column("palavra_id", BigInteger, ForeignKey("palavra.id", ondelete="CASCADE"), nullable=False),
    Column("periodo", Text, nullable=False),
    Column("pct", Numeric(5, 2), nullable=False),
    Column("computado_em", DateTime(timezone=True), nullable=False, server_default=func.now()),
    _created_at(),
    UniqueConstraint("turma_id", "palavra_id", "periodo", name="sinal_turma_unico"),
)


# ─────────────────── 7. Configuração de turma — isolado (C; default em A) ───────────────────

turma_config = Table(
    "turma_config",
    metadata,
    Column("turma_id", BigInteger, ForeignKey("turma.id", ondelete="CASCADE"), primary_key=True),
    Column("meta_semanal", Integer, nullable=True),  # palavras dominadas/semana
    Column("preset_rigor", JSONB, nullable=True),
    _created_at(),
)


# ─────────────────────────── 8. Telemetria — isolado (C) ───────────────────────────

sessao = Table(
    "sessao",
    metadata,
    _id(),
    Column("usuario_id", BigInteger, ForeignKey("usuario.id", ondelete="CASCADE"), nullable=False),
    Column("iniciada_em", DateTime(timezone=True), nullable=False, server_default=func.now()),
    Column("finalizada_em", DateTime(timezone=True), nullable=True),
    Column("xp_ganho", Integer, nullable=False, server_default="0"),
    _created_at(),
)

evento = Table(
    "evento",
    metadata,
    _id(),
    Column("usuario_id", BigInteger, ForeignKey("usuario.id", ondelete="CASCADE"), nullable=True),
    Column("tipo", Text, nullable=False),
    Column("payload", JSONB, nullable=True),
    _created_at(),
)
