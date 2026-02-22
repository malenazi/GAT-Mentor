"""Stats Service - Aggregates dashboard data, mastery maps, and trends."""
from datetime import datetime, timedelta

from sqlalchemy import func
from sqlalchemy.orm import Session

from app.models.attempt import Attempt
from app.models.concept import Concept
from app.models.question import Question
from app.models.streak import Streak
from app.models.study_session import StudySession
from app.models.topic import Topic
from app.models.user_concept_stats import UserConceptStats


def get_dashboard_data(db: Session, user_id: int) -> dict:
    """Aggregate dashboard stats."""
    # Total attempts
    total = db.query(Attempt).filter(Attempt.user_id == user_id).count()
    correct = (
        db.query(Attempt)
        .filter(Attempt.user_id == user_id, Attempt.is_correct == True)
        .count()
    )
    accuracy = correct / total if total > 0 else 0.0

    # Avg time
    avg_time_row = (
        db.query(func.avg(Attempt.time_taken_seconds))
        .filter(Attempt.user_id == user_id)
        .scalar()
    )
    avg_time = avg_time_row or 0.0

    # Streak
    streak = db.query(Streak).filter(Streak.user_id == user_id).first()
    current_streak = streak.current_streak if streak else 0
    longest_streak = streak.longest_streak if streak else 0

    # Total study minutes
    total_seconds = (
        db.query(func.sum(StudySession.total_time_seconds))
        .filter(StudySession.user_id == user_id)
        .scalar()
    ) or 0

    # Mastery summary by topic
    mastery_summary = {}
    stats_rows = (
        db.query(UserConceptStats, Concept, Topic)
        .join(Concept, UserConceptStats.concept_id == Concept.id)
        .join(Topic, Concept.topic_id == Topic.id)
        .filter(UserConceptStats.user_id == user_id)
        .all()
    )
    topic_masteries: dict[str, list[float]] = {}
    for s, c, t in stats_rows:
        topic_masteries.setdefault(t.name, []).append(s.mastery)
    for topic_name, values in topic_masteries.items():
        mastery_summary[topic_name] = sum(values) / len(values) if values else 0.0

    # Weakest concepts
    weakest = (
        db.query(UserConceptStats)
        .filter(UserConceptStats.user_id == user_id)
        .order_by(UserConceptStats.mastery.asc())
        .limit(5)
        .all()
    )
    weakest_list = []
    for s in weakest:
        concept = db.query(Concept).get(s.concept_id)
        topic = db.query(Topic).get(concept.topic_id) if concept else None
        weakest_list.append(
            {
                "concept_id": s.concept_id,
                "concept_name": concept.name if concept else "",
                "topic_name": topic.name if topic else "",
                "mastery": s.mastery,
                "accuracy": s.accuracy,
                "avg_time_seconds": s.avg_time_seconds,
                "total_attempts": s.total_attempts,
                "current_streak": s.current_streak,
            }
        )

    return {
        "total_questions_done": total,
        "total_correct": correct,
        "overall_accuracy": round(accuracy, 3),
        "avg_time_per_question": round(avg_time, 1),
        "current_streak": current_streak,
        "longest_streak": longest_streak,
        "total_study_minutes": total_seconds // 60,
        "mastery_summary": mastery_summary,
        "weakest_concepts": weakest_list,
    }


def get_mastery_map(db: Session, user_id: int) -> list[dict]:
    """Get mastery grouped by topic -> concepts."""
    topics = db.query(Topic).order_by(Topic.display_order).all()
    result = []

    for topic in topics:
        concepts_data = []
        for concept in topic.concepts:
            stats = (
                db.query(UserConceptStats)
                .filter(
                    UserConceptStats.user_id == user_id,
                    UserConceptStats.concept_id == concept.id,
                )
                .first()
            )
            concepts_data.append(
                {
                    "id": concept.id,
                    "name": concept.name,
                    "mastery": stats.mastery if stats else 0.0,
                    "accuracy": stats.accuracy if stats else 0.0,
                    "total_attempts": stats.total_attempts if stats else 0,
                }
            )
        result.append(
            {
                "topic_id": topic.id,
                "topic_name": topic.name,
                "concepts": concepts_data,
            }
        )

    return result


def get_trends(db: Session, user_id: int, days: int = 7) -> list[dict]:
    """Get accuracy and speed trends over the last N days."""
    trends = []
    for i in range(days - 1, -1, -1):
        day = datetime.utcnow().date() - timedelta(days=i)
        day_start = datetime.combine(day, datetime.min.time())
        day_end = datetime.combine(day, datetime.max.time())

        attempts = (
            db.query(Attempt)
            .filter(
                Attempt.user_id == user_id,
                Attempt.created_at.between(day_start, day_end),
            )
            .all()
        )

        total = len(attempts)
        correct = sum(1 for a in attempts if a.is_correct)
        avg_time = (
            sum(a.time_taken_seconds for a in attempts) / total if total > 0 else 0.0
        )

        trends.append(
            {
                "date": day.isoformat(),
                "accuracy": round(correct / total, 3) if total > 0 else 0.0,
                "avg_time": round(avg_time, 1),
                "questions_done": total,
            }
        )

    return trends
