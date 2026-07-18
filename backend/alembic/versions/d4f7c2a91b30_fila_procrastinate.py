"""fila procrastinate (tabelas do worker — Bloco 2b, fatia 2)

O schema vem do pacote instalado (`procrastinate/sql/schema.sql` — versão
lockada no uv.lock; 3.9 quando esta migration nasceu). Ao ATUALIZAR o
procrastinate no futuro, criar uma nova revision com os scripts de migração
que o pacote traz (`procrastinate/sql/migrations/`), mantendo a cadeia única.

O autogenerate ignora as tabelas `procrastinate_*` (filtro em env.py).

Revision ID: d4f7c2a91b30
Revises: bea8daf60f60
Create Date: 2026-07-18

"""
from importlib.resources import files
from typing import Sequence, Union

from alembic import op

# revision identifiers, used by Alembic.
revision: str = 'd4f7c2a91b30'
down_revision: Union[str, Sequence[str], None] = 'bea8daf60f60'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def _executar_cru(sql: str) -> None:
    """Executa na conexão do driver (psycopg), sem parâmetros.

    O schema tem `%`/`:=` em plpgsql; tanto o `text()` do SQLAlchemy quanto o
    parsing de placeholders do psycopg (ativado quando `parameters` não é
    None, mesmo vazio) quebrariam — direto no driver o SQL vai como está.
    """
    op.get_bind().connection.driver_connection.execute(sql)


def upgrade() -> None:
    """Aplica o schema da fila (tabelas/tipos/funções `procrastinate_*`)."""
    _executar_cru((files("procrastinate") / "sql" / "schema.sql").read_text())


def downgrade() -> None:
    """Derruba tudo que é da fila (prefixo `procrastinate_`)."""
    _executar_cru(
        """
        DO $$
        DECLARE fn record;
        BEGIN
            FOR fn IN
                SELECT p.oid::regprocedure AS assinatura
                FROM pg_proc p
                JOIN pg_namespace n ON n.oid = p.pronamespace
                WHERE n.nspname = current_schema()
                  AND p.proname LIKE 'procrastinate_%'
            LOOP
                EXECUTE 'DROP FUNCTION IF EXISTS ' || fn.assinatura || ' CASCADE';
            END LOOP;
        END $$;
        """
    )
    for tabela in (
        "procrastinate_periodic_defers",
        "procrastinate_events",
        "procrastinate_jobs",
        "procrastinate_workers",
    ):
        _executar_cru(f"DROP TABLE IF EXISTS {tabela} CASCADE")
    # Tipos (enums E compostos, ex.: procrastinate_job_to_defer_v1) — varre
    # pelo prefixo, como as funções, para não esquecer nenhum.
    _executar_cru(
        """
        DO $$
        DECLARE t record;
        BEGIN
            FOR t IN
                SELECT ty.typname
                FROM pg_type ty
                JOIN pg_namespace n ON n.oid = ty.typnamespace
                WHERE n.nspname = current_schema()
                  AND ty.typname LIKE 'procrastinate_%'
                  AND ty.typtype IN ('e', 'c', 'd')
            LOOP
                EXECUTE 'DROP TYPE IF EXISTS ' || quote_ident(t.typname) || ' CASCADE';
            END LOOP;
        END $$;
        """
    )
