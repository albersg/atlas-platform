from collections.abc import Callable

from sqlalchemy import create_engine
from sqlalchemy.orm import DeclarativeBase, Session, sessionmaker


class Base(DeclarativeBase):
    pass


def create_session_factory(database_url: str) -> Callable[[], Session]:
    engine = create_engine(database_url, pool_pre_ping=True, future=True)
    return sessionmaker(bind=engine, expire_on_commit=False, autoflush=False)
