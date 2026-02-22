from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.dependencies import get_current_user, get_db
from app.models.concept import Concept
from app.models.study_session import StudySession
from app.models.topic import Topic
from app.models.user import User
from app.schemas.session import SessionSubmission, StartSessionRequest
from app.services.session_service import start_session, submit_session

router = APIRouter()


@router.post("/start")
def start(
    request: StartSessionRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Start a new timed session or exam simulation."""
    session, questions = start_session(
        db,
        current_user.id,
        request.session_type,
        request.question_count,
        request.topic_id,
        request.difficulty,
    )

    question_list = []
    for q in questions:
        concept = db.query(Concept).get(q.concept_id)
        topic = db.query(Topic).get(concept.topic_id) if concept else None
        question_list.append(
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

    return {
        "id": session.id,
        "session_type": session.session_type,
        "question_count": session.question_count,
        "started_at": session.started_at.isoformat(),
        "questions": question_list,
    }


@router.get("/{session_id}")
def get_session(
    session_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    session = db.query(StudySession).get(session_id)
    if not session or session.user_id != current_user.id:
        raise HTTPException(status_code=404, detail="Session not found")

    return {
        "id": session.id,
        "session_type": session.session_type,
        "question_count": session.question_count,
        "correct_count": session.correct_count,
        "total_time_seconds": session.total_time_seconds,
        "started_at": session.started_at.isoformat(),
        "ended_at": session.ended_at.isoformat() if session.ended_at else None,
        "is_completed": session.is_completed,
    }


@router.post("/{session_id}/submit")
def submit(
    session_id: int,
    submission: SessionSubmission,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Submit all answers for a session."""
    try:
        result = submit_session(
            db, current_user.id, session_id, submission.answers
        )
    except ValueError as e:
        raise HTTPException(status_code=404, detail=str(e))
    return result


@router.get("/history/list")
def session_history(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    sessions = (
        db.query(StudySession)
        .filter(StudySession.user_id == current_user.id)
        .order_by(StudySession.started_at.desc())
        .limit(20)
        .all()
    )

    return [
        {
            "id": s.id,
            "session_type": s.session_type,
            "question_count": s.question_count,
            "correct_count": s.correct_count,
            "total_time_seconds": s.total_time_seconds,
            "started_at": s.started_at.isoformat(),
            "is_completed": s.is_completed,
        }
        for s in sessions
    ]
