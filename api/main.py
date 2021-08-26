from datetime import datetime
from os import environ

from fastapi import FastAPI
from sqlalchemy import create_engine, Column, DateTime
from sqlalchemy.orm import sessionmaker
from sqlalchemy.exc import NoResultFound
from sqlalchemy.ext.declarative import declarative_base
import uvicorn

HOST = environ.get("HOST", "127.0.0.1")
PORT = int(environ.get("PORT", "8000"))


APP = FastAPI()


@APP.get("/")
async def root():
  return {"message": "Hello, world!"}


@APP.get("/thing")
async def thing():
    engine = create_engine(environ.get("SQLALCHEMY_URL"))

    ModelBase = declarative_base(bind=engine)
    Session = sessionmaker(bind=engine)

    class SingleThing(ModelBase):
      __tablename__ = "singlething"
      updated_at = Column(DateTime, primary_key=True)

    with Session() as session:
        try:
            result = session.query(SingleThing).one()
        except NoResultFound:
            result = SingleThing(updated_at=datetime.utcnow())
            session.add(result)
            session.commit()

        return {"updated_at": result.updated_at}


def main():
    uvicorn.run(APP, host=HOST, port=PORT)


if __name__ == "__main__":
    main()
