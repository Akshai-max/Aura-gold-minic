"""add gold savings scheme fields on users

Revision ID: t5u6v7w8x9y0
Revises: s4t5u6v7w8x9
Create Date: 2026-06-23
"""

from decimal import Decimal
from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op

revision: str = "t5u6v7w8x9y0"
down_revision: Union[str, None] = "s4t5u6v7w8x9"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None

_SCHEME_TIERS = (Decimal("1"), Decimal("5"), Decimal("10"))


def _tier_for_holdings(grams: Decimal) -> Decimal:
    for tier in _SCHEME_TIERS:
        if grams <= tier:
            return tier
    return Decimal("10")


def upgrade() -> None:
    op.add_column(
        "users",
        sa.Column(
            "gold_scheme_target_grams",
            sa.Numeric(18, 4),
            nullable=True,
        ),
    )
    op.add_column(
        "users",
        sa.Column(
            "gold_scheme_status",
            sa.String(length=20),
            nullable=False,
            server_default="not_selected",
        ),
    )
    op.add_column(
        "users",
        sa.Column(
            "gold_scheme_started_at",
            sa.DateTime(timezone=True),
            nullable=True,
        ),
    )

    conn = op.get_bind()
    rows = conn.execute(
        sa.text(
            "SELECT id, gold_savings_grams FROM users "
            "WHERE gold_savings_grams > 0 AND is_deleted = false"
        )
    ).fetchall()
    for row in rows:
        holdings = Decimal(str(row.gold_savings_grams or 0))
        if holdings <= 0:
            continue
        target = _tier_for_holdings(holdings)
        conn.execute(
            sa.text(
                "UPDATE users SET gold_scheme_target_grams = :target, "
                "gold_scheme_status = 'completed' "
                "WHERE id = :user_id"
            ),
            {"target": target, "user_id": row.id},
        )


def downgrade() -> None:
    op.drop_column("users", "gold_scheme_started_at")
    op.drop_column("users", "gold_scheme_status")
    op.drop_column("users", "gold_scheme_target_grams")
