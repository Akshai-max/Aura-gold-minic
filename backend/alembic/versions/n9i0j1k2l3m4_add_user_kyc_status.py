"""add_user_kyc_status

Revision ID: n9i0j1k2l3m4
Revises: m8h9i0j1k2l3
Create Date: 2026-06-23 18:30:00.000000

"""

from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op

revision: str = "n9i0j1k2l3m4"
down_revision: Union[str, None] = "m8h9i0j1k2l3"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column(
        "users",
        sa.Column(
            "kyc_status",
            sa.String(length=20),
            nullable=False,
            server_default="not_started",
        ),
    )


def downgrade() -> None:
    op.drop_column("users", "kyc_status")
