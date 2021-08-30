FROM python:3.9.6-slim

RUN pip install \
    alembic \
    fastapi \
    fastapi_utils \
    psycopg2-binary \
    sqlalchemy \
    uvicorn

WORKDIR /app
COPY main.py alembic.ini ./
COPY alembic/ ./alembic/

ENTRYPOINT ["python", "main.py"]
