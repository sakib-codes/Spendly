import os
from sqlmodel import create_engine, Session
from dotenv import load_dotenv

# Load variables from the .env file
load_dotenv()

DATABASE_URL = os.getenv("DATABASE_URL")

if not DATABASE_URL:
    raise ValueError("DATABASE_URL is missing from environment variables!")

# We explicitly tell SQLAlchemy to use psycopg2
DATABASE_URL = DATABASE_URL.replace("postgresql://", "postgresql+psycopg2://")

# Create the engine that talks to Neon
engine = create_engine(DATABASE_URL, echo=True)

# Dependency for FastAPI to get a database session
def get_session():
    with Session(engine) as session:
        yield session
