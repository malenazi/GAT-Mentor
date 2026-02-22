"""Session Service - Manages timed sets and exam simulations."""
from datetime import datetime

from sqlalchemy.orm import Session

from app.models.attempt import Attempt
from app.models.concept import Concept
from app.models.question import Question
from app.models.study_session import StudySession
from app.models.topic import Topic
from app.services.mastery_service import update_mastery


def start_session(
    db: Session,
    user_id: int,
    session_type: str,
    question_count: int,
    topic_id: int | None = None,
    difficulty: int | None = None,
) -> tuple[StudySession, list[Question]]:
    """Create a session and select questions."""
    session = StudySession(
        user_id=user_id,
        session_type=session_type,
        question_count=question_count,
    )
    db.add(session)
    db.flush()

    # Select questions
    query = db.query(Question).filter(Question.is_active == True)
    if topic_id:
        query = query.join(Concept).filter(Concept.topic_id == topic_id)
    if difficulty:
        query = query.filter(
            Question.difficulty.between(difficulty - 1, difficulty + 1)
        )

    # Randomize and limit
    questions = query.order_by(func.random()).limit(question_count).all()
    db.commit()
    return session, questions


def submit_session(
    db: Session,
    user_id: int,
    session_id: int,
    answers: list[dict],
) -> dict:
    """Submit all answers for a session and get results."""
    session = db.query(StudySession).get(session_id)
    if not session or session.user_id != user_id:
        raise ValueError("Session not found")

    correct_count = 0
    total_time = 0
    topic_stats: dict[str, dict] = {}

    for answer in answers:
        question = db.query(Question).get(answer["question_id"])
        if not question:
            continue

        is_correct = answer["selected_option"] == question.correct_option
        time_taken = answer.get("time_taken_seconds", 0)

        if is_correct:
            correct_count += 1
        total_time += time_taken

        # Record attempt
        attempt = Attempt(
            user_id=user_id,
            question_id=question.id,
            selected_option=answer["selected_option"],
            is_correct=is_correct,
            time_taken_seconds=time_taken,
            session_id=session_id,
        )
        db.add(attempt)
        db.flush()

        # Update mastery
        update_mastery(db, user_id, question, attempt)

        # Track per-topic stats
        concept = db.query(Concept).get(question.concept_id)
        topic = db.query(Topic).get(concept.topic_id) if concept else None
        topic_name = topic.name if topic else "Unknown"

        if topic_name not in topic_stats:
            topic_stats[topic_name] = {"correct": 0, "total": 0, "time": 0}
        topic_stats[topic_name]["total"] += 1
        if is_correct:
            topic_stats[topic_name]["correct"] += 1
        topic_stats[topic_name]["time"] += time_taken

    # Update session
    session.correct_count = correct_count
    session.total_time_seconds = total_time
    session.ended_at = datetime.utcnow()
    session.is_completed = True
    db.commit()

    # Build topic breakdown
    topic_breakdown = []
    for name, stats in topic_stats.items():
        topic_breakdown.append(
            {
                "topic_name": name,
                "correct": stats["correct"],
                "total": stats["total"],
                "accuracy": round(stats["correct"] / stats["total"], 3)
                if stats["total"] > 0
                else 0.0,
                "avg_time": round(stats["time"] / stats["total"], 1)
                if stats["total"] > 0
                else 0.0,
            }
        )

    total_questions = len(answers)
    return {
        "session_id": session_id,
        "session_type": session.session_type,
        "total_questions": total_questions,
        "correct_count": correct_count,
        "accuracy": round(correct_count / total_questions, 3) if total_questions else 0,
        "total_time_seconds": total_time,
        "avg_time_per_question": round(total_time / total_questions, 1)
        if total_questions
        else 0,
        "topic_breakdown": topic_breakdown,
        "score_percentile": None,
    }


# Need this import for func.random()
from sqlalchemy import func
