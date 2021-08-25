"""base-tables

Revision ID: 06e75175a803
Revises: 
Create Date: 2021-08-25 09:44:43.283430

"""
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = '06e75175a803'
down_revision = None
branch_labels = None
depends_on = None


def upgrade():
    op.execute("""
        CREATE TABLE singlething (
            updated_at timestamptz not null
        )
    """)


def downgrade():
    op.execute("""
        DROP TABLE singlething
    """)
