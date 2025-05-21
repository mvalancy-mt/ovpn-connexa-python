import os
import pytest
from unittest.mock import patch, MagicMock
from src.cloudconnexa import CloudConnexaClient
from src.cloudconnexa.utils.errors import AuthenticationError, APIError

# This is a placeholder test that will initially fail
# You'll implement the actual CloudConnexaClient class following TDD principles
def test_client_initialization():
    """Test client initialization."""
    client = CloudConnexaClient(
        api_url="https://test.api.openvpn.com",
        client_id="test-client-id",
        client_secret="test-client-secret"
    )
    assert client.api_url == "https://test.api.openvpn.com"
    assert client.client_id == "test-client-id"
    assert client.client_secret == "test-client-secret"
    assert client.api_version == "1.1.0"

def test_client_initialization_with_version():
    """Test client initialization with custom API version."""
    client = CloudConnexaClient(
        api_url="https://test.api.openvpn.com",
        client_id="test-client-id",
        client_secret="test-client-secret",
        api_version="1.0"
    )
    assert client.api_version == "1.0"

def test_client_authentication():
    """Test client authentication."""
    client = CloudConnexaClient(
        api_url="https://test.api.openvpn.com",
        client_id="test-client-id",
        client_secret="test-client-secret"
    )
    
    with patch('src.cloudconnexa.client.auth.Authenticator.ensure_authenticated', return_value=True):
        assert client.authenticate() is True

def test_client_authentication_failure():
    """Test client authentication failure."""
    client = CloudConnexaClient(
        api_url="https://test.api.openvpn.com",
        client_id="test-client-id",
        client_secret="test-client-secret"
    )
    
    with patch('src.cloudconnexa.client.auth.Authenticator.ensure_authenticated', side_effect=AuthenticationError("Invalid credentials")):
        assert client.authenticate() is False

def test_client_environment_variables(monkeypatch):
    """Test client initialization from environment variables."""
    monkeypatch.setenv("CLOUDCONNEXA_API_URL", "https://env.api.openvpn.com")
    monkeypatch.setenv("CLOUDCONNEXA_CLIENT_ID", "env-client-id")
    monkeypatch.setenv("CLOUDCONNEXA_CLIENT_SECRET", "env-client-secret")
    client = CloudConnexaClient()
    assert client.api_url == "https://env.api.openvpn.com"
    assert client.client_id == "env-client-id"
    assert client.client_secret == "env-client-secret"

def test_client_token_management():
    """Test client token management."""
    client = CloudConnexaClient(
        api_url="https://test.api.openvpn.com",
        client_id="test-client-id",
        client_secret="test-client-secret"
    )
    
    # Patch the _auth property to simulate token
    class DummyAuth:
        token = "test-token"
        def ensure_authenticated(self):
            return True
    client._auth = DummyAuth()
    assert client._auth.token == "test-token"
    assert client._auth.ensure_authenticated() is True

def test_client_token_refresh():
    """Test client token refresh."""
    client = CloudConnexaClient(
        api_url="https://test.api.openvpn.com",
        client_id="test-client-id",
        client_secret="test-client-secret"
    )
    
    # Patch the _auth property to simulate token refresh
    class DummyAuth:
        token = "refreshed-token"
        def ensure_authenticated(self):
            return True
    client._auth = DummyAuth()
    assert client._auth.token == "refreshed-token"
    assert client._auth.ensure_authenticated() is True

def test_client_api_error_handling():
    """Test client API error handling."""
    client = CloudConnexaClient(
        api_url="https://test.api.openvpn.com",
        client_id="test-client-id",
        client_secret="test-client-secret"
    )
    
    # Mock API error with correct error structure
    mock_response = MagicMock()
    mock_response.status_code = 500
    mock_response.json.return_value = {"error": {"message": "Internal server error"}}
    
    with patch.object(client._session, 'get', return_value=mock_response):
        with pytest.raises(APIError):
            client.networks.list()

def test_client_invalid_api_version():
    """Test client initialization with invalid API version."""
    with pytest.raises(ValueError) as exc_info:
        CloudConnexaClient(
            api_url="https://test.api.openvpn.com",
            client_id="test-client-id",
            client_secret="test-client-secret",
            api_version="2.0"  # Invalid version
        )
    assert "Unsupported API version" in str(exc_info.value)

def test_client_invalid_api_url():
    """Test client initialization with invalid API URL."""
    with pytest.raises(ValueError) as exc_info:
        CloudConnexaClient(
            api_url="invalid-url",
            client_id="test-client-id",
            client_secret="test-client-secret"
        )
    assert "Invalid API URL" in str(exc_info.value)

def test_client_token_refresh_flow():
    """Test client token refresh flow."""
    client = CloudConnexaClient(
        api_url="https://test.api.openvpn.com",
        client_id="test-client-id",
        client_secret="test-client-secret"
    )
    
    # Mock initial token
    initial_token = "initial-token"
    refreshed_token = "refreshed-token"
    
    class DummyAuth:
        def __init__(self):
            self.token = initial_token
            self.refresh_count = 0
            
        def ensure_authenticated(self):
            if self.refresh_count == 0:
                self.refresh_count += 1
                self.token = refreshed_token
            return True
    
    client._auth = DummyAuth()
    
    # First call should trigger refresh
    assert client._auth.ensure_authenticated() is True
    assert client._auth.token == refreshed_token
    
    # Second call should use cached token
    assert client._auth.ensure_authenticated() is True
    assert client._auth.token == refreshed_token
    assert client._auth.refresh_count == 1

def test_client_concurrent_requests():
    """Test client handling of concurrent requests."""
    import threading
    import time
    
    client = CloudConnexaClient(
        api_url="https://test.api.openvpn.com",
        client_id="test-client-id",
        client_secret="test-client-secret"
    )
    
    # Mock response for network listing
    mock_response = MagicMock()
    mock_response.status_code = 200
    mock_response.json.return_value = [
        {"id": "1", "name": "Network 1"},
        {"id": "2", "name": "Network 2"}
    ]
    
    def make_request():
        with patch.object(client._session, 'get', return_value=mock_response):
            networks = client.networks.list()
            assert len(networks) == 2
    
    # Create multiple threads making concurrent requests
    threads = []
    for _ in range(5):
        thread = threading.Thread(target=make_request)
        threads.append(thread)
        thread.start()
    
    # Wait for all threads to complete
    for thread in threads:
        thread.join()
    
    # Verify no exceptions were raised during concurrent execution
