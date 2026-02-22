import enum
from datetime import date, datetime

from sqlalchemy import Boolean, Column, Date, DateTime, ForeignKey, Integer, String
from sqlalchemy.orm import relationship

from app.database import Base


class PlanItemType(str, enum.Enum):
    WARMUP = "warmup"
    WEAK_TOPIC_DRILL = "weak_topic_drill"
    TIMED_SPRINT = "timed_sprint"
    MISTAKE_REVIEW = "mistake_review"
    MIXED_PRACTICE = "mixed_practice"


class DailyPlan(Base):
    __tablename__ = "daily_plans"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    date = Column(Date, nullable=False)
    total_minutes = Column(Integer, nullable=False)
    is_completed = Column(Boolean, default=False)
    created_at = Column(DateTime, default=datetime.utcnow)

    user = relationship("User", back_populates="daily_plans")
    items = relationship("DailyPlanItem", back_populates="plan", cascade="all, delete-orphan")


class DailyPlanItem(Base):
    __tablename__ = "daily_plan_items"

    id = Column(Integer, primary_key=True, index=True)
    plan_id = Column(Integer, ForeignKey("daily_plans.id"), nullable=False)
    item_type = Column(String, nullable=False)
    concept_id = Column(Integer, ForeignKey("concepts.id"), nullable=True)
    duration_minutes = Column(Integer, nullable=False)
    question_count = Column(Integer, default=5)
    difficulty_range_min = Column(Integer, default=1)
    difficulty_range_max = Column(Integer, default=5)
    display_order = Column(Integer, default=0)
    is_completed = Column(Boolean, default=False)

    plan = relationship("DailyPlan", back_populates="items")
