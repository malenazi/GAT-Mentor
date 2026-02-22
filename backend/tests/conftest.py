"""Test fixtures for GAT Mentor backend."""
import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool

from app.database import Base
from app.dependencies import get_db
from app.models import *
from app.utils.security import hash_password


@pytest.fixture
def test_engine():
    """Create an in-memory SQLite database for testing."""
    engine = create_engine(
        "sqlite:///:memory:",
        connect_args={"check_same_thread": False},
        poolclass=StaticPool,
    )
    Base.metadata.create_all(bind=engine)
    return engine


@pytest.fixture
def test_db(test_engine):
    """Create a test database session."""
    TestSession = sessionmaker(bind=test_engine)
    db = TestSession()
    try:
        yield db
    finally:
        db.close()


@pytest.fixture
def seeded_db(test_db):
    """Database with topics, concepts, and sample questions."""
    topics = [
        Topic(id=1, name="Verbal", slug="verbal"),
        Topic(id=2, name="Quantitative", slug="quantitative"),
    ]
    test_db.add_all(topics)
    test_db.flush()

    concepts = [
        Concept(id=1, topic_id=1, name="Synonyms", slug="synonyms"),
        Concept(id=2, topic_id=1, name="Antonyms", slug="antonyms"),
        Concept(id=3, topic_id=2, name="Algebra", slug="algebra"),
    ]
    test_db.add_all(concepts)
    test_db.flush()

    questions = []
    for concept in concepts:
        for diff in [1, 3, 5]:
            questions.append(
                Question(
                    concept_id=concept.id,
                    text=f"Test question for {concept.name} difficulty {diff}?",
                    difficulty=diff,
                    option_a="Option A",
                    option_b="Option B",
                    option_c="Option C",
                    option_d="Option D",
                    correct_option="a",
                    explanation=f"Step 1: Correct answer is A.\nAnswer: A",
                    hint=f"Think about {concept.name}",
                    why_wrong_b="B is incorrect",
                    why_wrong_c="C is incorrect",
                    why_wrong_d="D is incorrect",
                    expected_time_seconds=60,
                )
            )
    test_db.add_all(questions)
    test_db.flush()

    user = User(
        id=1,
        email="test@test.com",
        hashed_password=hash_password("test123"),
        full_name="Test User",
    )
    test_db.add(user)
    test_db.flush()

    streak = Streak(user_id=1)
    test_db.add(streak)
    test_db.commit()

    return test_db


@pytest.fixture
def client(test_engine):
    """Create a test HTTP client with in-memory database."""
    from fastapi import FastAPI
    from fastapi.middleware.cors import CORSMiddleware

    from app.config import settings
    from app.routers import (
        admin, attempts, auth, onboarding, plan,
        questions, review, sessions, stats, streaks,
    )

    # Create a fresh app without the lifespan (tables already created by test_engine)
    app = FastAPI(title="Test")
    app.add_middleware(
        CORSMiddleware,
        allow_origins=["*"],
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )

    prefix = settings.API_V1_PREFIX
    app.include_router(auth.router, prefix=f"{prefix}/auth")
    app.include_router(onboarding.router, prefix=f"{prefix}/onboarding")
    app.include_router(questions.router, prefix=f"{prefix}/questions")
    app.include_router(attempts.router, prefix=f"{prefix}/attempts")
    app.include_router(stats.router, prefix=f"{prefix}/stats")
    app.include_router(plan.router, prefix=f"{prefix}/plan")
    app.include_router(review.router, prefix=f"{prefix}/review")
    app.include_router(sessions.router, prefix=f"{prefix}/sessions")
    app.include_router(streaks.router, prefix=f"{prefix}/streaks")
    app.include_router(admin.router, prefix=f"{prefix}/admin")

    TestSession = sessionmaker(bind=test_engine)

    def override_get_db():
        db = TestSession()
        try:
            yield db
        finally:
            db.close()

    app.dependency_overrides[get_db] = override_get_db
    return TestClient(app)
