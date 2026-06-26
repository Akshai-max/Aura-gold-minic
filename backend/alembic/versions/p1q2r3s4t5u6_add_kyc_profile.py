"""add_kyc_profile

Revision ID: p1q2r3s4t5u6
Revises: o0p1q2r3s4t5
Create Date: 2026-06-23

"""

from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op

revision: str = "p1q2r3s4t5u6"
down_revision: Union[str, None] = "o0p1q2r3s4t5"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column("users", sa.Column("kyc_profile", sa.Text(), nullable=True))


def downgrade() -> None:
    op.drop_column("users", "kyc_profile")
