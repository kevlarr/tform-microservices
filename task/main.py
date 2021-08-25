from datetime import datetime
from os import environ
from time import sleep

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

def main():
    with Session() as session:
        result = session.query(SingleThing).one_or_none()

        if not result:
            print("No record found")
            return

        last_updated, result.updated_at = result.updated_at, datetime.utcnow()
        session.commit()

        print(f"Updated from {last_updated} to {result.updated_at}")

if __name__ == "__main__":
    main()
