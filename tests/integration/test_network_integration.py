import os
import pytest
from src.cloudconnexa import CloudConnexaClient

REQUIRED_ENV_VARS = [
    "CLOUDCONNEXA_API_URL",
    "CLOUDCONNEXA_CLIENT_ID",
    "CLOUDCONNEXA_CLIENT_SECRET"
]

def has_real_credentials():
    return all(os.getenv(var) for var in REQUIRED_ENV_VARS)

pytestmark = pytest.mark.skipif(
    not has_real_credentials(),
    reason="Integration test requires real Cloud Connexa credentials in environment or .env file."
)

def get_real_client():
    return CloudConnexaClient()

def test_real_network_list():
    """Test listing networks with real API."""
    client = get_real_client()
    networks = client.networks.list()
    assert isinstance(networks, list)
    # Optionally print for debug
    print(f"Found {len(networks)} networks (integration test)")

def test_real_network_create_and_delete():
    """Test creating and deleting a network with real API."""
    client = get_real_client()
    # Create
    new_network = client.networks.create(
        name="Integration Test Network",
        description="Created by integration test"
    )
    assert new_network.name == "Integration Test Network"
    # Delete
    result = client.networks.delete(network_id=new_network.id)
    assert result is True 