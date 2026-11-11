"""Remove redundant user_id-only index from translation history.

Revision ID: 0002_history_index_cleanup
Revises: 0001_initial
"""
from alembic import op

revision = "0002_history_index_cleanup"
down_revision = "0001_initial"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.drop_index("ix_translation_history_user_id", table_name="translation_history")


def downgrade() -> None:
    op.create_index(
        "ix_translation_history_user_id",
        "translation_history",
        ["user_id"],
        unique=False,
    )
