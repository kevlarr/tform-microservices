from datetime import datetime
from os import environ

from fastapi import FastAPI
from fastapi.responses import HTMLResponse
import requests
import uvicorn


API_URL = environ.get("API_URL")
HOST = environ.get("HOST", "127.0.0.1")
PORT = int(environ.get("PORT", "8001"))


APP = FastAPI()


@APP.get("/", response_class=HTMLResponse)
async def root():
    resp = requests.get(f"{API_URL}").json()
    msg = resp["message"]

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
            <h1>{msg}</h1>
        </body>
    </html>
    """


@APP.get("/thing", response_class=HTMLResponse)
async def thing():
    resp = requests.get(f"{API_URL}/thing").json()

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


def main():
    uvicorn.run(APP, host=HOST, port=PORT)


if __name__ == "__main__":
    main()
