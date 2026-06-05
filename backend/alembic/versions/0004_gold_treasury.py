"""gold treasury table

Revision ID: 0004_gold_treasury
Revises: 91283168432c
Create Date: 2026-06-05
"""

from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op

revision: str = "0004_gold_treasury"
down_revision: str | None = "91283168432c"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.create_table(
        "gold_treasury",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("available_gold", sa.Numeric(14, 4), nullable=False, server_default="0"),
        sa.Column("total_supplied", sa.Numeric(14, 4), nullable=False, server_default="0"),
        sa.Column("updated_by", sa.Integer(), sa.ForeignKey("users.id"), nullable=True),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.func.now()),
    )


def downgrade() -> None:
    op.drop_table("gold_treasury")
