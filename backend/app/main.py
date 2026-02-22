import os
from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles

from app.config import settings
from app.database import Base, engine
from app.routers import (
    admin,
    attempts,
    auth,
    onboarding,
    plan,
    questions,
    review,
    sessions,
    stats,
    streaks,
)


def _auto_seed():
    """Seed the database if it's empty (first deploy)."""
    from app.database import SessionLocal
    from app.models.topic import Topic

    db = SessionLocal()
    try:
        if db.query(Topic).count() == 0:
            print("Empty database detected. Running seed...")
            from seeds.seed import seed

            seed()
            print("Seed complete.")
    except Exception as e:
        print(f"Auto-seed check skipped: {e}")
    finally:
        db.close()


@asynccontextmanager
async def lifespan(app: FastAPI):
    # Create tables on startup
    Base.metadata.create_all(bind=engine)
    # Auto-seed if empty
    _auto_seed()
    yield


def create_app() -> FastAPI:
    application = FastAPI(
        title=settings.APP_NAME,
        version="1.0.0",
        lifespan=lifespan,
    )

    # CORS — parse allowed origins from config
    origins = [
        o.strip()
        for o in settings.ALLOWED_ORIGINS.split(",")
        if o.strip()
    ]

    application.add_middleware(
        CORSMiddleware,
        allow_origins=origins,
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )

    prefix = settings.API_V1_PREFIX
    application.include_router(auth.router, prefix=f"{prefix}/auth", tags=["Auth"])
    application.include_router(
        onboarding.router, prefix=f"{prefix}/onboarding", tags=["Onboarding"]
    )
    application.include_router(
        questions.router, prefix=f"{prefix}/questions", tags=["Questions"]
    )
    application.include_router(
        attempts.router, prefix=f"{prefix}/attempts", tags=["Attempts"]
    )
    application.include_router(stats.router, prefix=f"{prefix}/stats", tags=["Stats"])
    application.include_router(plan.router, prefix=f"{prefix}/plan", tags=["Plan"])
    application.include_router(
        review.router, prefix=f"{prefix}/review", tags=["Review"]
    )
    application.include_router(
        sessions.router, prefix=f"{prefix}/sessions", tags=["Sessions"]
    )
    application.include_router(
        streaks.router, prefix=f"{prefix}/streaks", tags=["Streaks"]
    )
    application.include_router(admin.router, prefix=f"{prefix}/admin", tags=["Admin"])

    @application.get("/api/health")
    def health_check():
        return {"status": "healthy"}

    # Serve Flutter web build as static files (must be LAST, after all API routes)
    static_dir = os.path.join(os.path.dirname(os.path.dirname(__file__)), "static")
    if os.path.isdir(static_dir):
        application.mount(
            "/", StaticFiles(directory=static_dir, html=True), name="static"
        )

    return application


app = create_app()
