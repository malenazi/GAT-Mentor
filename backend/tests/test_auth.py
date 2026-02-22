"""Tests for authentication endpoints."""


def test_register(client):
    resp = client.post(
        "/api/v1/auth/register",
        json={"email": "new@test.com", "password": "pass123", "full_name": "New User"},
    )
    assert resp.status_code == 200
    data = resp.json()
    assert "access_token" in data
    assert data["token_type"] == "bearer"


def test_register_duplicate_email(client):
    client.post(
        "/api/v1/auth/register",
        json={"email": "dup@test.com", "password": "pass123", "full_name": "User 1"},
    )
    resp = client.post(
        "/api/v1/auth/register",
        json={"email": "dup@test.com", "password": "pass456", "full_name": "User 2"},
    )
    assert resp.status_code == 400


def test_login(client):
    # Register first
    client.post(
        "/api/v1/auth/register",
        json={"email": "login@test.com", "password": "pass123", "full_name": "Login User"},
    )
    # Then login
    resp = client.post(
        "/api/v1/auth/login",
        json={"email": "login@test.com", "password": "pass123"},
    )
    assert resp.status_code == 200
    assert "access_token" in resp.json()


def test_login_wrong_password(client):
    client.post(
        "/api/v1/auth/register",
        json={"email": "wrong@test.com", "password": "pass123", "full_name": "User"},
    )
    resp = client.post(
        "/api/v1/auth/login",
        json={"email": "wrong@test.com", "password": "wrongpass"},
    )
    assert resp.status_code == 401


def test_get_me(client):
    # Register and get token
    reg = client.post(
        "/api/v1/auth/register",
        json={"email": "me@test.com", "password": "pass123", "full_name": "Me User"},
    )
    token = reg.json()["access_token"]

    # Get profile
    resp = client.get(
        "/api/v1/auth/me",
        headers={"Authorization": f"Bearer {token}"},
    )
    assert resp.status_code == 200
    data = resp.json()
    assert data["email"] == "me@test.com"
    assert data["full_name"] == "Me User"
    assert data["onboarding_complete"] is False


def test_unauthorized_access(client):
    resp = client.get("/api/v1/auth/me")
    assert resp.status_code == 401

    resp = client.get(
        "/api/v1/auth/me",
        headers={"Authorization": "Bearer invalid_token"},
    )
    assert resp.status_code == 401
