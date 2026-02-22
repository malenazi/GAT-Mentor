"""
Mastery Service - Updates per-concept mastery after each attempt.

Mastery update formula:
    correct + fast  → mastery += 0.08 * (1 - current_mastery)
    correct + slow  → mastery += 0.04 * (1 - current_mastery)
    correct + guess → mastery += 0.01
    wrong           → mastery -= 0.06 * current_mastery, add to review queue
"""
from datetime import datetime, timedelta

from sqlalchemy.orm import Session

from app.models.attempt import Attempt
from app.models.question import Question
from app.models.user_concept_stats import UserConceptStats


def get_or_create_stats(
    db: Session, user_id: int, concept_id: int
) -> UserConceptStats:
    stats = (
        db.query(UserConceptStats)
        .filter(
            UserConceptStats.user_id == user_id,
            UserConceptStats.concept_id == concept_id,
        )
        .first()
    )
    if not stats:
        stats = UserConceptStats(user_id=user_id, concept_id=concept_id)
        db.add(stats)
        db.flush()
    return stats


def update_mastery(
    db: Session, user_id: int, question: Question, attempt: Attempt
) -> tuple[UserConceptStats, float]:
    """Update mastery and return (stats, mastery_change)."""
    stats = get_or_create_stats(db, user_id, question.concept_id)
    old_mastery = stats.mastery

    stats.total_attempts += 1
    if attempt.is_correct:
        stats.correct_attempts += 1
    stats.accuracy = stats.correct_attempts / stats.total_attempts

    # Running average for time
    if stats.avg_time_seconds == 0:
        stats.avg_time_seconds = attempt.time_taken_seconds
    else:
        stats.avg_time_seconds = (
            stats.avg_time_seconds * 0.8 + attempt.time_taken_seconds * 0.2
        )

    is_fast = attempt.time_taken_seconds <= question.expected_time_seconds

    if attempt.is_correct and not attempt.was_guessed:
        delta = 0.08 * (1 - stats.mastery) if is_fast else 0.04 * (1 - stats.mastery)
        stats.mastery = min(1.0, stats.mastery + delta)
        stats.current_streak += 1
        stats.best_streak = max(stats.best_streak, stats.current_streak)
        stats.last_correct = datetime.utcnow()

        # Update difficulty comfort
        stats.difficulty_comfort = max(stats.difficulty_comfort, question.difficulty)
    elif attempt.is_correct and attempt.was_guessed:
        stats.mastery = min(1.0, stats.mastery + 0.01)
        stats.current_streak = 0
    else:
        # Wrong answer
        delta = 0.06 * stats.mastery
        stats.mastery = max(0.0, stats.mastery - delta)
        stats.current_streak = 0

        # Schedule for review (spaced repetition)
        attempt.next_review_date = datetime.utcnow() + timedelta(days=1)
        attempt.review_interval_days = 1
        attempt.review_count = 0

    stats.last_seen = datetime.utcnow()
    mastery_change = stats.mastery - old_mastery
    return stats, mastery_change
