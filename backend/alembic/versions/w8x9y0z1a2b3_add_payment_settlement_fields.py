"""add payment settlement breakdown columns

Revision ID: w8x9y0z1a2b3
Revises: v7w8x9y0z1a2
Create Date: 2026-06-25
"""

from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op

revision: str = "w8x9y0z1a2b3"
down_revision: Union[str, None] = "v7w8x9y0z1a2"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column(
        "payment_orders",
        sa.Column("gst_percent", sa.Numeric(5, 2), nullable=True),
    )
    op.add_column(
        "payment_orders",
        sa.Column("metal_value_inr", sa.Numeric(18, 2), nullable=True),
    )
    op.add_column(
        "payment_orders",
        sa.Column("gst_amount_inr", sa.Numeric(18, 2), nullable=True),
    )
    op.add_column(
        "payment_orders",
        sa.Column("razorpay_fee_inr", sa.Numeric(18, 2), nullable=True),
    )
    op.add_column(
        "payment_orders",
        sa.Column("merchant_settlement_inr", sa.Numeric(18, 2), nullable=True),
    )


def downgrade() -> None:
    op.drop_column("payment_orders", "merchant_settlement_inr")
    op.drop_column("payment_orders", "razorpay_fee_inr")
    op.drop_column("payment_orders", "gst_amount_inr")
    op.drop_column("payment_orders", "metal_value_inr")
    op.drop_column("payment_orders", "gst_percent")
