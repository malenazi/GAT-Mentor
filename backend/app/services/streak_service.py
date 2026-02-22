"""Streak Service - Tracks daily study streaks."""
from datetime import date, timedelta

from sqlalchemy.orm import Session

from app.models.streak import Streak


def get_streak(db: Session, user_id: int) -> Streak:
    """Get or create streak record."""
    streak = db.query(Streak).filter(Streak.user_id == user_id).first()
    if not streak:
        streak = Streak(user_id=user_id)
        db.add(streak)
        db.commit()
        db.refresh(streak)
    return streak


def check_in(db: Session, user_id: int) -> Streak:
    """Record daily activity and update streak."""
    streak = get_streak(db, user_id)
    today = date.today()

    if streak.last_activity_date == today:
        # Already checked in today
        return streak

    if streak.last_activity_date == today - timedelta(days=1):
        # Consecutive day
        streak.current_streak += 1
    elif streak.last_activity_date is None or streak.last_activity_date < today - timedelta(days=1):
        # Streak broken or first activity
        streak.current_streak = 1
        streak.streak_start_date = today

    streak.longest_streak = max(streak.longest_streak, streak.current_streak)
    streak.last_activity_date = today
    db.commit()
    db.refresh(streak)
    return streak
