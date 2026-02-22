from datetime import datetime

from fastapi import APIRouter, Depends
from sqlalchemy import func
from sqlalchemy.orm import Session

from app.dependencies import get_current_user, get_db
from app.models.concept import Concept
from app.models.question import Question
from app.models.user import User
from app.models.user_concept_stats import UserConceptStats
from app.schemas.auth import UserProfile
from app.schemas.user import OnboardingProfileRequest

router = APIRouter()


@router.post("/profile", response_model=UserProfile)
def set_profile(
    request: OnboardingProfileRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    current_user.level = request.level
    current_user.study_focus = request.study_focus
    current_user.exam_date = request.exam_date
    current_user.daily_minutes = request.daily_minutes
    current_user.target_score = request.target_score
    db.commit()
    db.refresh(current_user)
    return UserProfile.model_validate(current_user)


@router.get("/diagnostic")
def get_diagnostic_questions(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Return 15 diagnostic questions: 5 per topic, mixed difficulty."""
    questions = []
    concepts = db.query(Concept).all()

    # Group concepts by topic
    topic_concepts: dict[int, list[int]] = {}
    for c in concepts:
        topic_concepts.setdefault(c.topic_id, []).append(c.id)

    for topic_id, concept_ids in topic_concepts.items():
        topic_qs = (
            db.query(Question)
            .filter(
                Question.concept_id.in_(concept_ids),
                Question.is_active == True,
            )
            .order_by(func.random())
            .limit(5)
            .all()
        )
        for q in topic_qs:
            concept = db.query(Concept).get(q.concept_id)
            questions.append(
                {
                    "id": q.id,
                    "concept_id": q.concept_id,
                    "concept_name": concept.name if concept else None,
                    "text": q.text,
                    "difficulty": q.difficulty,
                    "option_a": q.option_a,
                    "option_b": q.option_b,
                    "option_c": q.option_c,
                    "option_d": q.option_d,
                    "expected_time_seconds": q.expected_time_seconds,
                }
            )

    return {"questions": questions, "total": len(questions)}


@router.post("/diagnostic/submit")
def submit_diagnostic(
    submission: dict,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Grade diagnostic and set initial mastery per concept."""
    answers = submission.get("answers", [])
    concept_results: dict[int, dict] = {}

    for answer in answers:
        question = db.query(Question).get(answer["question_id"])
        if not question:
            continue

        is_correct = answer["selected_option"] == question.correct_option
        cid = question.concept_id

        if cid not in concept_results:
            concept_results[cid] = {"correct": 0, "total": 0}
        concept_results[cid]["total"] += 1
        if is_correct:
            concept_results[cid]["correct"] += 1

    # Set initial mastery per concept
    results = []
    for concept_id, data in concept_results.items():
        accuracy = data["correct"] / data["total"] if data["total"] > 0 else 0.0
        initial_mastery = accuracy * 0.5  # Conservative initial mastery

        stats = (
            db.query(UserConceptStats)
            .filter(
                UserConceptStats.user_id == current_user.id,
                UserConceptStats.concept_id == concept_id,
            )
            .first()
        )
        if not stats:
            stats = UserConceptStats(
                user_id=current_user.id,
                concept_id=concept_id,
            )
            db.add(stats)

        stats.mastery = initial_mastery
        stats.accuracy = accuracy
        stats.total_attempts = data["total"]
        stats.correct_attempts = data["correct"]
        stats.last_seen = datetime.utcnow()

        # Set difficulty comfort based on accuracy
        if accuracy >= 0.8:
            stats.difficulty_comfort = 3
        elif accuracy >= 0.5:
            stats.difficulty_comfort = 2
        else:
            stats.difficulty_comfort = 1

        concept = db.query(Concept).get(concept_id)
        results.append(
            {
                "concept_id": concept_id,
                "concept_name": concept.name if concept else "",
                "accuracy": round(accuracy, 2),
                "initial_mastery": round(initial_mastery, 2),
                "difficulty_comfort": stats.difficulty_comfort,
            }
        )

    # Mark onboarding complete
    current_user.onboarding_complete = True
    db.commit()

    # Calculate overall readiness
    total_correct = sum(r["accuracy"] for r in results)
    overall = total_correct / len(results) if results else 0.0

    return {
        "overall_accuracy": round(overall, 2),
        "concept_results": results,
        "recommended_level": (
            "beginner" if overall < 0.4
            else "average" if overall < 0.7
            else "high_scorer"
        ),
    }
