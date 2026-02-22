from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.dependencies import get_current_user, get_db
from app.models.user import User
from app.schemas.auth import (
    LoginRequest,
    RegisterRequest,
    TokenResponse,
    UserProfile,
)
from app.schemas.user import UpdateProfileRequest
from app.services.auth_service import (
    authenticate_user,
    create_token_for_user,
    register_user,
)

router = APIRouter()


@router.post("/register", response_model=TokenResponse)
def register(request: RegisterRequest, db: Session = Depends(get_db)):
    try:
        user = register_user(db, request.email, request.password, request.full_name)
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    token = create_token_for_user(user)
    return TokenResponse(access_token=token)


@router.post("/login", response_model=TokenResponse)
def login(request: LoginRequest, db: Session = Depends(get_db)):
    user = authenticate_user(db, request.email, request.password)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid email or password",
        )
    token = create_token_for_user(user)
    return TokenResponse(access_token=token)


@router.get("/me", response_model=UserProfile)
def get_me(current_user: User = Depends(get_current_user)):
    return UserProfile.model_validate(current_user)


@router.put("/me", response_model=UserProfile)
def update_me(
    request: UpdateProfileRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    update_data = request.model_dump(exclude_unset=True)
    for field, value in update_data.items():
        setattr(current_user, field, value)
    db.commit()
    db.refresh(current_user)
    return UserProfile.model_validate(current_user)
