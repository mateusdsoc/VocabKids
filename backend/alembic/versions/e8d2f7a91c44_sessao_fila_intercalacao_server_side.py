"""sessao.fila: intercalacao de erro server-side

A fila de slots pendentes passa a ser persistida na sessão e reordenada pelo
servidor a cada resposta (revisão da decisão #3 do Bloco 3): a regra de
intercalação (3.4) vive num lugar só — o app renderiza a ordem que recebe.

Revision ID: e8d2f7a91c44
Revises: c3f9a1b54d20
Create Date: 2026-06-10 00:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects.postgresql import JSONB


# revision identifiers, used by Alembic.
revision: str = 'e8d2f7a91c44'
down_revision: Union[str, Sequence[str], None] = 'c3f9a1b54d20'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Upgrade schema."""
    op.add_column('sessao', sa.Column('fila', JSONB(), nullable=True))


def downgrade() -> None:
    """Downgrade schema."""
    op.drop_column('sessao', 'fila')
