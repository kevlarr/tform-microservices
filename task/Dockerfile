FROM python:3.9.6-slim

RUN pip install sqlalchemy psycopg2-binary

WORKDIR /app
COPY run main.py ./

ENTRYPOINT ["./run"]
