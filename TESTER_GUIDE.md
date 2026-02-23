# GAT Mentor - Manual Testing Guide

Hi! Thanks for helping test GAT Mentor. This guide walks you through everything you need to set up, run, and test the app.

---

## What is this app?

GAT Mentor is a personalized GAT (Graduate Admissions Test) preparation app. It adapts to your skill level, tracks your mastery across topics, and schedules reviews using spaced repetition.

---

## Option A: Test the Deployed Version (Easiest)

If the app is deployed on Railway, just open the URL provided to you in a browser. Skip to [Testing the App](#testing-the-app) below.

---

## Option B: Run Locally on Your Machine

### Prerequisites

Make sure you have these installed:

- **Python 3.12+** - [Download](https://www.python.org/downloads/)
- **Git** - [Download](https://git-scm.com/downloads/)

You do NOT need Flutter installed — the backend serves everything.

### Step 1: Clone the repo

```bash
git clone <repo-url>
cd GAT_personlazed
```

### Step 2: Set up the backend

```bash
cd backend
pip install -r requirements.txt
```

### Step 3: Seed the database

This creates topics, concepts, 150+ questions, and demo accounts:

```bash
python -m seeds.seed
```

You should see output like:
```
Seeding topics...
  Created 3 topics
Seeding concepts...
  Created 15 concepts
Seeding questions from verbal_questions.json...
...
Seeding complete!
  Topics: 3
  Concepts: 15
  Questions: 150
  Users: 2
```

### Step 4: Start the server

```bash
python run.py
```

The server runs at **http://localhost:8000**

### Step 5: Open the app

- **API docs** (interactive): http://localhost:8000/docs
- **Web app** (if Flutter web build exists): http://localhost:8000

---

## Demo Accounts

These are pre-created when you seed the database:

| Account  | Email              | Password     | Notes                          |
|----------|--------------------|--------------|--------------------------------|
| Admin    | admin@gat.com      | admin123     | Goes to admin dashboard        |
| Student  | student@gat.com    | student123   | Regular student, needs onboarding |

You can also create a fresh account through the Register screen.

---

## Testing the App

### Test 0: Admin Dashboard (Admin-Only)

1. Login with `admin@gat.com` / `admin123`
2. You should be redirected to the **Admin Dashboard** (NOT the student home)
3. The dashboard shows:
   - Total Users, Active Questions, Total Attempts, Avg Mastery (4 stat cards)
   - Admin Actions section with "Manage Questions"

**Check for bugs**:
- [ ] Does admin see the admin dashboard (not student interface)?
- [ ] Do the 4 stat cards show real numbers?
- [ ] Does the bottom nav show Dashboard / Questions / Profile (3 tabs)?
- [ ] Does tapping "Manage Questions" navigate to the question list?
- [ ] Does the Questions tab show paginated question bank?
- [ ] Can you deactivate a question? Does it disappear from the list?
- [ ] Does pagination work (next/previous pages)?
- [ ] Does the Profile tab show admin's profile with editable settings?
- [ ] Try navigating to `/home` in the browser — does it redirect back to `/admin`?

---

### Test 1: Registration (Create a New Account)

1. Open the app
2. Tap **Register** (or "Don't have an account?")
3. Fill in:
   - Full Name: anything
   - Email: any email (e.g., `tester@test.com`)
   - Password: at least 6 characters
4. Tap **Create Account**

**Expected**: You are registered and redirected to the onboarding screen.

**Check for bugs**:
- [ ] Can you register with an empty name? (should show error)
- [ ] Can you register with an invalid email like "abc"? (should show error)
- [ ] Can you register with a 3-character password? (should show error)
- [ ] Try registering with the same email twice — does it show an error?

---

### Test 2: Login

1. Go to the login screen
2. Enter your registered email and password
3. Tap **Sign In**

**Expected**: You are logged in and see the onboarding or home screen.

**Check for bugs**:
- [ ] Wrong password — does it show an error message?
- [ ] Empty email — does validation work?
- [ ] Password visibility toggle (eye icon) — does it show/hide password?

---

### Test 3: Onboarding (Profile Setup)

After first login, you should see the onboarding flow:

1. **Set your profile**:
   - Level: Beginner / Average / High Scorer
   - Study Focus: Verbal / Quantitative / Both
   - Exam Date: pick a future date
   - Daily study time: e.g., 45 minutes
   - Target score: e.g., 75

2. **Take the diagnostic test**:
   - You'll get ~15 questions (5 per topic: Verbal, Quantitative, Analytical)
   - Answer each question
   - Submit when done

**Expected**: You see a results summary showing your accuracy per concept and a recommended level.

**Check for bugs**:
- [ ] Can you skip the profile setup without filling fields?
- [ ] Do the diagnostic questions load? Are there exactly ~15?
- [ ] Does submitting the diagnostic show results?
- [ ] After onboarding, are you redirected to the home screen?

---

### Test 4: Practice Questions (Core Feature)

This is the main feature — the adaptive engine picks questions based on your skill level.

1. From the home screen, start a practice session
2. A question should appear with 4 options (A, B, C, D)
3. Select an answer
4. Submit

**Expected**: You see feedback — whether you were correct/wrong, the explanation, and why wrong options are incorrect.

**Check for bugs**:
- [ ] Does a question appear? (if not, the adaptive engine may have an issue)
- [ ] Are all 4 options visible and tappable?
- [ ] After answering, do you see the explanation?
- [ ] Does the "Next Question" button work?
- [ ] Do you get a mix of Verbal, Quantitative, and Analytical questions?
- [ ] If you get many wrong, do questions get easier? (frustration guard)
- [ ] If you get many right in a row, do questions get harder? (streak bonus)
- [ ] Is the timer visible? Does it count correctly?

---

### Test 5: Review Queue (Spaced Repetition)

When you answer questions incorrectly, they get scheduled for review.

1. Answer a few questions wrong on purpose
2. Go to the Review section
3. You should see your wrong answers queued for review

**Expected**: Wrong answers appear in the review queue, showing the question and your previous incorrect answer.

**Check for bugs**:
- [ ] Do wrong answers appear in the review queue?
- [ ] Can you review a question and mark it as reviewed?
- [ ] Does the review count badge update?

---

### Test 6: Dashboard / Stats

1. Go to the Dashboard screen
2. Check your statistics

**Expected**: You see your overall progress, accuracy per topic, mastery levels, and trends.

**Check for bugs**:
- [ ] Do charts/graphs render correctly?
- [ ] Is accuracy calculation correct (matches what you answered)?
- [ ] Does mastery per concept make sense?
- [ ] Does the topic breakdown show all 3 topics (Verbal, Quantitative, Analytical)?

---

### Test 7: Daily Study Plan

1. Go to the Plan section
2. Check today's study plan

**Expected**: A personalized plan listing concepts to study, estimated time, and priority.

**Check for bugs**:
- [ ] Does the plan generate?
- [ ] Does it prioritize weak concepts?
- [ ] Does total time roughly match your daily study minutes setting?
- [ ] Can you mark plan items as complete?

---

### Test 8: Exam Simulation

1. Start an exam simulation session
2. Answer all questions in the session
3. Submit the session

**Expected**: A timed full-exam experience with scoring at the end.

**Check for bugs**:
- [ ] Does the session start with the right number of questions?
- [ ] Is there a timer?
- [ ] Can you navigate between questions?
- [ ] Does submitting show your score?
- [ ] Does the session appear in your history?

---

### Test 9: Streaks

1. Practice at least one question
2. Check the streak counter

**Expected**: Your streak increments when you practice daily.

**Check for bugs**:
- [ ] Does the streak counter show on the home screen?
- [ ] Does it increment after a practice session?

---

### Test 10: Edge Cases & General UX

Try to break things:

- [ ] **Offline behavior**: Turn off internet — what happens? Does the app crash or show a nice error?
- [ ] **Back button**: Press back rapidly — does navigation break?
- [ ] **Empty states**: New account with no attempts — do screens handle "no data" gracefully?
- [ ] **Long text**: Do question texts and explanations display properly without overflow?
- [ ] **Screen rotation** (mobile): Does the layout adjust?
- [ ] **Slow network**: Does the app show loading indicators?
- [ ] **Double-tap submit**: Tap submit rapidly — does it send duplicate answers?
- [ ] **Session expiry**: Stay idle for 24+ hours — does the app ask you to log in again?

---

## How to Report Bugs

When you find a bug, please include:

1. **What you did** (steps to reproduce)
2. **What you expected** to happen
3. **What actually happened** (include screenshot if possible)
4. **Where it happened** (which screen)
5. **Device info** (browser/phone, OS version)

### Bug Report Template

```
BUG: [Short description]

Screen: [Login / Practice / Dashboard / etc.]
Device: [Chrome on Windows / iPhone 15 / etc.]

Steps:
1. Go to ...
2. Tap on ...
3. Enter ...

Expected: ...
Actual: ...

Screenshot: [attach if possible]
```

---

## Testing via API (Optional / Advanced)

If you want to test the backend directly, open **http://localhost:8000/docs** for the Swagger UI.

### Quick API test flow:

**1. Register**
```
POST /api/v1/auth/register
Body: {"email": "test@test.com", "password": "pass123", "full_name": "Tester"}
```

**2. Login**
```
POST /api/v1/auth/login
Body: {"email": "test@test.com", "password": "pass123"}
→ Copy the access_token from the response
```

**3. Set profile**
```
POST /api/v1/onboarding/profile
Header: Authorization: Bearer <your_token>
Body: {"level": "average", "study_focus": "both", "daily_minutes": 45, "target_score": 75}
```

**4. Get diagnostic questions**
```
GET /api/v1/onboarding/diagnostic
Header: Authorization: Bearer <your_token>
```

**5. Get next question**
```
GET /api/v1/questions/next
Header: Authorization: Bearer <your_token>
```

**6. Check health**
```
GET /api/health
→ Should return: {"status": "healthy"}
```

---

## Summary Checklist

| #  | Feature            | Status |
|----|--------------------|--------|
| 0  | Admin Dashboard    | [ ]    |
| 1  | Registration       | [ ]    |
| 2  | Login              | [ ]    |
| 3  | Onboarding         | [ ]    |
| 4  | Practice Questions | [ ]    |
| 5  | Review Queue       | [ ]    |
| 6  | Dashboard/Stats    | [ ]    |
| 7  | Daily Plan         | [ ]    |
| 8  | Exam Simulation    | [ ]    |
| 9  | Streaks            | [ ]    |
| 10 | Edge Cases & UX    | [ ]    |

Mark each with **Pass** / **Fail** / **Partial** when done.

Thanks for testing!
