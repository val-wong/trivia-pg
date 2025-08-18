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
