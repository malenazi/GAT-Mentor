from pydantic import BaseModel, EmailStr, Field


class RegisterRequest(BaseModel):
    email: str = Field(..., min_length=5)
    password: str = Field(..., min_length=6)
    full_name: str = Field(..., min_length=2)


class LoginRequest(BaseModel):
    email: str
    password: str


class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"


class UserProfile(BaseModel):
    id: int
    email: str
    full_name: str
    level: str
    exam_date: str | None = None
    daily_minutes: int
    target_score: int
    study_focus: str
    is_admin: bool
    onboarding_complete: bool

    class Config:
        from_attributes = True
