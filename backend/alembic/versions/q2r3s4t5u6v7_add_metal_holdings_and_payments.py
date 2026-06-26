"""add metal holdings and payment orders

Revision ID: q2r3s4t5u6v7
Revises: p1q2r3s4t5u6
Create Date: 2026-06-23
"""

from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op

revision: str = "q2r3s4t5u6v7"
down_revision: Union[str, None] = "p1q2r3s4t5u6"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column(
        "users",
        sa.Column(
            "gold_savings_grams",
            sa.Numeric(18, 4),
            nullable=False,
            server_default="0",
        ),
    )
    op.add_column(
        "users",
        sa.Column(
            "silver_savings_grams",
            sa.Numeric(18, 4),
            nullable=False,
            server_default="0",
        ),
    )
    op.create_table(
        "payment_orders",
        sa.Column("id", sa.Uuid(), nullable=False),
        sa.Column("user_id", sa.Uuid(), nullable=False),
        sa.Column("razorpay_order_id", sa.String(length=64), nullable=False),
        sa.Column("razorpay_payment_id", sa.String(length=64), nullable=True),
        sa.Column("metal", sa.String(length=16), nullable=False),
        sa.Column("amount_paise", sa.Integer(), nullable=False),
        sa.Column("grams", sa.Numeric(18, 4), nullable=False),
        sa.Column("rate_per_gram", sa.Numeric(18, 2), nullable=False),
        sa.Column("status", sa.String(length=20), nullable=False, server_default="created"),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.Column("paid_at", sa.DateTime(timezone=True), nullable=True),
        sa.ForeignKeyConstraint(["user_id"], ["users.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("razorpay_order_id"),
    )
    op.create_index("ix_payment_orders_user_id", "payment_orders", ["user_id"])


def downgrade() -> None:
    op.drop_index("ix_payment_orders_user_id", table_name="payment_orders")
    op.drop_table("payment_orders")
    op.drop_column("users", "silver_savings_grams")
    op.drop_column("users", "gold_savings_grams")
