"""Tests for the adaptive engine."""
from datetime import datetime, timedelta

from app.models.concept import Concept
from app.models.user_concept_stats import UserConceptStats
from app.services.adaptive_engine import (
    _calculate_priorities,
    _calculate_target_difficulty,
    _calculate_review_urgency,
    _select_concept,
)


def _make_stats(mastery=0.5, accuracy=0.5, total_attempts=10, last_seen_days_ago=0, streak=0):
    """Helper to create mock UserConceptStats."""
    stats = UserConceptStats()
    stats.mastery = mastery
    stats.accuracy = accuracy
    stats.total_attempts = total_attempts
    stats.current_streak = streak
    stats.difficulty_comfort = 2
    if last_seen_days_ago is not None:
        stats.last_seen = datetime.utcnow() - timedelta(days=last_seen_days_ago)
    else:
        stats.last_seen = None
    return stats


def test_weak_concepts_get_higher_priority():
    """Concepts with lower mastery should have higher priority."""
    concepts = [
        Concept(id=1, topic_id=1, name="Strong", slug="s"),
        Concept(id=2, topic_id=1, name="Weak", slug="w"),
    ]
    stats = {
        1: _make_stats(mastery=0.9, accuracy=0.9),
        2: _make_stats(mastery=0.1, accuracy=0.3),
    }

    priorities = _calculate_priorities(concepts, stats)
    # Weak concept should be first (highest priority)
    assert priorities[0]["concept_id"] == 2
    assert priorities[0]["priority"] > priorities[1]["priority"]


def test_stale_concepts_get_higher_priority():
    """Concepts not seen recently should have higher priority."""
    concepts = [
        Concept(id=1, topic_id=1, name="Recent", slug="r"),
        Concept(id=2, topic_id=1, name="Stale", slug="s"),
    ]
    stats = {
        1: _make_stats(mastery=0.5, last_seen_days_ago=1),
        2: _make_stats(mastery=0.5, last_seen_days_ago=25),
    }

    priorities = _calculate_priorities(concepts, stats)
    assert priorities[0]["concept_id"] == 2


def test_never_seen_concepts_get_moderate_priority():
    """Concepts with no stats should get moderate priority."""
    concepts = [
        Concept(id=1, topic_id=1, name="Known", slug="k"),
        Concept(id=2, topic_id=1, name="New", slug="n"),
    ]
    stats = {
        1: _make_stats(mastery=0.8, accuracy=0.8, last_seen_days_ago=2),
    }

    priorities = _calculate_priorities(concepts, stats)
    # New concept should be first (no mastery, no accuracy, stale)
    assert priorities[0]["concept_id"] == 2


def test_difficulty_based_on_mastery():
    """Difficulty should increase with mastery."""
    low = _make_stats(mastery=0.1)
    mid = _make_stats(mastery=0.5)
    high = _make_stats(mastery=0.9)

    # Run multiple times to account for randomness
    low_diffs = [_calculate_target_difficulty(low) for _ in range(50)]
    mid_diffs = [_calculate_target_difficulty(mid) for _ in range(50)]
    high_diffs = [_calculate_target_difficulty(high) for _ in range(50)]

    assert sum(low_diffs) / len(low_diffs) < sum(mid_diffs) / len(mid_diffs)
    assert sum(mid_diffs) / len(mid_diffs) < sum(high_diffs) / len(high_diffs)


def test_streak_bonus():
    """Streak >= 3 should increase difficulty by 1."""
    no_streak = _make_stats(mastery=0.5, streak=0)
    with_streak = _make_stats(mastery=0.5, streak=5)

    no_diffs = [_calculate_target_difficulty(no_streak) for _ in range(100)]
    streak_diffs = [_calculate_target_difficulty(with_streak) for _ in range(100)]

    # Average difficulty with streak should be higher
    assert sum(streak_diffs) / len(streak_diffs) > sum(no_diffs) / len(no_diffs)


def test_frustration_guard():
    """Low accuracy with enough attempts should decrease difficulty."""
    frustrated = _make_stats(mastery=0.5, accuracy=0.3, total_attempts=10)
    normal = _make_stats(mastery=0.5, accuracy=0.7, total_attempts=10)

    frust_diffs = [_calculate_target_difficulty(frustrated) for _ in range(100)]
    normal_diffs = [_calculate_target_difficulty(normal) for _ in range(100)]

    assert sum(frust_diffs) / len(frust_diffs) < sum(normal_diffs) / len(normal_diffs)


def test_review_urgency():
    """Low mastery + long time since seen = high urgency."""
    urgent = _make_stats(mastery=0.2, last_seen_days_ago=5)
    not_urgent = _make_stats(mastery=0.8, last_seen_days_ago=1)

    assert _calculate_review_urgency(urgent) > _calculate_review_urgency(not_urgent)


def test_review_urgency_never_seen():
    """Never seen concept should have moderate urgency."""
    assert _calculate_review_urgency(None) == 0.5
    never_seen = _make_stats()
    never_seen.last_seen = None
    assert _calculate_review_urgency(never_seen) == 0.5


def test_select_concept_weighted():
    """Selection should favor higher priority concepts."""
    priorities = [
        {"concept_id": 1, "topic_id": 1, "mastery": 0.1, "priority": 0.9},
        {"concept_id": 2, "topic_id": 1, "mastery": 0.9, "priority": 0.1},
    ]

    # Run many times, concept 1 should be selected much more often
    selections = [_select_concept(priorities)["concept_id"] for _ in range(1000)]
    concept_1_count = selections.count(1)
    assert concept_1_count > 700  # Should be selected ~90% of the time
