# seed_questions.py
import json, sys
from sqlalchemy.orm import Session
from app.db import engine, SessionLocal
from app.models import Base, Question

Base.metadata.create_all(bind=engine)

def seed(path: str):
    with open(path, "r", encoding="utf-8") as f:
        data = json.load(f)
    inserted = 0
    with SessionLocal() as db:  # type: Session
        for row in data:
            q_text = row["question"].strip()
            # skip if already exists (unique by question)
            exists = db.query(Question).filter(Question.question == q_text).first()
            if exists:
                continue
            q = Question(
                question=q_text,
                option_a=row["option_a"],
                option_b=row["option_b"],
                option_c=row["option_c"],
                option_d=row["option_d"],
                correct_answer=row["correct_answer"],
                tags=row.get("tags", ""),
            )
            db.add(q)
            inserted += 1
        db.commit()
    print(f"Seeded {inserted} new questions")

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python seed_questions.py <path-to-json>")
        sys.exit(1)
    seed(sys.argv[1])