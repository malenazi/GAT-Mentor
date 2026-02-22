"""
Daily Plan Service

Plan structure for N minutes:
    10-15% warm-up (easy questions from strong concepts)
    40-50% weak topic drill (weakest 2-3 concepts)
    20-25% timed sprint (mixed difficulty, race clock)
    15-20% mistake review (spaced repetition queue)
"""
from datetime import date

from sqlalchemy.orm import Session

from app.models.daily_plan import DailyPlan, DailyPlanItem, PlanItemType
from app.models.user import User, StudentLevel
from app.models.user_concept_stats import UserConceptStats
from app.services.spaced_repetition import get_review_count


def get_or_generate_today_plan(db: Session, user: User) -> DailyPlan:
    """Get today's plan or generate a new one."""
    today = date.today()
    existing = (
        db.query(DailyPlan)
        .filter(DailyPlan.user_id == user.id, DailyPlan.date == today)
        .first()
    )
    if existing:
        return existing
    return generate_daily_plan(db, user)


def generate_daily_plan(db: Session, user: User) -> DailyPlan:
    """Generate a personalized daily plan."""
    today = date.today()
    total_minutes = user.daily_minutes

    # Delete existing plan for today if regenerating
    existing = (
        db.query(DailyPlan)
        .filter(DailyPlan.user_id == user.id, DailyPlan.date == today)
        .first()
    )
    if existing:
        db.delete(existing)
        db.flush()

    # Get weakest concepts
    weakest = _get_weakest_concepts(db, user.id, count=3)
    review_count = get_review_count(db, user.id)

    # Calculate time allocation
    warmup_min = max(5, int(total_minutes * 0.12))
    review_min = min(int(total_minutes * 0.20), 15) if review_count > 0 else 0
    sprint_min = max(5, int(total_minutes * 0.22))
    drill_min = total_minutes - warmup_min - review_min - sprint_min

    # Adjust for student level
    if user.level == StudentLevel.BEGINNER.value:
        warmup_min += 3
        sprint_min = max(5, sprint_min - 3)
    elif user.level == StudentLevel.HIGH_SCORER.value:
        warmup_min = max(5, warmup_min - 2)
        sprint_min += 2

    plan = DailyPlan(
        user_id=user.id,
        date=today,
        total_minutes=total_minutes,
    )
    db.add(plan)
    db.flush()

    items = []
    order = 0

    # 1. Warm-up
    items.append(
        DailyPlanItem(
            plan_id=plan.id,
            item_type=PlanItemType.WARMUP.value,
            duration_minutes=warmup_min,
            question_count=max(3, warmup_min // 2),
            difficulty_range_min=1,
            difficulty_range_max=2,
            display_order=order,
        )
    )
    order += 1

    # 2. Weak topic drills
    if weakest:
        drill_per = drill_min // len(weakest)
        for stats in weakest:
            items.append(
                DailyPlanItem(
                    plan_id=plan.id,
                    item_type=PlanItemType.WEAK_TOPIC_DRILL.value,
                    concept_id=stats.concept_id,
                    duration_minutes=max(5, drill_per),
                    question_count=max(3, drill_per // 2),
                    difficulty_range_min=stats.difficulty_comfort,
                    difficulty_range_max=min(stats.difficulty_comfort + 1, 5),
                    display_order=order,
                )
            )
            order += 1
    else:
        # No stats yet — general mixed practice
        items.append(
            DailyPlanItem(
                plan_id=plan.id,
                item_type=PlanItemType.MIXED_PRACTICE.value,
                duration_minutes=drill_min,
                question_count=max(5, drill_min // 2),
                difficulty_range_min=1,
                difficulty_range_max=3,
                display_order=order,
            )
        )
        order += 1

    # 3. Timed sprint
    items.append(
        DailyPlanItem(
            plan_id=plan.id,
            item_type=PlanItemType.TIMED_SPRINT.value,
            duration_minutes=sprint_min,
            question_count=max(5, sprint_min),
            difficulty_range_min=2,
            difficulty_range_max=4,
            display_order=order,
        )
    )
    order += 1

    # 4. Mistake review
    if review_min > 0:
        items.append(
            DailyPlanItem(
                plan_id=plan.id,
                item_type=PlanItemType.MISTAKE_REVIEW.value,
                duration_minutes=review_min,
                question_count=min(review_count, max(3, review_min // 2)),
                display_order=order,
            )
        )

    db.add_all(items)
    db.commit()
    db.refresh(plan)
    return plan


def _get_weakest_concepts(
    db: Session, user_id: int, count: int = 3
) -> list[UserConceptStats]:
    """Get the weakest concepts by mastery score."""
    return (
        db.query(UserConceptStats)
        .filter(UserConceptStats.user_id == user_id)
        .order_by(UserConceptStats.mastery.asc())
        .limit(count)
        .all()
    )
