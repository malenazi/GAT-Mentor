from datetime import datetime

from pydantic import BaseModel, Field


class AttemptCreate(BaseModel):
    question_id: int
    selected_option: str = Field(..., pattern="^[abcd]$")
    time_taken_seconds: int = Field(..., ge=0)
    was_guessed: bool = False
    hint_used: bool = False
    session_id: int | None = None


class AttemptResponse(BaseModel):
    id: int
    question_id: int
    selected_option: str
    is_correct: bool
    time_taken_seconds: int
    was_guessed: bool
    hint_used: bool
    mistake_type: str | None = None
    created_at: datetime

    # Enriched response fields
    correct_option: str | None = None
    explanation: str | None = None
    why_wrong: str | None = None
    mastery_change: float | None = None
    new_mastery: float | None = None

    class Config:
        from_attributes = True


class MistakeClassification(BaseModel):
    mistake_type: str = Field(
        ...,
        pattern="^(concept_misunderstanding|calculation_error|time_pressure|misread_question|guessed)$",
    )
