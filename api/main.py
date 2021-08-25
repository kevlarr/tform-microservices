from datetime import datetime
from os import environ

from fastapi import FastAPI
from sqlalchemy import create_engine, Column, DateTime
from sqlalchemy.orm import sessionmaker
from sqlalchemy.exc import NoResultFound
from sqlalchemy.ext.declarative import declarative_base

ENGINE = create_engine(environ.get("SQLALCHEMY_URL"))

ModelBase = declarative_base(bind=ENGINE)
Session = sessionmaker(bind=ENGINE)

class SingleThing(ModelBase):
    __tablename__ = "singlething"
    updated_at = Column(DateTime, primary_key=True)

app = FastAPI()

@app.get("/")
async def root():
    with Session() as session:
        try:
            result = session.query(SingleThing).one()
        except NoResultFound:
            result = SingleThing(updated_at=datetime.utcnow())
            session.add(result)
            session.commit()

        return {"updated_at": result.updated_at}
