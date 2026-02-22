"""
Adaptive Engine - Core algorithm for next-question selection.

Priority scoring:
    priority = (1 - mastery) * 0.35       # Weak concepts first
             + staleness * 0.15            # Forgotten concepts
             + (1 - accuracy) * 0.20       # Low accuracy concepts
             + review_urgency * 0.20       # Spaced repetition items
             + topic_deficit * 0.10        # Topic balance
"""
import random
from datetime import datetime

from sqlalchemy.orm import Session

from app.models.attempt import Attempt
from app.models.concept import Concept
from app.models.question import Question
from app.models.topic import Topic
from app.models.user_concept_stats import UserConceptStats

W_MASTERY = 0.35
W_STALENESS = 0.15
W_ACCURACY = 0.20
W_REVIEW = 0.20
W_BALANCE = 0.10


def get_next_question(
    db: Session,
    user_id: int,
    topic_id: int | None = None,
    concept_id: int | None = None,
    difficulty: int | None = None,
) -> Question | None:
    """Select the next optimal question for the user."""
    # If specific concept requested, skip adaptive selection
    if concept_id:
        return _find_question(db, user_id, concept_id, difficulty)

    # Get all concepts (filtered by topic if specified)
    concepts_query = db.query(Concept)
    if topic_id:
        concepts_query = concepts_query.filter(Concept.topic_id == topic_id)
    all_concepts = concepts_query.all()

    if not all_concepts:
        return None

    # Get user stats for all concepts
    user_stats = {
        s.concept_id: s
        for s in db.query(UserConceptStats)
        .filter(UserConceptStats.user_id == user_id)
        .all()
    }

    # Calculate priorities
    priorities = _calculate_priorities(all_concepts, user_stats)
    if not priorities:
        return None

    # Select concept (weighted random from top 5)
    selected = _select_concept(priorities)

    # Determine target difficulty
    target_diff = _calculate_target_difficulty(
        user_stats.get(selected["concept_id"]), difficulty
    )

    return _find_question(db, user_id, selected["concept_id"], target_diff)


def _calculate_priorities(
    concepts: list[Concept],
    user_stats: dict[int, UserConceptStats],
) -> list[dict]:
    """Calculate priority scores for all concepts."""
    scores = []
    topic_attempt_counts: dict[int, int] = {}

    for concept in concepts:
        stats = user_stats.get(concept.id)

        mastery = stats.mastery if stats else 0.0
        accuracy = stats.accuracy if stats else 0.0
        total_attempts = stats.total_attempts if stats else 0

        # Staleness
        if stats and stats.last_seen:
            days_since = (datetime.utcnow() - stats.last_seen).days
        else:
            days_since = 30  # Never seen = very stale
        staleness = min(days_since / 30.0, 1.0)

        # Review urgency
        review_urgency = _calculate_review_urgency(stats)

        # Track topic attempts for balance
        topic_attempt_counts[concept.topic_id] = (
            topic_attempt_counts.get(concept.topic_id, 0) + total_attempts
        )

        priority = (
            (1 - mastery) * W_MASTERY
            + staleness * W_STALENESS
            + (1 - accuracy) * W_ACCURACY
            + review_urgency * W_REVIEW
        )

        scores.append(
            {
                "concept_id": concept.id,
                "topic_id": concept.topic_id,
                "mastery": mastery,
                "priority": priority,
            }
        )

    # Add topic balance factor
    total_attempts = sum(topic_attempt_counts.values()) or 1
    unique_topics = len(topic_attempt_counts) or 1
    expected_ratio = 1.0 / unique_topics

    for score in scores:
        topic_ratio = topic_attempt_counts.get(score["topic_id"], 0) / total_attempts
        deficit = max(0, expected_ratio - topic_ratio)
        score["priority"] += deficit * W_BALANCE

    scores.sort(key=lambda s: s["priority"], reverse=True)
    return scores


def _select_concept(priorities: list[dict]) -> dict:
    """Weighted random from top 5 priority concepts."""
    top_n = priorities[:5]
    weights = [max(s["priority"], 0.01) for s in top_n]
    return random.choices(top_n, weights=weights, k=1)[0]


def _calculate_target_difficulty(
    stats: UserConceptStats | None,
    forced_difficulty: int | None = None,
) -> int | None:
    """Determine optimal difficulty for the selected concept."""
    if forced_difficulty:
        return forced_difficulty
    if not stats:
        return 2

    mastery = stats.mastery
    if mastery < 0.3:
        base = random.choice([1, 2])
    elif mastery < 0.6:
        base = random.choice([2, 3])
    elif mastery < 0.8:
        base = random.choice([3, 4])
    else:
        base = random.choice([4, 5])

    # Streak bonus
    if stats.current_streak >= 3:
        base = min(base + 1, 5)

    # Frustration guard
    if stats.accuracy < 0.5 and stats.total_attempts > 5:
        base = max(base - 1, 1)

    return base


def _calculate_review_urgency(stats: UserConceptStats | None) -> float:
    """How urgently does this concept need review? 0.0-1.0"""
    if not stats or not stats.last_seen:
        return 0.5

    days_since = (datetime.utcnow() - stats.last_seen).days

    if stats.mastery < 0.3 and days_since > 3:
        return 1.0
    elif stats.mastery < 0.6 and days_since > 7:
        return 0.8
    elif stats.mastery < 0.8 and days_since > 14:
        return 0.6
    elif days_since > 21:
        return 0.4
    return 0.0


def _find_question(
    db: Session,
    user_id: int,
    concept_id: int,
    difficulty: int | None = None,
) -> Question | None:
    """Find an unanswered question, or least recently answered."""
    # Get IDs of questions already answered by user for this concept
    answered_ids = [
        a.question_id
        for a in db.query(Attempt.question_id)
        .filter(Attempt.user_id == user_id)
        .join(Question)
        .filter(Question.concept_id == concept_id)
        .all()
    ]

    # Try to find unanswered question
    query = db.query(Question).filter(
        Question.concept_id == concept_id,
        Question.is_active == True,
    )
    if difficulty:
        query = query.filter(Question.difficulty.between(difficulty - 1, difficulty + 1))
    if answered_ids:
        query = query.filter(Question.id.notin_(answered_ids))

    question = query.order_by(Question.difficulty).first()

    if question:
        return question

    # All questions answered — return least recently attempted
    query = (
        db.query(Question)
        .filter(Question.concept_id == concept_id, Question.is_active == True)
    )
    if difficulty:
        query = query.filter(Question.difficulty.between(difficulty - 1, difficulty + 1))

    return query.first()
