"""Example fixture for testing."""

from uuid import uuid4

import pytest

from tests.consts import PROJECT_DIR


@pytest.fixture(name="example_fixture", scope="session")
def test_session_id() -> str:
    """Generate a unique test session ID."""
    session_id = str(PROJECT_DIR) + str(uuid4())[:6]
    return session_id
