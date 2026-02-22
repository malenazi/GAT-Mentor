"""
Spaced Repetition Service

Interval progression: 1 -> 3 -> 7 -> 14 -> 30 days
- Correct + fast on review: advance to next interval
- Correct + slow: stay at current interval
- Wrong on review: reset to 1 day
"""
from datetime import datetime, timedelta

from sqlalchemy.orm import Session

from app.models.attempt import Attempt

INTERVALS = [1, 3, 7, 14, 30]


def get_due_reviews(db: Session, user_id: int, limit: int = 20) -> list[Attempt]:
    """Get attempts due for review today."""
    return (
        db.query(Attempt)
        .filter(
            Attempt.user_id == user_id,
            Attempt.is_correct == False,
            Attempt.next_review_date != None,
            Attempt.next_review_date <= datetime.utcnow(),
        )
        .order_by(Attempt.next_review_date.asc())
        .limit(limit)
        .all()
    )


def get_review_count(db: Session, user_id: int) -> int:
    """Count of items due for review today."""
    return (
        db.query(Attempt)
        .filter(
            Attempt.user_id == user_id,
            Attempt.is_correct == False,
            Attempt.next_review_date != None,
            Attempt.next_review_date <= datetime.utcnow(),
        )
        .count()
    )


def process_review(
    db: Session,
    attempt: Attempt,
    got_correct: bool,
    time_taken: int,
    expected_time: int,
) -> Attempt:
    """Process a review result and schedule next review."""
    attempt.review_count += 1

    if got_correct and time_taken <= expected_time:
        # Advance to next interval
        try:
            current_idx = INTERVALS.index(attempt.review_interval_days)
        except ValueError:
            current_idx = 0
        next_idx = min(current_idx + 1, len(INTERVALS) - 1)
        attempt.review_interval_days = INTERVALS[next_idx]
    elif got_correct:
        # Correct but slow — stay at current interval
        pass
    else:
        # Wrong again — reset
        attempt.review_interval_days = 1

    attempt.next_review_date = datetime.utcnow() + timedelta(
        days=attempt.review_interval_days
    )
    return attempt
