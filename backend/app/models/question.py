from datetime import datetime

from sqlalchemy import Boolean, Column, DateTime, ForeignKey, Integer, String
from sqlalchemy.orm import relationship

from app.database import Base


class Question(Base):
    __tablename__ = "questions"

    id = Column(Integer, primary_key=True, index=True)
    concept_id = Column(Integer, ForeignKey("concepts.id"), nullable=False)
    text = Column(String, nullable=False)
    difficulty = Column(Integer, default=3)  # 1-5
    option_a = Column(String, nullable=False)
    option_b = Column(String, nullable=False)
    option_c = Column(String, nullable=False)
    option_d = Column(String, nullable=False)
    correct_option = Column(String, nullable=False)  # "a", "b", "c", "d"
    explanation = Column(String, nullable=False)  # Step-by-step solution
    hint = Column(String, nullable=True)
    why_wrong_a = Column(String, nullable=True)
    why_wrong_b = Column(String, nullable=True)
    why_wrong_c = Column(String, nullable=True)
    why_wrong_d = Column(String, nullable=True)
    expected_time_seconds = Column(Integer, default=90)
    tags = Column(String, nullable=True)  # Comma-separated
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime, default=datetime.utcnow)

    concept = relationship("Concept", back_populates="questions")
    attempts = relationship("Attempt", back_populates="question")
