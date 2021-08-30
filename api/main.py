from datetime import datetime
from os import environ

from fastapi import FastAPI
from fastapi_utils.tasks import repeat_every
from sqlalchemy import create_engine, Column, DateTime
from sqlalchemy.orm import sessionmaker
from sqlalchemy.exc import NoResultFound
from sqlalchemy.ext.declarative import declarative_base
import uvicorn

HOST = environ.get("HOST", "127.0.0.1")
PORT = int(environ.get("PORT", "8000"))


APP = FastAPI()
N_BACKGROUND = 0


ENGINE = create_engine(environ.get("SQLALCHEMY_URL"))

ModelBase = declarative_base(bind=ENGINE)
Session = sessionmaker(bind=ENGINE)

class SingleThing(ModelBase):
  __tablename__ = "singlething"
  updated_at = Column(DateTime, primary_key=True)


@APP.on_event("startup")
@repeat_every(seconds=5)
async def refresh_model():
    global N_BACKGROUND
    N_BACKGROUND += 1

    with Session() as session:
        result = session.query(SingleThing).one_or_none()

        if not result:
            print("No record found")
            return

        last_updated, result.updated_at = result.updated_at, datetime.utcnow()
        session.commit()

        print(f"Updated from {last_updated} to {result.updated_at}")



@APP.get("/")
async def root():
  return {"message": "Hello, world!"}


@APP.get("/thing")
async def thing():
    with Session() as session:
        try:
            result = session.query(SingleThing).one()
        except NoResultFound:
            result = SingleThing(updated_at=datetime.utcnow())
            session.add(result)
            session.commit()

        return {
            "updated_at": result.updated_at,
            "n_background": N_BACKGROUND,
        }


def main():
    uvicorn.run(APP, host=HOST, port=PORT)


if __name__ == "__main__":
    main()
