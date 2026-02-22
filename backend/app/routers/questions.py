from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import func
from sqlalchemy.orm import Session

from app.dependencies import get_current_user, get_db
from app.models.concept import Concept
from app.models.question import Question
from app.models.topic import Topic
from app.models.user import User
from app.schemas.question import BatchRequest, HintResponse, QuestionDetail, QuestionOut
from app.services.adaptive_engine import get_next_question

router = APIRouter()


@router.get("/next", response_model=QuestionOut)
def next_question(
    topic_id: int | None = None,
    concept_id: int | None = None,
    difficulty: int | None = None,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Get next question using adaptive engine."""
    question = get_next_question(
        db, current_user.id, topic_id, concept_id, difficulty
    )
    if not question:
        raise HTTPException(status_code=404, detail="No questions available")

    concept = db.query(Concept).get(question.concept_id)
    topic = db.query(Topic).get(concept.topic_id) if concept else None

    return QuestionOut(
        id=question.id,
        concept_id=question.concept_id,
        concept_name=concept.name if concept else None,
        topic_name=topic.name if topic else None,
        text=question.text,
        difficulty=question.difficulty,
        option_a=question.option_a,
        option_b=question.option_b,
        option_c=question.option_c,
        option_d=question.option_d,
        expected_time_seconds=question.expected_time_seconds,
        tags=question.tags,
    )


@router.get("/{question_id}", response_model=QuestionDetail)
def get_question(
    question_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Get full question with solution (for post-answer review)."""
    question = db.query(Question).get(question_id)
    if not question:
        raise HTTPException(status_code=404, detail="Question not found")

    concept = db.query(Concept).get(question.concept_id)
    topic = db.query(Topic).get(concept.topic_id) if concept else None

    return QuestionDetail(
        id=question.id,
        concept_id=question.concept_id,
        concept_name=concept.name if concept else None,
        topic_name=topic.name if topic else None,
        text=question.text,
        difficulty=question.difficulty,
        option_a=question.option_a,
        option_b=question.option_b,
        option_c=question.option_c,
        option_d=question.option_d,
        correct_option=question.correct_option,
        explanation=question.explanation,
        hint=question.hint,
        why_wrong_a=question.why_wrong_a,
        why_wrong_b=question.why_wrong_b,
        why_wrong_c=question.why_wrong_c,
        why_wrong_d=question.why_wrong_d,
        expected_time_seconds=question.expected_time_seconds,
        tags=question.tags,
    )


@router.get("/{question_id}/hint", response_model=HintResponse)
def get_hint(
    question_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    question = db.query(Question).get(question_id)
    if not question:
        raise HTTPException(status_code=404, detail="Question not found")
    return HintResponse(question_id=question.id, hint=question.hint)


@router.post("/batch")
def get_batch(
    request: BatchRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Get a batch of questions for timed sets."""
    query = db.query(Question).filter(Question.is_active == True)

    if request.topic_id:
        query = query.join(Concept).filter(Concept.topic_id == request.topic_id)
    if request.concept_id:
        query = query.filter(Question.concept_id == request.concept_id)
    if request.difficulty:
        query = query.filter(
            Question.difficulty.between(request.difficulty - 1, request.difficulty + 1)
        )

    questions = query.order_by(func.random()).limit(request.count).all()

    result = []
    for q in questions:
        concept = db.query(Concept).get(q.concept_id)
        topic = db.query(Topic).get(concept.topic_id) if concept else None
        result.append(
            {
                "id": q.id,
                "concept_id": q.concept_id,
                "concept_name": concept.name if concept else None,
                "topic_name": topic.name if topic else None,
                "text": q.text,
                "difficulty": q.difficulty,
                "option_a": q.option_a,
                "option_b": q.option_b,
                "option_c": q.option_c,
                "option_d": q.option_d,
                "expected_time_seconds": q.expected_time_seconds,
            }
        )

    return {"questions": result, "count": len(result)}
