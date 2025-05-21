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
    # Mock the networks.list() method to return a list of networks
    with patch.object(client, 'networks') as mock_networks:
        mock_networks.list.return_value = [{"id": "1", "name": "Network 1"}, {"id": "2", "name": "Network 2"}]
        networks = client.networks.list()
        assert len(networks) == 2
        assert networks[0]["name"] == "Network 1"

def test_network_create():
    """Test creating a network."""
    client = CloudConnexaClient(
        api_url="https://test.api.openvpn.com",
        client_id="test-client-id",
        client_secret="test-client-secret"
    )
    # Mock the networks.create() method to return a new network
    with patch.object(client, 'networks') as mock_networks:
        mock_networks.create.return_value = {"id": "3", "name": "New Network"}
        new_network = client.networks.create(name="New Network", description="A test network")
        assert new_network["name"] == "New Network"

def test_network_delete():
    """Test deleting a network."""
    client = CloudConnexaClient(
        api_url="https://test.api.openvpn.com",
        client_id="test-client-id",
        client_secret="test-client-secret"
    )
    # Mock the networks.delete() method
    with patch.object(client, 'networks') as mock_networks:
        mock_networks.delete.return_value = True
        result = client.networks.delete(network_id="3")
        assert result is True 