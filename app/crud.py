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
