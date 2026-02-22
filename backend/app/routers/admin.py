from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import func
from sqlalchemy.orm import Session

from app.dependencies import get_admin_user, get_db
from app.models.attempt import Attempt
from app.models.question import Question
from app.models.user import User
from app.models.user_concept_stats import UserConceptStats
from app.schemas.question import QuestionCreate, QuestionDetail

router = APIRouter()


@router.post("/questions/", response_model=QuestionDetail)
def create_question(
    request: QuestionCreate,
    admin: User = Depends(get_admin_user),
    db: Session = Depends(get_db),
):
    question = Question(**request.model_dump())
    db.add(question)
    db.commit()
    db.refresh(question)
    return QuestionDetail.model_validate(question)


@router.get("/questions/")
def list_questions(
    page: int = 1,
    per_page: int = 20,
    topic_id: int | None = None,
    concept_id: int | None = None,
    admin: User = Depends(get_admin_user),
    db: Session = Depends(get_db),
):
    from app.models.concept import Concept

    query = db.query(Question)
    if concept_id:
        query = query.filter(Question.concept_id == concept_id)
    elif topic_id:
        query = query.join(Concept).filter(Concept.topic_id == topic_id)

    total = query.count()
    questions = (
        query.order_by(Question.id.desc())
        .offset((page - 1) * per_page)
        .limit(per_page)
        .all()
    )

    return {
        "questions": [
            {
                "id": q.id,
                "concept_id": q.concept_id,
                "text": q.text[:100],
                "difficulty": q.difficulty,
                "correct_option": q.correct_option,
                "is_active": q.is_active,
            }
            for q in questions
        ],
        "total": total,
        "page": page,
    }


@router.put("/questions/{question_id}")
def update_question(
    question_id: int,
    request: QuestionCreate,
    admin: User = Depends(get_admin_user),
    db: Session = Depends(get_db),
):
    question = db.query(Question).get(question_id)
    if not question:
        raise HTTPException(status_code=404, detail="Question not found")

    for field, value in request.model_dump().items():
        setattr(question, field, value)
    db.commit()
    db.refresh(question)
    return {"id": question.id, "message": "Updated successfully"}


@router.delete("/questions/{question_id}")
def delete_question(
    question_id: int,
    admin: User = Depends(get_admin_user),
    db: Session = Depends(get_db),
):
    question = db.query(Question).get(question_id)
    if not question:
        raise HTTPException(status_code=404, detail="Question not found")

    question.is_active = False  # Soft delete
    db.commit()
    return {"message": "Question deactivated"}


@router.post("/questions/bulk")
def bulk_upload(
    questions: list[QuestionCreate],
    admin: User = Depends(get_admin_user),
    db: Session = Depends(get_db),
):
    """Bulk upload questions."""
    created = []
    for q_data in questions:
        question = Question(**q_data.model_dump())
        db.add(question)
        created.append(question)

    db.commit()
    return {"created": len(created), "message": f"{len(created)} questions uploaded"}


@router.get("/stats/overview")
def admin_overview(
    admin: User = Depends(get_admin_user),
    db: Session = Depends(get_db),
):
    total_users = db.query(User).count()
    total_questions = db.query(Question).filter(Question.is_active == True).count()
    total_attempts = db.query(Attempt).count()
    avg_mastery = db.query(func.avg(UserConceptStats.mastery)).scalar() or 0.0

    return {
        "total_users": total_users,
        "total_questions": total_questions,
        "total_attempts": total_attempts,
        "avg_mastery": round(avg_mastery, 3),
    }
