FROM python:3.9.6-slim

RUN pip install \
    uvicorn \
    fastapi \
    requests

WORKDIR /app
COPY main.py .

ENTRYPOINT ["python", "main.py"]
