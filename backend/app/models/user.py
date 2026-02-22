import enum
from datetime import datetime

from sqlalchemy import Boolean, Column, DateTime, Float, Integer, String
from sqlalchemy.orm import relationship

from app.database import Base


class StudentLevel(str, enum.Enum):
    BEGINNER = "beginner"
    AVERAGE = "average"
    HIGH_SCORER = "high_scorer"


class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    email = Column(String, unique=True, index=True, nullable=False)
    hashed_password = Column(String, nullable=False)
    full_name = Column(String, nullable=False)
    level = Column(String, default=StudentLevel.AVERAGE.value)
    exam_date = Column(DateTime, nullable=True)
    daily_minutes = Column(Integer, default=45)
    target_score = Column(Integer, default=70)
    study_focus = Column(String, default="both")  # "quant", "verbal", "both"
    is_admin = Column(Boolean, default=False)
    onboarding_complete = Column(Boolean, default=False)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    attempts = relationship("Attempt", back_populates="user")
    concept_stats = relationship("UserConceptStats", back_populates="user")
    study_sessions = relationship("StudySession", back_populates="user")
    daily_plans = relationship("DailyPlan", back_populates="user")
    streak = relationship("Streak", back_populates="user", uselist=False)
