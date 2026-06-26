"""add user bank accounts and link OTP challenges

Revision ID: s4t5u6v7w8x9
Revises: r3s4t5u6v7w8
Create Date: 2026-06-24
"""

from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op

revision: str = "s4t5u6v7w8x9"
down_revision: Union[str, None] = "r3s4t5u6v7w8"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        "user_bank_accounts",
        sa.Column("id", sa.Uuid(), nullable=False),
        sa.Column("user_id", sa.Uuid(), nullable=False),
        sa.Column("account_holder_name", sa.String(length=200), nullable=False),
        sa.Column("account_number_encrypted", sa.String(length=512), nullable=False),
        sa.Column("account_number_last4", sa.String(length=4), nullable=False),
        sa.Column("ifsc", sa.String(length=11), nullable=False),
        sa.Column("bank_name", sa.String(length=200), nullable=False),
        sa.Column("branch_name", sa.String(length=200), nullable=False),
        sa.Column("account_type", sa.String(length=20), nullable=False),
        sa.Column("is_primary", sa.Boolean(), nullable=False, server_default=sa.true()),
        sa.Column("verified_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.Column(
            "updated_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.ForeignKeyConstraint(["user_id"], ["users.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index(
        "ix_user_bank_accounts_user_id",
        "user_bank_accounts",
        ["user_id"],
    )

    op.create_table(
        "bank_link_challenges",
        sa.Column("id", sa.Uuid(), nullable=False),
        sa.Column("user_id", sa.Uuid(), nullable=False),
        sa.Column("account_holder_name", sa.String(length=200), nullable=False),
        sa.Column("account_number_encrypted", sa.String(length=512), nullable=False),
        sa.Column("account_number_last4", sa.String(length=4), nullable=False),
        sa.Column("ifsc", sa.String(length=11), nullable=False),
        sa.Column("bank_name", sa.String(length=200), nullable=False),
        sa.Column("branch_name", sa.String(length=200), nullable=False),
        sa.Column("account_type", sa.String(length=20), nullable=False),
        sa.Column("otp_hash", sa.String(length=128), nullable=False),
        sa.Column("expires_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("attempts", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("consumed", sa.Boolean(), nullable=False, server_default=sa.false()),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.Column(
            "updated_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.ForeignKeyConstraint(["user_id"], ["users.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index(
        "ix_bank_link_challenges_user_created",
        "bank_link_challenges",
        ["user_id", "created_at"],
    )


def downgrade() -> None:
    op.drop_index("ix_bank_link_challenges_user_created", table_name="bank_link_challenges")
    op.drop_table("bank_link_challenges")
    op.drop_index("ix_user_bank_accounts_user_id", table_name="user_bank_accounts")
    op.drop_table("user_bank_accounts")
