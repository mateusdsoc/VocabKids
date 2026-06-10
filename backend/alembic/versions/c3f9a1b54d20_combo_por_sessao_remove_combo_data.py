"""combo por sessao: remove aluno_progresso.combo_data

O combo é por sessão (produto 3.7, decidido 10/06): zera ao abrir cada sessão,
ao errar e ao acertar só na 2ª tentativa — não carrega entre sessões. O campo
`combo_data` (que fazia o combo zerar por dia) deixa de existir.

Revision ID: c3f9a1b54d20
Revises: 6ef923aa6272
Create Date: 2026-06-10 00:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'c3f9a1b54d20'
down_revision: Union[str, Sequence[str], None] = '6ef923aa6272'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Upgrade schema."""
    op.drop_column('aluno_progresso', 'combo_data')


def downgrade() -> None:
    """Downgrade schema."""
    op.add_column('aluno_progresso', sa.Column('combo_data', sa.Date(), nullable=True))
