"""Tests for the spaced repetition service."""
from datetime import datetime, timedelta

from app.models.attempt import Attempt
from app.services.spaced_repetition import (
    INTERVALS,
    get_due_reviews,
    get_review_count,
    process_review,
)


def _make_review_attempt(db, user_id=1, days_overdue=0, interval=1):
    """Create a wrong attempt scheduled for review."""
    attempt = Attempt(
        user_id=user_id,
        question_id=1,
        selected_option="b",
        is_correct=False,
        time_taken_seconds=60,
        next_review_date=datetime.utcnow() - timedelta(days=days_overdue),
        review_interval_days=interval,
        review_count=0,
    )
    db.add(attempt)
    db.commit()
    return attempt


def test_get_due_reviews(seeded_db):
    """Should return attempts due for review."""
    _make_review_attempt(seeded_db, days_overdue=1)  # Due
    _make_review_attempt(seeded_db, days_overdue=-1)  # Not due yet

    due = get_due_reviews(seeded_db, 1)
    assert len(due) == 1


def test_review_count(seeded_db):
    """Should count items due for review."""
    _make_review_attempt(seeded_db, days_overdue=1)
    _make_review_attempt(seeded_db, days_overdue=2)

    assert get_review_count(seeded_db, 1) == 2


def test_correct_fast_advances_interval(seeded_db):
    """Correct + fast should advance to next interval."""
    attempt = _make_review_attempt(seeded_db, interval=1)

    process_review(
        seeded_db, attempt,
        got_correct=True, time_taken=30, expected_time=60,
    )

    assert attempt.review_interval_days == 3  # 1 -> 3
    assert attempt.review_count == 1


def test_full_interval_progression(seeded_db):
    """Should progress through all intervals: 1 -> 3 -> 7 -> 14 -> 30."""
    attempt = _make_review_attempt(seeded_db, interval=1)

    for expected_interval in [3, 7, 14, 30]:
        process_review(
            seeded_db, attempt,
            got_correct=True, time_taken=30, expected_time=60,
        )
        assert attempt.review_interval_days == expected_interval


def test_correct_slow_stays_at_current(seeded_db):
    """Correct but slow should stay at current interval."""
    attempt = _make_review_attempt(seeded_db, interval=3)

    process_review(
        seeded_db, attempt,
        got_correct=True, time_taken=120, expected_time=60,  # Slow
    )

    assert attempt.review_interval_days == 3  # Stays at 3


def test_wrong_resets_to_one(seeded_db):
    """Wrong on review should reset interval to 1 day."""
    attempt = _make_review_attempt(seeded_db, interval=14)

    process_review(
        seeded_db, attempt,
        got_correct=False, time_taken=30, expected_time=60,
    )

    assert attempt.review_interval_days == 1  # Reset


def test_max_interval_stays_at_30(seeded_db):
    """Should not go beyond 30-day interval."""
    attempt = _make_review_attempt(seeded_db, interval=30)

    process_review(
        seeded_db, attempt,
        got_correct=True, time_taken=30, expected_time=60,
    )

    assert attempt.review_interval_days == 30  # Stays at max


def test_review_updates_next_date(seeded_db):
    """Next review date should be set correctly."""
    attempt = _make_review_attempt(seeded_db, interval=1)
    before = datetime.utcnow()

    process_review(
        seeded_db, attempt,
        got_correct=True, time_taken=30, expected_time=60,
    )

    # Next review should be ~3 days from now (advanced from 1 to 3)
    assert attempt.next_review_date > before
    delta = attempt.next_review_date - before
    assert 2 <= delta.days <= 4
