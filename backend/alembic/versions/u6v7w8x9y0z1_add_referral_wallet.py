"""add referral and wallet fields

Revision ID: u6v7w8x9y0z1
Revises: t5u6v7w8x9y0
Create Date: 2026-06-25
"""

import secrets
from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op
from sqlalchemy.dialects.postgresql import UUID

revision: str = "u6v7w8x9y0z1"
down_revision: Union[str, None] = "t5u6v7w8x9y0"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def _generate_code() -> str:
    return secrets.token_hex(4).upper()


def upgrade() -> None:
    op.add_column(
        "users",
        sa.Column("referral_code", sa.String(length=16), nullable=True),
    )
    op.add_column(
        "users",
        sa.Column(
            "referred_by_user_id",
            UUID(as_uuid=True),
            sa.ForeignKey("users.id", ondelete="SET NULL"),
            nullable=True,
        ),
    )
    op.add_column(
        "users",
        sa.Column("referral_scheme_grams", sa.Numeric(18, 4), nullable=True),
    )
    op.add_column(
        "users",
        sa.Column(
            "wallet_balance_inr",
            sa.Numeric(18, 2),
            nullable=False,
            server_default="0",
        ),
    )
    op.create_index("ix_users_referral_code", "users", ["referral_code"], unique=True)

    conn = op.get_bind()
    rows = conn.execute(
        sa.text("SELECT id FROM users WHERE is_deleted = false")
    ).fetchall()
    used: set[str] = set()
    for row in rows:
        code = _generate_code()
        while code in used:
            code = _generate_code()
        used.add(code)
        conn.execute(
            sa.text("UPDATE users SET referral_code = :code WHERE id = :user_id"),
            {"code": code, "user_id": row.id},
        )

    op.create_table(
        "referral_rewards",
        sa.Column("id", UUID(as_uuid=True), primary_key=True),
        sa.Column(
            "referrer_id",
            UUID(as_uuid=True),
            sa.ForeignKey("users.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column(
            "referee_id",
            UUID(as_uuid=True),
            sa.ForeignKey("users.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column("scheme_grams", sa.Numeric(18, 4), nullable=False),
        sa.Column("reward_inr", sa.Numeric(18, 2), nullable=False),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.func.now(),
            nullable=False,
        ),
        sa.UniqueConstraint(
            "referrer_id", "referee_id", name="uq_referral_rewards_referrer_referee"
        ),
    )
    op.create_index(
        "ix_referral_rewards_referrer_id", "referral_rewards", ["referrer_id"]
    )


def downgrade() -> None:
    op.drop_index("ix_referral_rewards_referrer_id", table_name="referral_rewards")
    op.drop_table("referral_rewards")
    op.drop_index("ix_users_referral_code", table_name="users")
    op.drop_column("users", "wallet_balance_inr")
    op.drop_column("users", "referral_scheme_grams")
    op.drop_column("users", "referred_by_user_id")
    op.drop_column("users", "referral_code")
