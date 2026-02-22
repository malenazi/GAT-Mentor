"""
Seed script for GAT Mentor database.

Creates:
- 3 topics (Verbal, Quantitative, Analytical)
- 15 concepts (5 per topic)
- 150 questions (50 per topic, 10 per concept)
- 1 admin user (admin@gat.com / admin123)
- 1 demo student (student@gat.com / student123)
"""
import json
import os
import sys

# Add parent directory to path
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from app.database import Base, engine, SessionLocal
from app.models.user import User
from app.models.topic import Topic
from app.models.concept import Concept
from app.models.question import Question
from app.models.streak import Streak
from app.utils.security import hash_password

DATA_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "data")


def load_json(filename: str) -> list[dict]:
    filepath = os.path.join(DATA_DIR, filename)
    with open(filepath, "r", encoding="utf-8") as f:
        return json.load(f)


def seed():
    # Create all tables
    Base.metadata.create_all(bind=engine)

    db = SessionLocal()

    try:
        # Check if already seeded
        if db.query(Topic).count() > 0:
            print("Database already seeded. Skipping.")
            print(f"  Topics: {db.query(Topic).count()}")
            print(f"  Concepts: {db.query(Concept).count()}")
            print(f"  Questions: {db.query(Question).count()}")
            print(f"  Users: {db.query(User).count()}")
            return

        # 1. Seed topics
        print("Seeding topics...")
        topics_data = load_json("topics.json")
        for t in topics_data:
            topic = Topic(
                id=t["id"],
                name=t["name"],
                slug=t["slug"],
                description=t.get("description"),
                weight_in_exam=t.get("weight_in_exam", 0.33),
                display_order=t.get("display_order", 0),
            )
            db.add(topic)
        db.flush()
        print(f"  Created {len(topics_data)} topics")

        # 2. Seed concepts
        print("Seeding concepts...")
        concepts_data = load_json("concepts.json")
        slug_to_concept_id = {}
        for c in concepts_data:
            concept = Concept(
                id=c["id"],
                topic_id=c["topic_id"],
                name=c["name"],
                slug=c["slug"],
                description=c.get("description"),
                display_order=c.get("display_order", 0),
            )
            db.add(concept)
            slug_to_concept_id[c["slug"]] = c["id"]
        db.flush()
        print(f"  Created {len(concepts_data)} concepts")

        # 3. Seed questions from all three files
        question_files = [
            "verbal_questions.json",
            "quantitative_questions.json",
            "analytical_questions.json",
        ]

        total_questions = 0
        for qfile in question_files:
            filepath = os.path.join(DATA_DIR, qfile)
            if not os.path.exists(filepath):
                print(f"  Warning: {qfile} not found, skipping")
                continue

            print(f"Seeding questions from {qfile}...")
            questions_data = load_json(qfile)

            for q in questions_data:
                concept_id = slug_to_concept_id.get(q["concept_slug"])
                if not concept_id:
                    print(f"  Warning: concept '{q['concept_slug']}' not found, skipping question")
                    continue

                question = Question(
                    concept_id=concept_id,
                    text=q["text"],
                    difficulty=q.get("difficulty", 3),
                    option_a=q["option_a"],
                    option_b=q["option_b"],
                    option_c=q["option_c"],
                    option_d=q["option_d"],
                    correct_option=q["correct_option"],
                    explanation=q["explanation"],
                    hint=q.get("hint"),
                    why_wrong_a=q.get("why_wrong_a"),
                    why_wrong_b=q.get("why_wrong_b"),
                    why_wrong_c=q.get("why_wrong_c"),
                    why_wrong_d=q.get("why_wrong_d"),
                    expected_time_seconds=q.get("expected_time_seconds", 90),
                    tags=q.get("tags"),
                )
                db.add(question)
                total_questions += 1

            db.flush()
            print(f"  Loaded {len(questions_data)} questions from {qfile}")

        print(f"  Total questions seeded: {total_questions}")

        # 4. Create admin user
        print("Creating admin user...")
        admin = User(
            email="admin@gat.com",
            hashed_password=hash_password("admin123"),
            full_name="Admin User",
            is_admin=True,
            onboarding_complete=True,
        )
        db.add(admin)
        db.flush()
        admin_streak = Streak(user_id=admin.id)
        db.add(admin_streak)

        # 5. Create demo student
        print("Creating demo student...")
        student = User(
            email="student@gat.com",
            hashed_password=hash_password("student123"),
            full_name="Demo Student",
            level="average",
            daily_minutes=45,
            target_score=75,
            onboarding_complete=False,
        )
        db.add(student)
        db.flush()
        student_streak = Streak(user_id=student.id)
        db.add(student_streak)

        db.commit()
        print("\nSeeding complete!")
        print(f"  Topics: {db.query(Topic).count()}")
        print(f"  Concepts: {db.query(Concept).count()}")
        print(f"  Questions: {db.query(Question).count()}")
        print(f"  Users: {db.query(User).count()}")
        print("\nDemo accounts:")
        print("  Admin:   admin@gat.com / admin123")
        print("  Student: student@gat.com / student123")

    except Exception as e:
        db.rollback()
        print(f"Error seeding database: {e}")
        raise
    finally:
        db.close()


if __name__ == "__main__":
    seed()
