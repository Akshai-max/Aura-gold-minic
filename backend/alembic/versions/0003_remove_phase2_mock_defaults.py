"""remove phase 2 mock defaults

Revision ID: 0003_remove_phase2_mock_defaults
Revises: 0002_investment_foundation
Create Date: 2026-06-04
"""

from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op

revision: str = "0003_remove_phase2_mock_defaults"
down_revision: str | None = "0002_investment_foundation"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.alter_column(
        "gold_prices",
        "source",
        server_default="Admin Price Feed",
        existing_type=sa.String(length=80),
    )
    op.alter_column(
        "gold_settings",
        "current_provider",
        server_default="Manual Price Feed",
        existing_type=sa.String(length=80),
    )
    op.execute(
        """
        UPDATE gold_settings
        SET current_provider = 'Manual Price Feed'
        WHERE current_provider = 'Mock Admin Feed'
        """
    )
    op.execute(
        """
        UPDATE wallets
        SET gold_balance = 0,
            available_gold = 0,
            locked_gold = 0,
            pending_gold = 0,
            total_invested = 0
        WHERE gold_balance = 18.7520
          AND available_gold = 17.1250
          AND locked_gold = 1.2500
          AND pending_gold = 0.3770
          AND total_invested = 121450.00
          AND NOT EXISTS (
              SELECT 1
              FROM transactions
              WHERE transactions.user_id = wallets.user_id
          )
        """
    )


def downgrade() -> None:
    op.alter_column(
        "gold_settings",
        "current_provider",
        server_default="Mock Admin Feed",
        existing_type=sa.String(length=80),
    )
    op.alter_column(
        "gold_prices",
        "source",
        server_default="Mock Admin Feed",
        existing_type=sa.String(length=80),
    )
