"""Shared test fixtures."""

import pytest
from fastapi.testclient import TestClient

from app.config import settings
from app.main import app


@pytest.fixture(scope="session")
def test_client():
    """
    Create a TestClient that properly initializes the lifespan.

    This ensures the embedding model is loaded once for all tests.
    """
    with TestClient(app) as client:
        yield client


@pytest.fixture(scope="session")
def auth_headers():
    """Return authentication headers for tests."""
    return {"Authorization": f"Bearer {settings.auth_token}"}
