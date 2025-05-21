"""Test fixtures for the Cloud Connexa client."""

import pytest
from unittest.mock import patch, MagicMock


@pytest.fixture
def mock_response():
    """Create a mock response object."""
    mock = MagicMock()
    mock.status_code = 200
    mock.json.return_value = {}
    return mock


@pytest.fixture
def test_api_url():
    """Return a test API URL."""
    return "https://test.api.openvpn.com"


@pytest.fixture
def test_client_id():
    """Return a test client ID."""
    return "test-client-id"


@pytest.fixture
def test_client_secret():
    """Return a test client secret."""
    return "test-client-secret"


@pytest.fixture
def api_token():
    """Return a test API token."""
    return "test-api-token"
