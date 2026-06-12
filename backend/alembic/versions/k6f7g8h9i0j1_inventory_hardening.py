"""inventory_hardening

Revision ID: k6f7g8h9i0j1
Revises: j5e6f7g8h9i0
Create Date: 2026-06-08 20:00:00.000000

"""

from typing import Sequence, Union

from alembic import op

revision: str = "k6f7g8h9i0j1"
down_revision: Union[str, None] = "j5e6f7g8h9i0"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.execute(
        "CREATE INDEX IF NOT EXISTS ix_stock_movements_item_created "
        "ON stock_movements (inventory_item_id, created_at DESC)"
    )
    op.execute(
        "CREATE INDEX IF NOT EXISTS ix_inventory_items_low_stock "
        "ON inventory_items (stock_quantity) "
        "WHERE is_deleted = false AND stock_quantity <= reorder_level"
    )
    op.execute("CREATE EXTENSION IF NOT EXISTS pg_trgm")
    op.execute(
        "CREATE INDEX IF NOT EXISTS ix_inventory_items_item_name_trgm "
        "ON inventory_items USING gin (item_name gin_trgm_ops)"
    )


def downgrade() -> None:
    op.execute("DROP INDEX IF EXISTS ix_inventory_items_item_name_trgm")
    op.execute("DROP INDEX IF EXISTS ix_inventory_items_low_stock")
    op.execute("DROP INDEX IF EXISTS ix_stock_movements_item_created")
