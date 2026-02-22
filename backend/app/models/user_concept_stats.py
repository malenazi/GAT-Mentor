from datetime import datetime

from sqlalchemy import Column, DateTime, Float, ForeignKey, Integer, UniqueConstraint
from sqlalchemy.orm import relationship

from app.database import Base


class UserConceptStats(Base):
    __tablename__ = "user_concept_stats"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    concept_id = Column(Integer, ForeignKey("concepts.id"), nullable=False)
    mastery = Column(Float, default=0.0)  # 0.0 to 1.0
    difficulty_comfort = Column(Integer, default=1)  # 1-5
    total_attempts = Column(Integer, default=0)
    correct_attempts = Column(Integer, default=0)
    accuracy = Column(Float, default=0.0)
    avg_time_seconds = Column(Float, default=0.0)
    current_streak = Column(Integer, default=0)
    best_streak = Column(Integer, default=0)
    last_seen = Column(DateTime, nullable=True)
    last_correct = Column(DateTime, nullable=True)

    __table_args__ = (
        UniqueConstraint("user_id", "concept_id", name="uq_user_concept"),
    )

    user = relationship("User", back_populates="concept_stats")
    concept = relationship("Concept", back_populates="user_stats")
