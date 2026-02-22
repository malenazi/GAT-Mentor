from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.dependencies import get_current_user, get_db
from app.models.concept import Concept
from app.models.daily_plan import DailyPlan, DailyPlanItem
from app.models.user import User
from app.schemas.plan import PlanSettings
from app.services.plan_service import generate_daily_plan, get_or_generate_today_plan

router = APIRouter()


@router.get("/today")
def today_plan(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Get or generate today's plan."""
    plan = get_or_generate_today_plan(db, current_user)
    return _plan_to_dict(db, plan)


@router.post("/generate")
def force_generate(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Force regenerate today's plan."""
    plan = generate_daily_plan(db, current_user)
    return _plan_to_dict(db, plan)


@router.put("/settings")
def update_settings(
    request: PlanSettings,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    if request.daily_minutes:
        current_user.daily_minutes = request.daily_minutes
    if request.target_score:
        current_user.target_score = request.target_score
    if request.exam_date:
        from datetime import datetime

        current_user.exam_date = datetime.fromisoformat(request.exam_date)
    db.commit()
    return {
        "daily_minutes": current_user.daily_minutes,
        "target_score": current_user.target_score,
        "exam_date": current_user.exam_date.isoformat() if current_user.exam_date else None,
    }


@router.put("/items/{item_id}/complete")
def complete_item(
    item_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    item = db.query(DailyPlanItem).get(item_id)
    if not item:
        raise HTTPException(status_code=404, detail="Plan item not found")

    plan = db.query(DailyPlan).get(item.plan_id)
    if not plan or plan.user_id != current_user.id:
        raise HTTPException(status_code=403, detail="Not authorized")

    item.is_completed = True

    # Check if all items complete
    all_items = db.query(DailyPlanItem).filter(DailyPlanItem.plan_id == plan.id).all()
    if all(i.is_completed for i in all_items):
        plan.is_completed = True

    db.commit()
    return {"id": item.id, "is_completed": True, "plan_completed": plan.is_completed}


def _plan_to_dict(db: Session, plan: DailyPlan) -> dict:
    items = []
    for item in sorted(plan.items, key=lambda i: i.display_order):
        concept_name = None
        if item.concept_id:
            concept = db.query(Concept).get(item.concept_id)
            concept_name = concept.name if concept else None

        items.append(
            {
                "id": item.id,
                "item_type": item.item_type,
                "concept_id": item.concept_id,
                "concept_name": concept_name,
                "duration_minutes": item.duration_minutes,
                "question_count": item.question_count,
                "difficulty_range_min": item.difficulty_range_min,
                "difficulty_range_max": item.difficulty_range_max,
                "display_order": item.display_order,
                "is_completed": item.is_completed,
            }
        )

    return {
        "id": plan.id,
        "date": plan.date.isoformat(),
        "total_minutes": plan.total_minutes,
        "is_completed": plan.is_completed,
        "items": items,
    }
