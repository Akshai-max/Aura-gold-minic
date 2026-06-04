"""investment foundation

Revision ID: 0002_investment_foundation
Revises: 0001_initial
Create Date: 2026-06-04
"""

from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op

revision: str = "0002_investment_foundation"
down_revision: str | None = "0001_initial"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.create_table(
        "wallets",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("user_id", sa.Integer(), sa.ForeignKey("users.id"), nullable=False),
        sa.Column("gold_balance", sa.Numeric(14, 4), nullable=False, server_default="0"),
        sa.Column("available_gold", sa.Numeric(14, 4), nullable=False, server_default="0"),
        sa.Column("locked_gold", sa.Numeric(14, 4), nullable=False, server_default="0"),
        sa.Column("pending_gold", sa.Numeric(14, 4), nullable=False, server_default="0"),
        sa.Column("total_invested", sa.Numeric(14, 2), nullable=False, server_default="0"),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now()),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.func.now()),
        sa.UniqueConstraint("user_id"),
    )
    op.create_index("ix_wallets_user_id", "wallets", ["user_id"])
    op.create_table(
        "portfolio_snapshots",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("user_id", sa.Integer(), sa.ForeignKey("users.id"), nullable=False),
        sa.Column("portfolio_value", sa.Numeric(14, 2), nullable=False, server_default="0"),
        sa.Column("profit_loss", sa.Numeric(14, 2), nullable=False, server_default="0"),
        sa.Column("snapshot_date", sa.Date(), nullable=False),
    )
    op.create_index("ix_portfolio_snapshots_user_id", "portfolio_snapshots", ["user_id"])
    op.create_index(
        "ix_portfolio_snapshots_snapshot_date",
        "portfolio_snapshots",
        ["snapshot_date"],
    )
    op.create_table(
        "gold_prices",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("gold_type", sa.String(length=20), nullable=False, server_default="24K"),
        sa.Column("price", sa.Numeric(14, 2), nullable=False),
        sa.Column("source", sa.String(length=80), nullable=False, server_default="Admin Price Feed"),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now()),
    )
    op.create_table(
        "transactions",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("user_id", sa.Integer(), sa.ForeignKey("users.id"), nullable=False),
        sa.Column("transaction_type", sa.String(length=20), nullable=False),
        sa.Column("gold_amount", sa.Numeric(14, 4), nullable=False, server_default="0"),
        sa.Column("gold_price", sa.Numeric(14, 2), nullable=False, server_default="0"),
        sa.Column("amount", sa.Numeric(14, 2), nullable=False, server_default="0"),
        sa.Column("status", sa.String(length=30), nullable=False, server_default="PENDING"),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now()),
    )
    op.create_index("ix_transactions_user_id", "transactions", ["user_id"])
    op.create_index("ix_transactions_transaction_type", "transactions", ["transaction_type"])
    op.create_index("ix_transactions_status", "transactions", ["status"])
    op.create_table(
        "gold_settings",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column(
            "auto_price_feed_enabled",
            sa.Boolean(),
            nullable=False,
            server_default=sa.text("true"),
        ),
        sa.Column(
            "current_provider",
            sa.String(length=80),
            nullable=False,
            server_default="Manual Price Feed",
        ),
        sa.Column(
            "update_frequency",
            sa.String(length=40),
            nullable=False,
            server_default="5 minutes",
        ),
        sa.Column("manual_override_price", sa.Numeric(14, 2), nullable=False, server_default="0"),
    )


def downgrade() -> None:
    op.drop_table("gold_settings")
    op.drop_index("ix_transactions_status", table_name="transactions")
    op.drop_index("ix_transactions_transaction_type", table_name="transactions")
    op.drop_index("ix_transactions_user_id", table_name="transactions")
    op.drop_table("transactions")
    op.drop_table("gold_prices")
    op.drop_index("ix_portfolio_snapshots_snapshot_date", table_name="portfolio_snapshots")
    op.drop_index("ix_portfolio_snapshots_user_id", table_name="portfolio_snapshots")
    op.drop_table("portfolio_snapshots")
    op.drop_index("ix_wallets_user_id", table_name="wallets")
    op.drop_table("wallets")
