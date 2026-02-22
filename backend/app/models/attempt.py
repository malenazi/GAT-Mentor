import enum
from datetime import datetime

from sqlalchemy import Boolean, Column, DateTime, ForeignKey, Integer, String
from sqlalchemy.orm import relationship

from app.database import Base


class MistakeType(str, enum.Enum):
    CONCEPT_MISUNDERSTANDING = "concept_misunderstanding"
    CALCULATION_ERROR = "calculation_error"
    TIME_PRESSURE = "time_pressure"
    MISREAD_QUESTION = "misread_question"
    GUESSED = "guessed"


class Attempt(Base):
    __tablename__ = "attempts"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    question_id = Column(Integer, ForeignKey("questions.id"), nullable=False)
    selected_option = Column(String, nullable=False)
    is_correct = Column(Boolean, nullable=False)
    time_taken_seconds = Column(Integer, nullable=False)
    was_guessed = Column(Boolean, default=False)
    hint_used = Column(Boolean, default=False)
    mistake_type = Column(String, nullable=True)
    session_id = Column(Integer, ForeignKey("study_sessions.id"), nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)

    # Spaced repetition fields
    next_review_date = Column(DateTime, nullable=True)
    review_interval_days = Column(Integer, default=1)
    review_count = Column(Integer, default=0)

    user = relationship("User", back_populates="attempts")
    question = relationship("Question", back_populates="attempts")
    session = relationship("StudySession", back_populates="attempts")
