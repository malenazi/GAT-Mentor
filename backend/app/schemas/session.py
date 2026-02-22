from datetime import datetime

from pydantic import BaseModel, Field


class StartSessionRequest(BaseModel):
    session_type: str = Field(..., pattern="^(timed_set|exam_simulation|practice|review)$")
    question_count: int = Field(default=10, ge=5, le=50)
    topic_id: int | None = None
    difficulty: int | None = Field(default=None, ge=1, le=5)


class SessionResponse(BaseModel):
    id: int
    session_type: str
    question_count: int
    started_at: datetime
    questions: list[dict] = []  # QuestionOut items

    class Config:
        from_attributes = True


class SessionSubmission(BaseModel):
    answers: list[dict]  # [{question_id, selected_option, time_taken_seconds}]


class TopicBreakdown(BaseModel):
    topic_name: str
    correct: int
    total: int
    accuracy: float
    avg_time: float


class SessionResult(BaseModel):
    session_id: int
    session_type: str
    total_questions: int
    correct_count: int
    accuracy: float
    total_time_seconds: int
    avg_time_per_question: float
    topic_breakdown: list[TopicBreakdown]
    score_percentile: float | None = None

    class Config:
        from_attributes = True


class SessionSummary(BaseModel):
    id: int
    session_type: str
    question_count: int
    correct_count: int
    total_time_seconds: int
    started_at: datetime
    is_completed: bool

    class Config:
        from_attributes = True
