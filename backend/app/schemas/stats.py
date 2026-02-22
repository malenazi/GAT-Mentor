from pydantic import BaseModel


class ConceptMastery(BaseModel):
    concept_id: int
    concept_name: str
    topic_name: str
    mastery: float
    accuracy: float
    avg_time_seconds: float
    total_attempts: int
    current_streak: int

    class Config:
        from_attributes = True


class DashboardData(BaseModel):
    total_questions_done: int
    total_correct: int
    overall_accuracy: float
    avg_time_per_question: float
    current_streak: int
    longest_streak: int
    total_study_minutes: int
    mastery_summary: dict  # topic_name -> average mastery
    weakest_concepts: list[ConceptMastery]


class MasteryMap(BaseModel):
    topics: list[dict]  # [{topic_name, concepts: [{name, mastery, accuracy}]}]


class TrendPoint(BaseModel):
    date: str
    accuracy: float
    avg_time: float
    questions_done: int


class TrendData(BaseModel):
    daily_trends: list[TrendPoint]
    period: str  # "7d" or "30d"
