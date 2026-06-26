"""add gold and silver invested amount tracking

Revision ID: x9y0z1a2b3c4
Revises: w8x9y0z1a2b3
Create Date: 2026-06-25
"""

from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op

revision: str = "x9y0z1a2b3c4"
down_revision: Union[str, None] = "w8x9y0z1a2b3"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column(
        "users",
        sa.Column(
            "gold_invested_inr",
            sa.Numeric(18, 2),
            nullable=False,
            server_default="0",
        ),
    )
    op.add_column(
        "users",
        sa.Column(
            "silver_invested_inr",
            sa.Numeric(18, 2),
            nullable=False,
            server_default="0",
        ),
    )


def downgrade() -> None:
    op.drop_column("users", "silver_invested_inr")
    op.drop_column("users", "gold_invested_inr")
