import pytest
from unittest.mock import patch, MagicMock
from src.cloudconnexa import CloudConnexaClient

def test_network_list():
    """Test listing networks."""
    client = CloudConnexaClient(
        api_url="https://test.api.openvpn.com",
        client_id="test-client-id",
        client_secret="test-client-secret"
    )
    
    # Mock the session's get method
    mock_response = MagicMock()
    mock_response.status_code = 200
    mock_response.json.return_value = [
        {"id": "1", "name": "Network 1"},
        {"id": "2", "name": "Network 2"}
    ]
    
    with patch.object(client._session, 'get', return_value=mock_response):
        networks = client.networks.list()
        assert len(networks) == 2
        assert networks[0].name == "Network 1"
        assert networks[1].name == "Network 2"

def test_network_create():
    """Test creating a network."""
    client = CloudConnexaClient(
        api_url="https://test.api.openvpn.com",
        client_id="test-client-id",
        client_secret="test-client-secret"
    )
    
    # Mock the session's post method
    mock_response = MagicMock()
    mock_response.status_code = 201
    mock_response.json.return_value = {
        "id": "3",
        "name": "New Network",
        "description": "A test network",
        "internet_access": "split_tunnel_on",
        "egress": True
    }
    
    with patch.object(client._session, 'post', return_value=mock_response):
        new_network = client.networks.create(
            name="New Network",
            description="A test network"
        )
        assert new_network.name == "New Network"
        assert new_network.description == "A test network"

def test_network_delete():
    """Test deleting a network."""
    client = CloudConnexaClient(
        api_url="https://test.api.openvpn.com",
        client_id="test-client-id",
        client_secret="test-client-secret"
    )
    
    # Mock the session's delete method
    mock_response = MagicMock()
    mock_response.status_code = 204
    
    with patch.object(client._session, 'delete', return_value=mock_response):
        result = client.networks.delete(network_id="3")
        assert result is True 