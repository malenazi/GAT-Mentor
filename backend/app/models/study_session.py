import enum
from datetime import datetime

from sqlalchemy import Boolean, Column, DateTime, ForeignKey, Integer, String
from sqlalchemy.orm import relationship

from app.database import Base


class SessionType(str, enum.Enum):
    PRACTICE = "practice"
    TIMED_SET = "timed_set"
    DIAGNOSTIC = "diagnostic"
    REVIEW = "review"
    EXAM_SIMULATION = "exam_simulation"


class StudySession(Base):
    __tablename__ = "study_sessions"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    session_type = Column(String, nullable=False)
    question_count = Column(Integer, default=0)
    correct_count = Column(Integer, default=0)
    total_time_seconds = Column(Integer, default=0)
    started_at = Column(DateTime, default=datetime.utcnow)
    ended_at = Column(DateTime, nullable=True)
    is_completed = Column(Boolean, default=False)

    user = relationship("User", back_populates="study_sessions")
    attempts = relationship("Attempt", back_populates="session")
