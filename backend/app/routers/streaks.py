from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.dependencies import get_current_user, get_db
from app.models.user import User
from app.services.streak_service import check_in, get_streak

router = APIRouter()


@router.get("/current")
def current_streak(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    streak = get_streak(db, current_user.id)
    return {
        "current_streak": streak.current_streak,
        "longest_streak": streak.longest_streak,
        "last_activity_date": streak.last_activity_date.isoformat()
        if streak.last_activity_date
        else None,
        "streak_start_date": streak.streak_start_date.isoformat()
        if streak.streak_start_date
        else None,
    }


@router.post("/checkin")
def daily_checkin(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    streak = check_in(db, current_user.id)
    return {
        "current_streak": streak.current_streak,
        "longest_streak": streak.longest_streak,
        "last_activity_date": streak.last_activity_date.isoformat()
        if streak.last_activity_date
        else None,
    }
