import os
import pytest
from src.cloudconnexa import CloudConnexaClient

def test_real_authentication():
    """
    Integration test: Attempts real authentication using credentials from environment or .env file.
    This test will fail unless valid credentials are provided.
    """
    api_url = os.getenv("CLOUDCONNEXA_API_URL")
    client_id = os.getenv("CLOUDCONNEXA_CLIENT_ID")
    client_secret = os.getenv("CLOUDCONNEXA_CLIENT_SECRET")

    if not (api_url and client_id and client_secret):
        pytest.skip("Integration credentials not set in environment or .env file.")

    client = CloudConnexaClient()
    assert client.authenticate() is True
    print("Authenticated successfully with real credentials.") 