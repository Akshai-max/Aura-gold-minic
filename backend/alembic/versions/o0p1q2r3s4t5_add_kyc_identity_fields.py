"""add_kyc_identity_fields

Revision ID: o0p1q2r3s4t5
Revises: n9i0j1k2l3m4
Create Date: 2026-06-23 19:00:00.000000

"""

from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op

revision: str = "o0p1q2r3s4t5"
down_revision: Union[str, None] = "n9i0j1k2l3m4"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column("users", sa.Column("kyc_aadhaar_encrypted", sa.Text(), nullable=True))
    op.add_column(
        "users", sa.Column("kyc_aadhaar_last4", sa.String(length=4), nullable=True)
    )
    op.add_column(
        "users", sa.Column("kyc_pan_last4", sa.String(length=4), nullable=True)
    )


def downgrade() -> None:
    op.drop_column("users", "kyc_pan_last4")
    op.drop_column("users", "kyc_aadhaar_last4")
    op.drop_column("users", "kyc_aadhaar_encrypted")
