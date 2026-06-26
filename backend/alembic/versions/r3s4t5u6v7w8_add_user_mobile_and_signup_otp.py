"""add user mobile and signup otp challenges

Revision ID: r3s4t5u6v7w8
Revises: q2r3s4t5u6v7
Create Date: 2026-06-24
"""

from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op

revision: str = "r3s4t5u6v7w8"
down_revision: Union[str, None] = "q2r3s4t5u6v7"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column(
        "users",
        sa.Column("mobile_number", sa.String(length=15), nullable=True),
    )
    op.add_column(
        "users",
        sa.Column(
            "mobile_verified",
            sa.Boolean(),
            nullable=False,
            server_default=sa.false(),
        ),
    )
    op.create_index(
        "ix_users_mobile_active",
        "users",
        ["mobile_number"],
        unique=True,
        postgresql_where=sa.text("is_deleted = false AND mobile_number IS NOT NULL"),
    )

    op.create_table(
        "signup_otp_challenges",
        sa.Column("id", sa.Uuid(), nullable=False),
        sa.Column("mobile_number", sa.String(length=15), nullable=False),
        sa.Column("otp_hash", sa.String(length=128), nullable=False),
        sa.Column("expires_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("attempts", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("verified", sa.Boolean(), nullable=False, server_default=sa.false()),
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
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index(
        "ix_signup_otp_mobile_created",
        "signup_otp_challenges",
        ["mobile_number", "created_at"],
    )


def downgrade() -> None:
    op.drop_index("ix_signup_otp_mobile_created", table_name="signup_otp_challenges")
    op.drop_table("signup_otp_challenges")
    op.drop_index("ix_users_mobile_active", table_name="users")
    op.drop_column("users", "mobile_verified")
    op.drop_column("users", "mobile_number")
