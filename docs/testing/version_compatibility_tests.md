# Version Compatibility Tests

This document outlines the testing approach for ensuring compatibility between Cloud Connexa API v1.0 and v1.1.0. The tests verify that our client library correctly handles the differences between API versions while providing a consistent interface.

## Key API Version Differences

The primary differences between v1.0 and v1.1.0 that require compatibility testing are:

1. **DNS Records**
   - v1.0: No single record retrieval endpoint
   - v1.1.0: Direct `/dns/{record_id}` endpoint

2. **User Groups**
   - v1.0: No single group retrieval endpoint
   - v1.1.0: Direct `/user_groups/{group_id}` endpoint

3. **IP Services**
   - v1.0: Includes routing information in DTO
   - v1.1.0: No routing information in DTO

## Test Fixtures

We use pytest fixtures to create clients for both API versions:

```python
import pytest
from cloudconnexa import CloudConnexaClient

@pytest.fixture
def client_v10():
    """Create a test client for API v1.0."""
    return CloudConnexaClient(
        api_url="https://test.api.openvpn.com",
        client_id="test_client_id",
        client_secret="test_client_secret",
        api_version="1.0"
    )

@pytest.fixture
def client_v110():
    """Create a test client for API v1.1.0."""
    return CloudConnexaClient(
        api_url="https://test.api.openvpn.com",
        client_id="test_client_id",
        client_secret="test_client_secret",
        api_version="1.1.0"
    )

@pytest.fixture
def mock_responses():
    """Mock API responses for different versions."""
    return {
        "v10": {
            "dns_list": {
                "items": [
                    {
                        "id": "dns_12345",
                        "network_id": "net_12345",
                        "hostname": "test.example.com",
                        "ip": "192.168.1.1",
                        "type": "A",
                        "ttl": 3600,
                        "created_at": "2023-01-01T00:00:00Z"
                    }
                ]
            },
            "ip_service": {
                "id": "svc_12345",
                "name": "Web Server",
                "host_id": "host_12345",
                "protocol": "tcp",
                "port": 80,
                "enabled": True,
                "routing": {
                    "network": "10.0.0.0/8",
                    "gateway": "10.0.0.1"
                }
            }
        },
        "v110": {
            "dns_record": {
                "id": "dns_12345",
                "network_id": "net_12345",
                "hostname": "test.example.com",
                "ip": "192.168.1.1",
                "type": "A",
                "ttl": 3600,
                "created_at": "2023-01-01T00:00:00Z"
            },
            "ip_service": {
                "id": "svc_12345",
                "name": "Web Server",
                "host_id": "host_12345",
                "protocol": "tcp",
                "port": 80,
                "enabled": True
                # No routing information
            }
        }
    }
```

## DNS Record Tests

Test retrieving a DNS record with both API versions:

```python
def test_dns_record_get_compatibility(client_v10, client_v110, mock_responses, requests_mock):
    """Test DNS record retrieval compatibility across API versions."""
    record_id = "dns_12345"
    
    # Mock v1.0 API (list and filter)
    requests_mock.get(
        f"{client_v10.api_url}/api/1.0/dns",
        json=mock_responses["v10"]["dns_list"]
    )
    
    # Mock v1.1.0 API (direct endpoint)
    requests_mock.get(
        f"{client_v110.api_url}/api/1.1.0/dns/{record_id}",
        json=mock_responses["v110"]["dns_record"]
    )
    
    # Get record with v1.0 client
    record_v10 = client_v10.dns.get(record_id)
    
    # Get record with v1.1.0 client
    record_v110 = client_v110.dns.get(record_id)
    
    # Verify both clients return equivalent records
    assert record_v10.id == record_v110.id
    assert record_v10.hostname == record_v110.hostname
    assert record_v10.ip == record_v110.ip
    assert record_v10.type == record_v110.type
    assert record_v10.ttl == record_v110.ttl
```

## User Group Tests

Test retrieving a user group with both API versions:

```python
def test_user_group_get_compatibility(client_v10, client_v110, requests_mock):
    """Test user group retrieval compatibility across API versions."""
    group_id = "group_12345"
    group_data = {
        "id": group_id,
        "name": "Developers",
        "description": "Development team",
        "created_at": "2023-01-01T00:00:00Z"
    }
    
    # Mock v1.0 API (list and filter)
    requests_mock.get(
        f"{client_v10.api_url}/api/1.0/user_groups",
        json={"items": [group_data]}
    )
    
    # Mock v1.1.0 API (direct endpoint)
    requests_mock.get(
        f"{client_v110.api_url}/api/1.1.0/user_groups/{group_id}",
        json=group_data
    )
    
    # Get group with v1.0 client
    group_v10 = client_v10.user_groups.get(group_id)
    
    # Get group with v1.1.0 client
    group_v110 = client_v110.user_groups.get(group_id)
    
    # Verify both clients return equivalent groups
    assert group_v10.id == group_v110.id
    assert group_v10.name == group_v110.name
    assert group_v10.description == group_v110.description
```

## IP Service Tests

Test handling IP service DTO differences between versions:

```python
def test_ip_service_compatibility(client_v10, client_v110, mock_responses, requests_mock):
    """Test IP service compatibility across API versions."""
    service_id = "svc_12345"
    
    # Mock v1.0 API (with routing)
    requests_mock.get(
        f"{client_v10.api_url}/api/1.0/ip_services/{service_id}",
        json=mock_responses["v10"]["ip_service"]
    )
    
    # Mock v1.1.0 API (without routing)
    requests_mock.get(
        f"{client_v110.api_url}/api/1.1.0/ip_services/{service_id}",
        json=mock_responses["v110"]["ip_service"]
    )
    
    # Get service with v1.0 client
    service_v10 = client_v10.ip_services.get(service_id)
    
    # Get service with v1.1.0 client
    service_v110 = client_v110.ip_services.get(service_id)
    
    # Verify basic properties match
    assert service_v10.id == service_v110.id
    assert service_v10.name == service_v110.name
    assert service_v10.host_id == service_v110.host_id
    assert service_v10.protocol == service_v110.protocol
    assert service_v10.port == service_v110.port
    
    # Verify routing is available in v1.0 but not in v1.1.0
    assert hasattr(service_v10, "routing")
    assert service_v10.routing["network"] == "10.0.0.0/8"
    assert not hasattr(service_v110, "routing")
```

## API Version Detection Tests

Test automatic API version detection:

```python
def test_version_detection(requests_mock):
    """Test API version auto-detection."""
    api_url = "https://test.api.openvpn.com"
    
    # Mock v1.1.0 version endpoint (success)
    requests_mock.get(
        f"{api_url}/api/v1.1.0/version",
        status_code=200
    )
    
    # Create client without explicit version
    client = CloudConnexaClient(
        api_url=api_url,
        client_id="test_client_id",
        client_secret="test_client_secret"
    )
    
    # Verify detected version is 1.1.0
    assert client.api_version == "1.1.0"
    
    # Reset and mock v1.1.0 failure
    requests_mock.reset()
    requests_mock.get(
        f"{api_url}/api/v1.1.0/version",
        status_code=404
    )
    
    # Create another client
    client = CloudConnexaClient(
        api_url=api_url,
        client_id="test_client_id",
        client_secret="test_client_secret"
    )
    
    # Verify fallback to v1.0
    assert client.api_version == "1.0"
```

## Comprehensive Test Matrix

Our test matrix covers all API functionality across both versions:

| Feature | v1.0 Test | v1.1.0 Test | Cross-Version Test |
|---------|-----------|-------------|-------------------|
| DNS Single Record | ✅ | ✅ | ✅ |
| DNS List | ✅ | ✅ | ✅ |
| DNS Create | ✅ | ✅ | ✅ |
| User Group Single | ✅ | ✅ | ✅ |
| User Group List | ✅ | ✅ | ✅ |
| User Group Create | ✅ | ✅ | ✅ |
| IP Service (with/without routing) | ✅ | ✅ | ✅ |
| Version Detection | n/a | n/a | ✅ |

## Testing with Both Versions in CI

Our continuous integration pipeline runs tests against both API versions to ensure compatibility:

```yaml
# Example GitHub Actions workflow
jobs:
  test:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        api_version: ["1.0", "1.1.0"]
    
    steps:
      - uses: actions/checkout@v2
      - name: Set up Python
        uses: actions/setup-python@v2
        with:
          python-version: '3.9'
      
      - name: Install dependencies
        run: |
          python -m pip install --upgrade pip
          pip install -e ".[dev]"
      
      - name: Run tests
        run: |
          pytest tests/ --api-version=${{ matrix.api_version }}
```

This ensures that our client works consistently with both API versions and handles the transition between them seamlessly. 