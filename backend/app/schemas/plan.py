from datetime import date

from pydantic import BaseModel, Field


class PlanItemOut(BaseModel):
    id: int
    item_type: str
    concept_id: int | None = None
    concept_name: str | None = None
    duration_minutes: int
    question_count: int
    difficulty_range_min: int
    difficulty_range_max: int
    display_order: int
    is_completed: bool

    class Config:
        from_attributes = True


class DailyPlanOut(BaseModel):
    id: int
    date: date
    total_minutes: int
    is_completed: bool
    items: list[PlanItemOut]

    class Config:
        from_attributes = True


class PlanSettings(BaseModel):
    exam_date: str | None = None
    daily_minutes: int = Field(default=45, ge=15, le=180)
    target_score: int = Field(default=70, ge=0, le=100)


class PlanItemComplete(BaseModel):
    is_completed: bool = True
