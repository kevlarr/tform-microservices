from datetime import datetime
from os import environ

from fastapi import FastAPI
from fastapi.responses import HTMLResponse
import requests

app = FastAPI()

@app.get("/", response_class=HTMLResponse)
async def root():
    api_url = environ.get("API_URL")
    resp = requests.get(api_url).json()

    dt = datetime.fromisoformat(resp["updated_at"])
    date = dt.strftime("%Y-%m-%d")
    time = dt.strftime("%I:%M:%S %p")

    return f"""
    <html>
        <head>
            <style>
                html, body {{
                    height: 100%;
                }}

                body {{
                    align-items: center;
                    display: flex;
                    flex-direction: column;
                    justify-content: center;
                }}
            </style>
        </head>
        <body>
            <h1>{date}</h1>
            <p>{time}</p>
        </body>
    </html>
    """
