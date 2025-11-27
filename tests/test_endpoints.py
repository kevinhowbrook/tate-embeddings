"""Tests for API endpoints."""

import pytest


def test_root(test_client):
    """Test the health check endpoint."""
    response = test_client.get("/")
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "ok"
    assert data["service"] == "tate-embeddings"
    assert "model" in data
    assert "pretrained" in data


def test_embed_text_success(test_client, auth_headers):
    """Test successful text embedding generation."""
    response = test_client.post(
        "/embed-text", json={"query": "landscape painting"}, headers=auth_headers
    )
    assert response.status_code == 200
    data = response.json()
    assert "embedding" in data
    assert isinstance(data["embedding"], list)
    # ViT-B-32 produces 512-dimensional embeddings
    assert len(data["embedding"]) == 512
    # Check that values are floats and normalized (roughly between -1 and 1)
    assert all(isinstance(x, float) for x in data["embedding"])
    assert all(-1.5 <= x <= 1.5 for x in data["embedding"])


def test_embed_text_empty_query(test_client, auth_headers):
    """Test that empty queries are rejected."""
    response = test_client.post("/embed-text", json={"query": ""}, headers=auth_headers)
    assert response.status_code == 422  # Validation error


def test_embed_text_unauthenticated(test_client):
    """Test that unauthenticated text embedding requests are rejected."""
    response = test_client.post("/embed-text", json={"query": "landscape painting"})
    assert response.status_code == 403


def test_embed_image_success(test_client, auth_headers):
    """Test successful image embedding generation."""
    response = test_client.post(
        "/embed-image",
        json={"url": "https://www.tate.org.uk/static/images/default.jpg"},
        headers=auth_headers,
    )
    assert response.status_code == 200
    data = response.json()
    assert "embedding" in data
    assert isinstance(data["embedding"], list)
    # ViT-B-32 produces 512-dimensional embeddings
    assert len(data["embedding"]) == 512
    # Check that values are floats and normalized
    assert all(isinstance(x, float) for x in data["embedding"])
    assert all(-1.5 <= x <= 1.5 for x in data["embedding"])


def test_embed_image_invalid_url(test_client, auth_headers):
    """Test that invalid image URLs return an error."""
    response = test_client.post(
        "/embed-image",
        json={"url": "https://invalid.example.com/nonexistent.jpg"},
        headers=auth_headers,
    )
    assert response.status_code == 500


def test_embed_image_malformed_url(test_client, auth_headers):
    """Test that malformed URLs are rejected."""
    response = test_client.post(
        "/embed-image", json={"url": "not-a-url"}, headers=auth_headers
    )
    assert response.status_code == 422  # Validation error


def test_embed_image_unauthenticated(test_client):
    """Test that unauthenticated image embedding requests are rejected."""
    response = test_client.post(
        "/embed-image",
        json={"url": "https://www.tate.org.uk/static/images/default.jpg"},
    )
    assert response.status_code == 403


def test_embed_text_long_query(test_client, auth_headers):
    """Test embedding generation with a longer text query."""
    long_query = "A beautiful landscape painting depicting rolling hills, " * 10
    response = test_client.post(
        "/embed-text", json={"query": long_query}, headers=auth_headers
    )
    assert response.status_code == 200
    data = response.json()
    assert len(data["embedding"]) == 512


def test_embed_text_special_characters(test_client, auth_headers):
    """Test embedding generation with special characters."""
    response = test_client.post(
        "/embed-text",
        json={"query": "Picasso's 'Guernica' & Matisse's œuvres"},
        headers=auth_headers,
    )
    assert response.status_code == 200
    data = response.json()
    assert len(data["embedding"]) == 512
