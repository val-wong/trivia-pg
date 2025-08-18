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

# create tables on import (fine for dev)
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

# ---- put the fixed route BEFORE the dynamic one ----
@app.get("/questions/random", response_model=schemas.QuestionOut)
def random_q(db: Session = Depends(get_db)):
    q = crud.random_question(db)
    if not q:
        raise HTTPException(status_code=404, detail="No data")
    return q
# ----------------------------------------------------

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
