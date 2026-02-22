from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.dependencies import get_current_user, get_db
from app.models.user import User
from app.services.stats_service import get_dashboard_data, get_mastery_map, get_trends

router = APIRouter()


@router.get("/dashboard")
def dashboard(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    return get_dashboard_data(db, current_user.id)


@router.get("/mastery")
def mastery_map(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    return {"topics": get_mastery_map(db, current_user.id)}


@router.get("/trends")
def trends(
    days: int = 7,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    return {
        "daily_trends": get_trends(db, current_user.id, days),
        "period": f"{days}d",
    }


@router.get("/weakest")
def weakest_concepts(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    from app.models.concept import Concept
    from app.models.topic import Topic
    from app.models.user_concept_stats import UserConceptStats

    stats = (
        db.query(UserConceptStats)
        .filter(UserConceptStats.user_id == current_user.id)
        .order_by(UserConceptStats.mastery.asc())
        .limit(5)
        .all()
    )

    result = []
    for s in stats:
        concept = db.query(Concept).get(s.concept_id)
        topic = db.query(Topic).get(concept.topic_id) if concept else None
        result.append(
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

    return result
