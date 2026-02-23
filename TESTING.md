# GAT Mentor - Testing Guidelines & Instructions

## Table of Contents

1. [Overview](#overview)
2. [Test Architecture](#test-architecture)
3. [Backend Testing (Python/FastAPI)](#backend-testing-pythonfastapi)
4. [Frontend Testing (Flutter/Dart)](#frontend-testing-flutterdart)
5. [Test Categories & Priority](#test-categories--priority)
6. [Writing New Tests](#writing-new-tests)
7. [Running Tests](#running-tests)
8. [CI/CD Integration](#cicd-integration)
9. [Test Coverage Goals](#test-coverage-goals)

---

## Overview

GAT Mentor is a full-stack adaptive learning application with:
- **Backend**: FastAPI (Python 3.12) + PostgreSQL/SQLAlchemy
- **Frontend**: Flutter (Dart) + Riverpod state management

Testing spans both layers. The backend uses **pytest** with an in-memory SQLite database. The frontend uses **flutter_test** for widget and unit testing.

### Current Test Inventory

| Layer    | File                        | Tests | What it covers                         |
|----------|-----------------------------|-------|----------------------------------------|
| Backend  | `test_auth.py`              | 5     | Register, login, token, unauthorized   |
| Backend  | `test_adaptive_engine.py`   | 9     | Priority scoring, difficulty, streaks  |
| Backend  | `test_mastery.py`           | 6     | Mastery gain/loss, guessing, streaks   |
| Backend  | `test_spaced_repetition.py` | 7     | Intervals, progression, review dates   |
| Frontend | `auth_flow_test.dart`       | 7     | Login/Register form UI & validation    |
| Frontend | `widget_test.dart`          | 1     | Basic smoke test (needs update)        |

---

## Test Architecture

### Backend Test Structure

```
backend/
  tests/
    conftest.py                  # Shared fixtures (DB, client, seed data)
    test_auth.py                 # Auth API endpoint tests
    test_adaptive_engine.py      # Adaptive engine unit tests
    test_mastery.py              # Mastery service unit tests
    test_spaced_repetition.py    # Spaced repetition unit tests
```

**Key Fixtures** (defined in `conftest.py`):

| Fixture      | Scope   | Description                                            |
|--------------|---------|--------------------------------------------------------|
| `test_engine`| function| In-memory SQLite engine with schema created            |
| `test_db`    | function| SQLAlchemy session bound to test engine                |
| `seeded_db`  | function| Session with topics, concepts, questions, user, streak |
| `client`     | function| FastAPI TestClient with dependency override             |

### Frontend Test Structure

```
frontend/gat_mentor/
  test/
    widget_test.dart             # Basic smoke test
    auth_flow_test.dart          # Auth screen widget tests
```

---

## Backend Testing (Python/FastAPI)

### Prerequisites

```bash
cd backend
pip install -r requirements.txt
```

Required packages: `pytest==8.3.0`, `pytest-asyncio==0.24.0`, `httpx==0.27.0`

### Fixture Usage Guide

**Use `client`** for API endpoint/integration tests:
```python
def test_some_endpoint(client):
    resp = client.post("/api/v1/auth/register", json={...})
    assert resp.status_code == 200
```

**Use `seeded_db`** for service/unit tests that need database data:
```python
def test_some_service(seeded_db):
    result = some_service_function(seeded_db, user_id=1, ...)
    assert result.value == expected
```

**Use `test_db`** for tests that need an empty database:
```python
def test_empty_state(test_db):
    result = test_db.query(User).all()
    assert len(result) == 0
```

### Seeded Data Reference

When using the `seeded_db` fixture, the following data is available:

| Entity    | Details                                                       |
|-----------|---------------------------------------------------------------|
| Topics    | id=1 Verbal, id=2 Quantitative                               |
| Concepts  | id=1 Synonyms (verbal), id=2 Antonyms (verbal), id=3 Algebra (quant) |
| Questions | 9 total: 3 per concept at difficulties 1, 3, 5               |
| User      | id=1, email=test@test.com, password=test123, name=Test User   |
| Streak    | user_id=1 (default values)                                    |

### Test Naming Conventions

- File: `test_<module>.py`
- Function: `test_<what_it_tests>` using descriptive snake_case
- Always include a docstring explaining the expected behavior
- Use helper functions prefixed with `_` (e.g., `_make_stats`, `_make_attempt`)

```python
# Good
def test_weak_concepts_get_higher_priority():
    """Concepts with lower mastery should have higher priority."""

# Bad
def test_1():
def test_priority():
```

### Test Pattern: API Endpoints

```python
def test_endpoint_success(client):
    """Describe expected success behavior."""
    # Arrange: set up any prerequisite data via API
    reg = client.post("/api/v1/auth/register", json={
        "email": "user@test.com",
        "password": "pass123",
        "full_name": "User",
    })
    token = reg.json()["access_token"]

    # Act: call the endpoint under test
    resp = client.get(
        "/api/v1/some/endpoint",
        headers={"Authorization": f"Bearer {token}"},
    )

    # Assert: verify response
    assert resp.status_code == 200
    data = resp.json()
    assert data["key"] == "expected_value"


def test_endpoint_unauthorized(client):
    """Should return 401 without auth token."""
    resp = client.get("/api/v1/some/endpoint")
    assert resp.status_code == 401


def test_endpoint_bad_input(client):
    """Should return 422 for invalid input."""
    resp = client.post("/api/v1/some/endpoint", json={"bad": "data"})
    assert resp.status_code == 422
```

### Test Pattern: Service Functions

```python
def _make_mock_object(**overrides):
    """Helper to create mock data with sensible defaults."""
    obj = SomeModel()
    obj.field1 = overrides.get("field1", "default_value")
    obj.field2 = overrides.get("field2", 0.5)
    return obj


def test_service_function_behavior(seeded_db):
    """Describe what the function should do in this scenario."""
    # Arrange
    input_data = _make_mock_object(field1="test")

    # Act
    result = service_function(seeded_db, input_data)

    # Assert
    assert result.output == expected
```

### Test Pattern: Randomized Algorithms

For functions involving randomness (like adaptive engine), run multiple iterations:

```python
def test_weighted_selection():
    """Higher weight items should be selected more often."""
    results = [random_function() for _ in range(1000)]
    high_priority_count = results.count("expected")
    assert high_priority_count > 700  # Should be selected ~90%
```

---

## Frontend Testing (Flutter/Dart)

### Prerequisites

```bash
cd frontend/gat_mentor
flutter pub get
```

### Widget Test Pattern

```dart
testWidgets('description of test', (tester) async {
  // Arrange: build the widget tree
  await tester.pumpWidget(
    const ProviderScope(
      child: MaterialApp(home: ScreenUnderTest()),
    ),
  );
  await tester.pumpAndSettle();

  // Act: interact with widgets
  await tester.enterText(
    find.widgetWithText(TextFormField, 'Field Label'),
    'input value',
  );
  await tester.tap(find.text('Button Text'));
  await tester.pumpAndSettle();

  // Assert: verify UI state
  expect(find.text('Expected Text'), findsOneWidget);
});
```

### Key Patterns

**Always wrap with ProviderScope** (required for Riverpod):
```dart
await tester.pumpWidget(
  const ProviderScope(
    child: MaterialApp(home: YourScreen()),
  ),
);
```

**Use `pumpAndSettle()`** after actions to let animations complete.

**Finding widgets:**
```dart
find.text('Exact Text')                            // By text
find.byIcon(Icons.some_icon)                       // By icon
find.byType(ElevatedButton)                        // By type
find.widgetWithText(TextFormField, 'Label')         // By type + text
find.widgetWithText(ElevatedButton, 'Button Text')  // Specific button
```

**Common assertions:**
```dart
expect(find.text('Hello'), findsOneWidget);      // Exactly one match
expect(find.text('Hello'), findsNothing);         // No matches
expect(find.text('Hello'), findsWidgets);          // One or more
expect(find.text('Hello'), findsNWidgets(3));      // Exactly N
```

### Frontend Test Organization

Group related tests:
```dart
void main() {
  group('ScreenName widget tests', () {
    testWidgets('renders correctly', (tester) async { ... });
    testWidgets('validates empty fields', (tester) async { ... });
    testWidgets('handles user interaction', (tester) async { ... });
  });
}
```

---

## Test Categories & Priority

### Priority 1 - Critical (Must Have)

These tests cover core business logic and user-facing functionality:

| Area                  | What to test                                         | Status    |
|-----------------------|------------------------------------------------------|-----------|
| Auth API              | Register, login, token validation, unauthorized      | Covered   |
| Adaptive Engine       | Priority scoring, difficulty scaling, frustration     | Covered   |
| Mastery Service       | Mastery gain/loss, streaks, guessing penalty          | Covered   |
| Spaced Repetition     | Intervals, progression, reset on wrong               | Covered   |
| Question Selection    | Next question endpoint returns valid questions        | **TODO**  |
| Answer Submission     | Submit attempt, updates stats correctly               | **TODO**  |
| Onboarding Flow       | Profile setup, diagnostic test submission             | **TODO**  |

### Priority 2 - Important (Should Have)

| Area                  | What to test                                         | Status    |
|-----------------------|------------------------------------------------------|-----------|
| Plan Service          | Daily plan generation, concept selection              | **TODO**  |
| Stats Service         | Accuracy calculation, topic-wise breakdown            | **TODO**  |
| Session Service       | Exam simulation start/end, scoring                    | **TODO**  |
| Streak Service        | Daily streak increment, reset logic                   | **TODO**  |
| Auth Service          | Password hashing, JWT encode/decode                   | **TODO**  |
| Login Screen UI       | Form rendering, validation, toggle                    | Covered   |
| Register Screen UI    | Form rendering, validation                            | Covered   |

### Priority 3 - Nice to Have

| Area                  | What to test                                         | Status    |
|-----------------------|------------------------------------------------------|-----------|
| Home Screen UI        | Renders dashboard, navigation works                   | **TODO**  |
| Practice Screen UI    | Question display, option selection, feedback           | **TODO**  |
| Review Screen UI      | Review queue, card flipping                           | **TODO**  |
| Dashboard Screen UI   | Charts render, stats display                          | **TODO**  |
| API Error Handling    | Network errors, timeout, 500 responses                | **TODO**  |
| Edge Cases            | Empty DB, user with no attempts, zero mastery         | **TODO**  |
| Admin Endpoints       | Seed data, admin-only access control                  | **TODO**  |

---

## Writing New Tests

### Backend: Adding a New Test File

1. Create `backend/tests/test_<module>.py`
2. Import fixtures from `conftest.py` by using them as function parameters
3. Follow the naming and docstring conventions above

**Example: Adding tests for the plan service**

```python
"""Tests for the plan service."""
from app.services.plan_service import generate_daily_plan


def test_plan_includes_weak_concepts(seeded_db):
    """Daily plan should prioritize concepts with low mastery."""
    plan = generate_daily_plan(seeded_db, user_id=1)
    assert len(plan) > 0
    # Concepts with no attempts should appear in plan
    assert any(item["concept_id"] in [1, 2, 3] for item in plan)


def test_plan_respects_daily_minutes(seeded_db):
    """Plan should not exceed user's daily study time."""
    plan = generate_daily_plan(seeded_db, user_id=1)
    total_minutes = sum(item.get("estimated_minutes", 0) for item in plan)
    assert total_minutes <= 45  # Default daily minutes
```

### Backend: Adding Tests for an Endpoint

```python
"""Tests for the questions endpoint."""


def _register_and_get_token(client):
    """Helper to register and get auth token."""
    resp = client.post("/api/v1/auth/register", json={
        "email": "q_test@test.com",
        "password": "pass123",
        "full_name": "Question Tester",
    })
    return resp.json()["access_token"]


def test_get_next_question(client):
    """Should return a question for authenticated user."""
    token = _register_and_get_token(client)

    # Note: client fixture has empty DB, may need to seed via admin endpoint
    resp = client.get(
        "/api/v1/questions/next",
        headers={"Authorization": f"Bearer {token}"},
    )
    assert resp.status_code in [200, 404]  # 404 if no questions seeded


def test_next_question_unauthorized(client):
    """Should reject unauthenticated requests."""
    resp = client.get("/api/v1/questions/next")
    assert resp.status_code == 401
```

### Frontend: Adding Widget Tests

1. Create `frontend/gat_mentor/test/<feature>_test.dart`
2. Import the screen/widget and required providers
3. Wrap with `ProviderScope` + `MaterialApp`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gat_mentor/features/home/presentation/screens/home_screen.dart';

void main() {
  group('HomeScreen widget tests', () {
    testWidgets('renders home screen elements', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: HomeScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('GAT Mentor'), findsOneWidget);
      // Add more assertions for expected UI elements
    });
  });
}
```

---

## Running Tests

### Backend Tests

```bash
# Run all backend tests
cd backend
pytest

# Run with verbose output
pytest -v

# Run a specific test file
pytest tests/test_auth.py

# Run a specific test function
pytest tests/test_auth.py::test_register

# Run tests matching a keyword
pytest -k "mastery"

# Run with coverage report
pytest --cov=app --cov-report=term-missing

# Run with coverage HTML report
pytest --cov=app --cov-report=html
# Open htmlcov/index.html to view

# Stop on first failure
pytest -x

# Show print output
pytest -s
```

### Frontend Tests

```bash
# Run all Flutter tests
cd frontend/gat_mentor
flutter test

# Run a specific test file
flutter test test/auth_flow_test.dart

# Run with verbose output
flutter test --reporter expanded

# Run with coverage
flutter test --coverage
# Coverage report in coverage/lcov.info

# Generate HTML coverage report (requires lcov)
genhtml coverage/lcov.info -o coverage/html
```

### Run Everything

From the project root:

```bash
# Backend tests
cd backend && pytest -v && cd ..

# Frontend tests
cd frontend/gat_mentor && flutter test && cd ../..
```

---

## CI/CD Integration

Currently no CI/CD pipeline exists. Below is a recommended GitHub Actions workflow:

### Recommended: `.github/workflows/test.yml`

```yaml
name: Tests

on:
  push:
    branches: [master]
  pull_request:
    branches: [master]

jobs:
  backend-tests:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Set up Python 3.12
        uses: actions/setup-python@v5
        with:
          python-version: "3.12"

      - name: Install dependencies
        run: |
          cd backend
          pip install -r requirements.txt

      - name: Run tests
        run: |
          cd backend
          pytest -v --tb=short

  frontend-tests:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Set up Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: "3.x"

      - name: Install dependencies
        run: |
          cd frontend/gat_mentor
          flutter pub get

      - name: Run tests
        run: |
          cd frontend/gat_mentor
          flutter test
```

---

## Test Coverage Goals

### Target Coverage by Module

| Module                     | Current | Target | Priority |
|----------------------------|---------|--------|----------|
| `services/adaptive_engine` | ~90%    | 95%    | P1       |
| `services/mastery_service` | ~85%    | 90%    | P1       |
| `services/spaced_repetition`| ~90%   | 95%    | P1       |
| `routers/auth`             | ~80%    | 90%    | P1       |
| `services/auth_service`    | ~0%     | 80%    | P2       |
| `routers/questions`        | ~0%     | 80%    | P2       |
| `routers/attempts`         | ~0%     | 80%    | P2       |
| `routers/onboarding`       | ~0%     | 70%    | P2       |
| `services/plan_service`    | ~0%     | 70%    | P2       |
| `services/stats_service`   | ~0%     | 70%    | P2       |
| `services/session_service` | ~0%     | 70%    | P2       |
| `services/streak_service`  | ~0%     | 70%    | P2       |
| `routers/stats`            | ~0%     | 60%    | P3       |
| `routers/plan`             | ~0%     | 60%    | P3       |
| `routers/review`           | ~0%     | 60%    | P3       |
| `routers/sessions`         | ~0%     | 60%    | P3       |
| `routers/admin`            | ~0%     | 50%    | P3       |
| Flutter auth screens       | ~70%    | 80%    | P2       |
| Flutter other screens      | ~0%     | 50%    | P3       |

### Overall Targets

- **Backend**: 70% line coverage minimum
- **Frontend**: 50% line coverage minimum
- **Critical services** (adaptive engine, mastery, spaced repetition): 90%+ coverage

---

## Quick Reference

| Task                           | Command                                    |
|--------------------------------|--------------------------------------------|
| Run all backend tests          | `cd backend && pytest`                     |
| Run all frontend tests         | `cd frontend/gat_mentor && flutter test`   |
| Run specific backend test      | `pytest tests/test_auth.py::test_register` |
| Run specific frontend test     | `flutter test test/auth_flow_test.dart`    |
| Backend coverage               | `pytest --cov=app --cov-report=term-missing` |
| Frontend coverage              | `flutter test --coverage`                  |
| Run tests matching keyword     | `pytest -k "mastery"`                      |
| Stop on first failure          | `pytest -x`                                |
| Verbose output                 | `pytest -v` / `flutter test --reporter expanded` |
