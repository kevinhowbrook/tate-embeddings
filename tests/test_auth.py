"""Tests for authentication functionality."""

import pytest


def test_invalid_token(test_client):
    """Test that requests with invalid tokens are rejected."""
    headers = {"Authorization": "Bearer invalid_token"}
    response = test_client.post("/embed-text", json={"query": "test"}, headers=headers)
    assert response.status_code == 403
    assert "Invalid authentication" in response.json()["detail"]


def test_missing_token(test_client):
    """Test that requests without authentication are rejected."""
    response = test_client.post("/embed-text", json={"query": "test"})
    assert response.status_code == 403


def test_malformed_auth_header(test_client):
    """Test that requests with malformed auth headers are rejected."""
    headers = {"Authorization": "NotBearer token123"}
    response = test_client.post("/embed-text", json={"query": "test"}, headers=headers)
    assert response.status_code == 403
