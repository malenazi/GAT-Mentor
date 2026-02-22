"""Tests for the mastery service."""
from datetime import datetime

from app.models.attempt import Attempt
from app.models.question import Question
from app.models.user_concept_stats import UserConceptStats
from app.services.mastery_service import get_or_create_stats, update_mastery


def _make_question(difficulty=3, expected_time=60):
    q = Question()
    q.concept_id = 1
    q.difficulty = difficulty
    q.expected_time_seconds = expected_time
    return q


def _make_attempt(is_correct=True, time_taken=30, was_guessed=False):
    a = Attempt()
    a.is_correct = is_correct
    a.time_taken_seconds = time_taken
    a.was_guessed = was_guessed
    return a


def test_correct_fast_increases_mastery_more(seeded_db):
    """Correct + fast should increase mastery by 0.08 * (1 - mastery)."""
    question = _make_question(expected_time=60)
    attempt = _make_attempt(is_correct=True, time_taken=30)  # Fast

    stats, change = update_mastery(seeded_db, 1, question, attempt)
    assert change > 0
    assert stats.mastery > 0


def test_correct_slow_increases_mastery_less(seeded_db):
    """Correct + slow should increase mastery by 0.04 * (1 - mastery)."""
    question = _make_question(expected_time=60)
    fast_attempt = _make_attempt(is_correct=True, time_taken=30)
    slow_attempt = _make_attempt(is_correct=True, time_taken=90)

    _, fast_change = update_mastery(seeded_db, 1, question, fast_attempt)

    # Reset stats for fair comparison
    stats = seeded_db.query(UserConceptStats).filter(
        UserConceptStats.user_id == 1,
        UserConceptStats.concept_id == 1,
    ).first()
    stats.mastery = 0.0
    stats.total_attempts = 0
    stats.correct_attempts = 0
    seeded_db.commit()

    _, slow_change = update_mastery(seeded_db, 1, question, slow_attempt)
    assert fast_change > slow_change


def test_wrong_decreases_mastery(seeded_db):
    """Wrong answer should decrease mastery."""
    # First get some mastery
    question = _make_question(expected_time=60)
    correct = _make_attempt(is_correct=True, time_taken=30)
    update_mastery(seeded_db, 1, question, correct)
    update_mastery(seeded_db, 1, question, correct)

    stats = seeded_db.query(UserConceptStats).filter(
        UserConceptStats.user_id == 1,
        UserConceptStats.concept_id == 1,
    ).first()
    mastery_before = stats.mastery

    wrong = _make_attempt(is_correct=False, time_taken=30)
    stats, change = update_mastery(seeded_db, 1, question, wrong)
    assert change < 0
    assert stats.mastery < mastery_before


def test_guessed_gives_minimal_mastery(seeded_db):
    """Guessed correct should give only +0.01."""
    question = _make_question(expected_time=60)
    guessed = _make_attempt(is_correct=True, time_taken=30, was_guessed=True)

    stats, change = update_mastery(seeded_db, 1, question, guessed)
    assert change == 0.01
    assert stats.current_streak == 0  # Guessing breaks streak


def test_wrong_schedules_review(seeded_db):
    """Wrong answer should schedule the attempt for review."""
    question = _make_question(expected_time=60)
    wrong = _make_attempt(is_correct=False, time_taken=30)
    wrong.user_id = 1
    wrong.question_id = 1
    wrong.selected_option = "b"
    seeded_db.add(wrong)
    seeded_db.flush()

    update_mastery(seeded_db, 1, question, wrong)
    assert wrong.next_review_date is not None
    assert wrong.review_interval_days == 1


def test_streak_tracking(seeded_db):
    """Streaks should increment on correct, reset on wrong."""
    question = _make_question(expected_time=60)

    # 3 correct in a row
    for _ in range(3):
        correct = _make_attempt(is_correct=True, time_taken=30)
        update_mastery(seeded_db, 1, question, correct)

    stats = seeded_db.query(UserConceptStats).filter(
        UserConceptStats.user_id == 1,
        UserConceptStats.concept_id == 1,
    ).first()
    assert stats.current_streak == 3
    assert stats.best_streak == 3

    # Wrong resets streak
    wrong = _make_attempt(is_correct=False, time_taken=30)
    update_mastery(seeded_db, 1, question, wrong)
    assert stats.current_streak == 0
    assert stats.best_streak == 3  # Best streak preserved
