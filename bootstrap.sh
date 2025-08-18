set -euo pipefail

# env for Postgres
cat > .env <<'EOF'
POSTGRES_USER=trivia
POSTGRES_PASSWORD=trivia
POSTGRES_DB=trivia
PGDATA=/var/lib/postgresql/data/pgdata
EOF

# docker-compose
cat > docker-compose.yml <<'EOF'
services:
  db:
    image: postgres:16
    env_file: .env
    environment:
      - POSTGRES_USER=${POSTGRES_USER}
      - POSTGRES_PASSWORD=${POSTGRES_PASSWORD}
      - POSTGRES_DB=${POSTGRES_DB}
      - PGDATA=${PGDATA}
    ports:
      - "5432:5432"
    volumes:
      - pgdata:${PGDATA}
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U $$POSTGRES_USER -d $$POSTGRES_DB"]
      interval: 5s
      timeout: 3s
      retries: 10
volumes:
  pgdata:
EOF

# requirements
cat > requirements.txt <<'EOF'
fastapi==0.115.0
uvicorn==0.30.6
SQLAlchemy==2.0.32
pydantic==2.9.1
psycopg[binary]==3.2.1
python-dotenv==1.0.1
EOF

# app package
mkdir -p app
: > app/__init__.py

cat > app/db.py <<'EOF'
import os
from dotenv import load_dotenv
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

load_dotenv()

def _build_db_url():
    url = os.getenv("DATABASE_URL")
    if url:
        return url
    user = os.getenv("POSTGRES_USER", "trivia")
    pwd = os.getenv("POSTGRES_PASSWORD", "trivia")
    db = os.getenv("POSTGRES_DB", "trivia")
    host = os.getenv("POSTGRES_HOST", "localhost")
    port = os.getenv("POSTGRES_PORT", "5432")
    return f"postgresql+psycopg://{user}:{pwd}@{host}:{port}/{db}"

DATABASE_URL = _build_db_url()
engine = create_engine(DATABASE_URL, pool_pre_ping=True)
SessionLocal = sessionmaker(bind=engine, autocommit=False, autoflush=False)

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
EOF

cat > app/models.py <<'EOF'
from sqlalchemy import Column, Integer, String, Text, DateTime, func
from sqlalchemy.orm import declarative_base

Base = declarative_base()

class Question(Base):
    __tablename__ = "questions"
    id = Column(Integer, primary_key=True, index=True)
    question = Column(Text, nullable=False, unique=True)
    option_a = Column(String(255), nullable=False)
    option_b = Column(String(255), nullable=False)
    option_c = Column(String(255), nullable=False)
    option_d = Column(String(255), nullable=False)
    correct_answer = Column(String(1), nullable=False)
    tags = Column(String(255), default="")
    created_at = Column(DateTime(timezone=True), server_default=func.now())
EOF

cat > app/schemas.py <<'EOF'
from pydantic import BaseModel, Field
from typing import Optional

class QuestionBase(BaseModel):
    question: str = Field(..., min_length=5)
    option_a: str
    option_b: str
    option_c: str
    option_d: str
    correct_answer: str = Field(..., pattern=r"^[ABCD]$")
    tags: Optional[str] = ""

class QuestionCreate(QuestionBase):
    pass

class QuestionUpdate(BaseModel):
    question: Optional[str] = None
    option_a: Optional[str] = None
    option_b: Optional[str] = None
    option_c: Optional[str] = None
    option_d: Optional[str] = None
    correct_answer: Optional[str] = None
    tags: Optional[str] = None

class QuestionOut(QuestionBase):
    id: int
    class Config:
        from_attributes = True
EOF

cat > app/crud.py <<'EOF'
from sqlalchemy.orm import Session
from sqlalchemy import select, or_, func
from . import models, schemas

def create_question(db: Session, data: schemas.QuestionCreate):
    q = models.Question(**data.model_dump())
    db.add(q)
    db.commit()
    db.refresh(q)
    return q

def get_question(db: Session, question_id: int):
    return db.get(models.Question, question_id)

def list_questions(db: Session, skip: int = 0, limit: int = 50):
    return db.execute(select(models.Question).offset(skip).limit(limit)).scalars().all()

def update_question(db: Session, question_id: int, data: schemas.QuestionUpdate):
    q = db.get(models.Question, question_id)
    if not q:
        return None
    for k, v in data.model_dump(exclude_unset=True).items():
        setattr(q, k, v)
    db.commit()
    db.refresh(q)
    return q

def delete_question(db: Session, question_id: int):
    q = db.get(models.Question, question_id)
    if not q:
        return False
    db.delete(q)
    db.commit()
    return True

def search_questions(db: Session, query: str, limit: int = 50):
    ilike = f"%{query}%"
    stmt = select(models.Question).where(
        or_(
            models.Question.question.ilike(ilike),
            models.Question.tags.ilike(ilike),
        )
    ).limit(limit)
    return db.execute(stmt).scalars().all()

def random_question(db: Session):
    stmt = select(models.Question).order_by(func.random()).limit(1)
    return db.execute(stmt).scalars().first()
EOF

cat > app/main.py <<'EOF'
from fastapi import FastAPI, Depends, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.orm import Session
from .db import engine, get_db
from .models import Base
from . import schemas, crud

app = FastAPI(title="Trivia API", version="0.1.0")

origins = [
    "http://localhost:5173",
    "http://127.0.0.1:5173",
]

app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

Base.metadata.create_all(bind=engine)

@app.get("/healthz")
def healthz():
    return {"ok": True}

@app.post("/questions", response_model=schemas.QuestionOut, status_code=201)
def create_question(payload: schemas.QuestionCreate, db: Session = Depends(get_db)):
    return crud.create_question(db, payload)

@app.get("/questions", response_model=list[schemas.QuestionOut])
def list_questions(skip: int = 0, limit: int = 50, db: Session = Depends(get_db)):
    return crud.list_questions(db, skip=skip, limit=limit)

@app.get("/questions/{question_id}", response_model=schemas.QuestionOut)
def get_question(question_id: int, db: Session = Depends(get_db)):
    q = crud.get_question(db, question_id)
    if not q:
        raise HTTPException(status_code=404, detail="Not found")
    return q

@app.patch("/questions/{question_id}", response_model=schemas.QuestionOut)
def patch_question(question_id: int, payload: schemas.QuestionUpdate, db: Session = Depends(get_db)):
    q = crud.update_question(db, question_id, payload)
    if not q:
        raise HTTPException(status_code=404, detail="Not found")
    return q

@app.delete("/questions/{question_id}", status_code=204)
def delete_question(question_id: int, db: Session = Depends(get_db)):
    ok = crud.delete_question(db, question_id)
    if not ok:
        raise HTTPException(status_code=404, detail="Not found")
    return

@app.get("/questions/search", response_model=list[schemas.QuestionOut])
def search(q: str, limit: int = 50, db: Session = Depends(get_db)):
    return crud.search_questions(db, q, limit)

@app.get("/questions/random", response_model=schemas.QuestionOut)
def random_q(db: Session = Depends(get_db)):
    q = crud.random_question(db)
    if not q:
        raise HTTPException(status_code=404, detail="No data")
    return q
EOF

# bring up db
docker compose up -d

# venv + deps
python3 -m venv .venv
. .venv/bin/activate
python -m pip install --upgrade pip
python -m pip install -r requirements.txt

# run api
uvicorn app.main:app --reload --port 8000
