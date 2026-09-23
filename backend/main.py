from fastapi import FastAPI, Depends
from sqlmodel import SQLModel, Session, select
from database import engine, get_session
from models import User

app = FastAPI(
    title="Spendly API",
    description="Backend API for the Spendly personal finance app.",
    version="1.0.0"
)

@app.on_event("startup")
def on_startup():
    # Automatically create the tables in Neon if they don't exist
    SQLModel.metadata.create_all(engine)

from sync import router as sync_router
app.include_router(sync_router)

@app.get("/")
def read_root():
    return {"message": "Hello from the Spendly API!"}

@app.get("/health")
def health_check():
    return {"status": "ok"}

@app.get("/debug-env")
def debug_env():
    import os
    secrets_dir = "/etc/secrets"
    secrets_files = os.listdir(secrets_dir) if os.path.exists(secrets_dir) else []
    
    return {
        "GOOGLE_APPLICATION_CREDENTIALS": os.environ.get("GOOGLE_APPLICATION_CREDENTIALS"),
        "secrets_dir_exists": os.path.exists(secrets_dir),
        "secrets_files": secrets_files
    }

@app.post("/users/", response_model=User)
def create_user(user: User, session: Session = Depends(get_session)):
    existing = session.get(User, user.firebase_uid)
    if existing:
        if user.email:
            existing.email = user.email
        if user.full_name:
            existing.full_name = user.full_name
        session.add(existing)
        session.commit()
        session.refresh(existing)
        return existing
    session.add(user)
    session.commit()
    session.refresh(user)
    return user

@app.get("/users/", response_model=list[User])
def get_users(session: Session = Depends(get_session)):
    users = session.exec(select(User)).all()
    return users

from auth import verify_token

@app.get("/auth-test")
def auth_test(token_data: dict = Depends(verify_token)):
    return {"message": "You are authenticated!", "uid": token_data.get("uid")}
