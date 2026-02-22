from datetime import datetime

from pydantic import BaseModel, Field


class OnboardingProfileRequest(BaseModel):
    level: str = Field(..., pattern="^(beginner|average|high_scorer)$")
    study_focus: str = Field(default="both", pattern="^(quant|verbal|both)$")
    exam_date: datetime | None = None
    daily_minutes: int = Field(default=45, ge=15, le=180)
    target_score: int = Field(default=70, ge=0, le=100)


class UpdateProfileRequest(BaseModel):
    full_name: str | None = None
    level: str | None = None
    study_focus: str | None = None
    exam_date: datetime | None = None
    daily_minutes: int | None = None
    target_score: int | None = None
