from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.dependencies import get_current_user, get_db
from app.models.attempt import Attempt
from app.models.question import Question
from app.models.user import User
from app.schemas.attempt import AttemptCreate, AttemptResponse
from app.services.mastery_service import update_mastery
from app.services.streak_service import check_in

router = APIRouter()


@router.post("/", response_model=AttemptResponse)
def create_attempt(
    request: AttemptCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Record an answer attempt and update mastery."""
    question = db.query(Question).get(request.question_id)
    if not question:
        raise HTTPException(status_code=404, detail="Question not found")

    is_correct = request.selected_option == question.correct_option

    attempt = Attempt(
        user_id=current_user.id,
        question_id=request.question_id,
        selected_option=request.selected_option,
        is_correct=is_correct,
        time_taken_seconds=request.time_taken_seconds,
        was_guessed=request.was_guessed,
        hint_used=request.hint_used,
        session_id=request.session_id,
    )

    # Auto-classify mistake if guessed
    if request.was_guessed and not is_correct:
        attempt.mistake_type = "guessed"

    db.add(attempt)
    db.flush()

    # Update mastery
    stats, mastery_change = update_mastery(db, current_user.id, question, attempt)

    # Update streak
    check_in(db, current_user.id)

    db.commit()
    db.refresh(attempt)

    # Build "why wrong" for selected option
    why_wrong = None
    if not is_correct:
        why_wrong_map = {
            "a": question.why_wrong_a,
            "b": question.why_wrong_b,
            "c": question.why_wrong_c,
            "d": question.why_wrong_d,
        }
        why_wrong = why_wrong_map.get(request.selected_option)

    return AttemptResponse(
        id=attempt.id,
        question_id=attempt.question_id,
        selected_option=attempt.selected_option,
        is_correct=is_correct,
        time_taken_seconds=attempt.time_taken_seconds,
        was_guessed=attempt.was_guessed,
        hint_used=attempt.hint_used,
        mistake_type=attempt.mistake_type,
        created_at=attempt.created_at,
        correct_option=question.correct_option,
        explanation=question.explanation,
        why_wrong=why_wrong,
        mastery_change=round(mastery_change, 4),
        new_mastery=round(stats.mastery, 4),
    )


@router.get("/history")
def get_history(
    page: int = 1,
    per_page: int = 20,
    topic_id: int | None = None,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Get paginated attempt history."""
    query = db.query(Attempt).filter(Attempt.user_id == current_user.id)

    if topic_id:
        from app.models.concept import Concept

        query = (
            query.join(Question)
            .join(Concept)
            .filter(Concept.topic_id == topic_id)
        )

    total = query.count()
    attempts = (
        query.order_by(Attempt.created_at.desc())
        .offset((page - 1) * per_page)
        .limit(per_page)
        .all()
    )

    return {
        "attempts": [
            {
                "id": a.id,
                "question_id": a.question_id,
                "selected_option": a.selected_option,
                "is_correct": a.is_correct,
                "time_taken_seconds": a.time_taken_seconds,
                "was_guessed": a.was_guessed,
                "created_at": a.created_at.isoformat(),
            }
            for a in attempts
        ],
        "total": total,
        "page": page,
        "per_page": per_page,
    }


@router.get("/recent")
def get_recent(
    limit: int = 10,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Get most recent attempts."""
    attempts = (
        db.query(Attempt)
        .filter(Attempt.user_id == current_user.id)
        .order_by(Attempt.created_at.desc())
        .limit(limit)
        .all()
    )
    return [
        {
            "id": a.id,
            "question_id": a.question_id,
            "is_correct": a.is_correct,
            "time_taken_seconds": a.time_taken_seconds,
            "created_at": a.created_at.isoformat(),
        }
        for a in attempts
    ]
