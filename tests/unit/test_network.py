import pytest
from unittest.mock import patch, MagicMock
from src.cloudconnexa import CloudConnexaClient
from src.cloudconnexa.utils.errors import ResourceNotFoundError, ValidationError, RateLimitError
from datetime import datetime

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
        result = client.networks.list()
        assert len(result['data']) == 2
        assert result['pagination']['total'] == 2
        assert result['pagination']['page'] == 1
        assert result['pagination']['per_page'] == 2
        assert not result['pagination']['has_more']

def test_network_list_empty():
    """Test listing networks when none exist."""
    client = CloudConnexaClient(
        api_url="https://test.api.openvpn.com",
        client_id="test-client-id",
        client_secret="test-client-secret"
    )
    
    mock_response = MagicMock()
    mock_response.status_code = 200
    mock_response.json.return_value = []
    
    with patch.object(client._session, 'get', return_value=mock_response):
        result = client.networks.list()
        assert len(result['data']) == 0
        assert result['pagination']['total'] == 0
        assert result['pagination']['page'] == 1
        assert result['pagination']['per_page'] == 0
        assert not result['pagination']['has_more']

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
        "egress": True,
        "created_at": "2024-01-01T00:00:00Z",
        "updated_at": "2024-01-01T00:00:00Z",
        "status": "active",
        "vpn_region": "us-west",
        "dns_servers": ["8.8.8.8"],
        "routes": [],
        "connectors": []
    }
    
    with patch.object(client._session, 'post', return_value=mock_response):
        new_network = client.networks.create(
            name="New Network",
            description="A test network",
            internet_access="split_tunnel_on",
            egress=True,
            vpn_region="us-west"
        )
        assert new_network.name == "New Network"
        assert new_network.description == "A test network"
        assert new_network.internet_access == "split_tunnel_on"
        assert new_network.egress is True
        assert new_network.vpn_region == "us-west"
        assert new_network.dns_servers == ["8.8.8.8"]
        assert isinstance(new_network.created_at, datetime)
        assert isinstance(new_network.updated_at, datetime)

def test_network_create_validation_error():
    """Test network creation with invalid data."""
    client = CloudConnexaClient(
        api_url="https://test.api.openvpn.com",
        client_id="test-client-id",
        client_secret="test-client-secret"
    )
    mock_response = MagicMock()
    mock_response.status_code = 400
    mock_response.json.return_value = {
        "error": {
            "code": "validation_error",
            "message": "Validation failed",
            "details": {
                "name": ["Name cannot be empty"]
            }
        }
    }
    with patch.object(client._session, 'post', return_value=mock_response):
        with pytest.raises(ValidationError) as exc_info:
            client.networks.create(name="")
        assert exc_info.value.status_code == 400
        assert "Validation failed" in str(exc_info.value)

def test_network_get():
    """Test getting a network."""
    client = CloudConnexaClient(
        api_url="https://test.api.openvpn.com",
        client_id="test-client-id",
        client_secret="test-client-secret"
    )
    
    mock_response = MagicMock()
    mock_response.status_code = 200
    mock_response.json.return_value = {
        "id": "1",
        "name": "Test Network",
        "description": "A test network",
        "internet_access": "split_tunnel_on",
        "egress": True,
        "created_at": "2024-01-01T00:00:00Z",
        "updated_at": "2024-01-01T00:00:00Z",
        "status": "active",
        "vpn_region": "us-west",
        "dns_servers": ["8.8.8.8"],
        "routes": [],
        "connectors": []
    }
    
    with patch.object(client._session, 'get', return_value=mock_response):
        network = client.networks.get(network_id="1")
        assert network.id == "1"
        assert network.name == "Test Network"
        assert network.description == "A test network"
        assert network.internet_access == "split_tunnel_on"
        assert network.egress is True
        assert network.vpn_region == "us-west"
        assert network.dns_servers == ["8.8.8.8"]
        assert isinstance(network.created_at, datetime)
        assert isinstance(network.updated_at, datetime)

def test_network_get_not_found():
    """Test getting a non-existent network."""
    client = CloudConnexaClient(
        api_url="https://test.api.openvpn.com",
        client_id="test-client-id",
        client_secret="test-client-secret"
    )
    mock_response = MagicMock()
    mock_response.status_code = 404
    mock_response.json.return_value = {
        "error": {
            "code": "not_found",
            "message": "Network not found"
        }
    }
    with patch.object(client._session, 'get', return_value=mock_response):
        with pytest.raises(ResourceNotFoundError) as exc_info:
            client.networks.get(network_id="non_existent")
        assert exc_info.value.status_code == 404
        assert "Network with ID 'non_existent' not found" in str(exc_info.value)

def test_network_update():
    """Test updating a network."""
    client = CloudConnexaClient(
        api_url="https://test.api.openvpn.com",
        client_id="test-client-id",
        client_secret="test-client-secret"
    )
    
    mock_response = MagicMock()
    mock_response.status_code = 200
    mock_response.json.return_value = {
        "id": "1",
        "name": "Updated Network",
        "description": "Updated description",
        "internet_access": "split_tunnel_on",
        "egress": True,
        "created_at": "2024-01-01T00:00:00Z",
        "updated_at": "2024-01-02T00:00:00Z",
        "status": "active",
        "vpn_region": "us-west",
        "dns_servers": ["8.8.8.8"],
        "routes": [],
        "connectors": []
    }
    
    with patch.object(client._session, 'patch', return_value=mock_response):
        updated_network = client.networks.update(
            network_id="1",
            name="Updated Network",
            description="Updated description"
        )
        assert updated_network.name == "Updated Network"
        assert updated_network.description == "Updated description"
        assert isinstance(updated_network.updated_at, datetime)

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

def test_network_delete_not_found():
    """Test deleting a non-existent network."""
    client = CloudConnexaClient(
        api_url="https://test.api.openvpn.com",
        client_id="test-client-id",
        client_secret="test-client-secret"
    )
    mock_response = MagicMock()
    mock_response.status_code = 404
    mock_response.json.return_value = {
        "error": {
            "code": "not_found",
            "message": "Network not found"
        }
    }
    with patch.object(client._session, 'delete', return_value=mock_response):
        with pytest.raises(ResourceNotFoundError) as exc_info:
            client.networks.delete(network_id="non_existent")
        assert exc_info.value.status_code == 404
        assert "Network with ID 'non_existent' not found" in str(exc_info.value)

def test_network_list_with_pagination():
    """Test listing networks with pagination."""
    client = CloudConnexaClient(
        api_url="https://test.api.openvpn.com",
        client_id="test-client-id",
        client_secret="test-client-secret"
    )
    
    mock_response = MagicMock()
    mock_response.status_code = 200
    mock_response.json.return_value = {
        "data": [
            {"id": "1", "name": "Network 1"},
            {"id": "2", "name": "Network 2"}
        ],
        "pagination": {
            "total": 4,
            "page": 1,
            "per_page": 2,
            "has_more": True
        }
    }
    
    with patch.object(client._session, 'get', return_value=mock_response):
        result = client.networks.list(page=1, per_page=2)
        assert len(result['data']) == 2
        assert result['pagination']['total'] == 4
        assert result['pagination']['page'] == 1
        assert result['pagination']['per_page'] == 2
        assert result['pagination']['has_more']

def test_network_list_with_filtering():
    """Test listing networks with filtering."""
    client = CloudConnexaClient(
        api_url="https://test.api.openvpn.com",
        client_id="test-client-id",
        client_secret="test-client-secret"
    )
    
    mock_response = MagicMock()
    mock_response.status_code = 200
    mock_response.json.return_value = {
        "data": [
            {"id": "1", "name": "Production Network", "status": "active"}
        ],
        "pagination": {
            "total": 1,
            "page": 1,
            "per_page": 10,
            "has_more": False
        }
    }
    
    with patch.object(client._session, 'get', return_value=mock_response):
        result = client.networks.list(status="active", name="Production")
        assert len(result['data']) == 1
        assert result['data'][0].name == "Production Network"
        assert result['data'][0].status == "active"
        assert result['pagination']['total'] == 1

def test_network_list_with_sorting():
    """Test listing networks with sorting."""
    client = CloudConnexaClient(
        api_url="https://test.api.openvpn.com",
        client_id="test-client-id",
        client_secret="test-client-secret"
    )
    
    mock_response = MagicMock()
    mock_response.status_code = 200
    mock_response.json.return_value = {
        "data": [
            {"id": "2", "name": "Network B", "created_at": "2024-02-01T00:00:00Z"},
            {"id": "1", "name": "Network A", "created_at": "2024-01-01T00:00:00Z"}
        ],
        "pagination": {
            "total": 2,
            "page": 1,
            "per_page": 10,
            "has_more": False
        }
    }
    
    with patch.object(client._session, 'get', return_value=mock_response):
        result = client.networks.list(sort_by="created_at", sort_order="desc")
        assert len(result['data']) == 2
        assert result['data'][0].name == "Network B"
        assert result['data'][1].name == "Network A"
        assert result['pagination']['total'] == 2

def test_network_list_rate_limit():
    """Test rate limiting when listing networks."""
    client = CloudConnexaClient(
        api_url="https://test.api.openvpn.com",
        client_id="test-client-id",
        client_secret="test-client-secret"
    )
    
    mock_response = MagicMock()
    mock_response.status_code = 429
    mock_response.headers = {"Retry-After": "60"}
    mock_response.json.return_value = {
        "error": {
            "code": "rate_limit_exceeded",
            "message": "Rate limit exceeded",
            "retry_after": 60
        }
    }
    
    with patch.object(client._session, 'get', return_value=mock_response):
        with pytest.raises(RateLimitError) as exc_info:
            client.networks.list()
        assert exc_info.value.status_code == 429
        assert "Rate limit exceeded" in str(exc_info.value)
        assert exc_info.value.retry_after == 60 