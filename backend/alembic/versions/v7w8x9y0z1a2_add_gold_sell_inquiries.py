"""add gold sell inquiries

Revision ID: v7w8x9y0z1a2
Revises: u6v7w8x9y0z1
Create Date: 2026-06-25
"""

from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op
from sqlalchemy.dialects.postgresql import UUID

revision: str = "v7w8x9y0z1a2"
down_revision: Union[str, None] = "u6v7w8x9y0z1"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        "gold_sell_inquiries",
        sa.Column("id", UUID(as_uuid=True), primary_key=True, server_default=sa.text("gen_random_uuid()")),
        sa.Column("user_id", UUID(as_uuid=True), sa.ForeignKey("users.id", ondelete="CASCADE"), nullable=False),
        sa.Column("name", sa.String(length=200), nullable=False),
        sa.Column("mobile_number", sa.String(length=15), nullable=False),
        sa.Column("message", sa.Text(), nullable=False),
        sa.Column("status", sa.String(length=20), nullable=False, server_default="pending"),
        sa.Column("admin_response", sa.Text(), nullable=True),
        sa.Column("responded_by_user_id", UUID(as_uuid=True), sa.ForeignKey("users.id", ondelete="SET NULL"), nullable=True),
        sa.Column("responded_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False),
    )
    op.create_index("ix_gold_sell_inquiries_user_id", "gold_sell_inquiries", ["user_id"])
    op.create_index("ix_gold_sell_inquiries_status", "gold_sell_inquiries", ["status"])
    op.create_index("ix_gold_sell_inquiries_created_at", "gold_sell_inquiries", ["created_at"])


def downgrade() -> None:
    op.drop_index("ix_gold_sell_inquiries_created_at", table_name="gold_sell_inquiries")
    op.drop_index("ix_gold_sell_inquiries_status", table_name="gold_sell_inquiries")
    op.drop_index("ix_gold_sell_inquiries_user_id", table_name="gold_sell_inquiries")
    op.drop_table("gold_sell_inquiries")
