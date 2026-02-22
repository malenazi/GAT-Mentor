from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.dependencies import get_current_user, get_db
from app.models.attempt import Attempt
from app.models.concept import Concept
from app.models.question import Question
from app.models.topic import Topic
from app.models.user import User
from app.schemas.attempt import MistakeClassification
from app.services.spaced_repetition import get_due_reviews, get_review_count, process_review

router = APIRouter()


@router.get("/queue")
def review_queue(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Get mistakes due for review."""
    reviews = get_due_reviews(db, current_user.id)
    result = []

    for attempt in reviews:
        question = db.query(Question).get(attempt.question_id)
        concept = db.query(Concept).get(question.concept_id) if question else None
        topic = db.query(Topic).get(concept.topic_id) if concept else None

        result.append(
            {
                "attempt_id": attempt.id,
                "question_id": attempt.question_id,
                "question_text": question.text if question else "",
                "concept_name": concept.name if concept else "",
                "topic_name": topic.name if topic else "",
                "selected_option": attempt.selected_option,
                "correct_option": question.correct_option if question else "",
                "mistake_type": attempt.mistake_type,
                "review_count": attempt.review_count,
                "next_review_date": attempt.next_review_date.isoformat()
                if attempt.next_review_date
                else None,
            }
        )

    return {"reviews": result, "count": len(result)}


@router.get("/queue/count")
def review_count(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    count = get_review_count(db, current_user.id)
    return {"count": count}


@router.post("/{attempt_id}/classify")
def classify_mistake(
    attempt_id: int,
    classification: MistakeClassification,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Classify a mistake type."""
    attempt = db.query(Attempt).get(attempt_id)
    if not attempt or attempt.user_id != current_user.id:
        raise HTTPException(status_code=404, detail="Attempt not found")

    attempt.mistake_type = classification.mistake_type
    db.commit()

    return {"attempt_id": attempt.id, "mistake_type": attempt.mistake_type}


@router.post("/{attempt_id}/reviewed")
def mark_reviewed(
    attempt_id: int,
    body: dict,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Mark a review as completed and schedule next review."""
    attempt = db.query(Attempt).get(attempt_id)
    if not attempt or attempt.user_id != current_user.id:
        raise HTTPException(status_code=404, detail="Attempt not found")

    question = db.query(Question).get(attempt.question_id)
    expected_time = question.expected_time_seconds if question else 90

    updated = process_review(
        db,
        attempt,
        got_correct=body.get("got_correct", False),
        time_taken=body.get("time_taken", 0),
        expected_time=expected_time,
    )
    db.commit()

    return {
        "attempt_id": updated.id,
        "review_count": updated.review_count,
        "next_review_date": updated.next_review_date.isoformat()
        if updated.next_review_date
        else None,
        "review_interval_days": updated.review_interval_days,
    }
