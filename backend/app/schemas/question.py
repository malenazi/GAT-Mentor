from pydantic import BaseModel, Field


class QuestionOut(BaseModel):
    id: int
    concept_id: int
    concept_name: str | None = None
    topic_name: str | None = None
    text: str
    difficulty: int
    option_a: str
    option_b: str
    option_c: str
    option_d: str
    expected_time_seconds: int
    tags: str | None = None

    class Config:
        from_attributes = True


class QuestionDetail(QuestionOut):
    correct_option: str
    explanation: str
    hint: str | None = None
    why_wrong_a: str | None = None
    why_wrong_b: str | None = None
    why_wrong_c: str | None = None
    why_wrong_d: str | None = None


class HintResponse(BaseModel):
    question_id: int
    hint: str | None = None


class BatchRequest(BaseModel):
    count: int = Field(default=10, ge=1, le=50)
    topic_id: int | None = None
    concept_id: int | None = None
    difficulty: int | None = Field(default=None, ge=1, le=5)


class QuestionCreate(BaseModel):
    concept_id: int
    text: str
    difficulty: int = Field(default=3, ge=1, le=5)
    option_a: str
    option_b: str
    option_c: str
    option_d: str
    correct_option: str = Field(..., pattern="^[abcd]$")
    explanation: str
    hint: str | None = None
    why_wrong_a: str | None = None
    why_wrong_b: str | None = None
    why_wrong_c: str | None = None
    why_wrong_d: str | None = None
    expected_time_seconds: int = 90
    tags: str | None = None
