# Migration Guide: Cloud Connexa API v1.0 to v1.1.0

This document outlines the key differences between Cloud Connexa API v1.0 and v1.1.0, and explains how our Python client library handles these differences to provide a seamless experience regardless of which API version you're using.

## Overview of Changes

The Cloud Connexa API v1.1.0 introduces several important improvements:

1. **Single Resource Endpoints**: Dedicated endpoints for retrieving individual resources by ID (DNS records, User Groups)
2. **Simplified DTOs**: Removal of unnecessary fields in IP Service DTOs (routing information)
3. **Performance Improvements**: Optimized endpoints for better response times

Our client library is designed to work with both versions, automatically detecting the API version and adjusting its behavior accordingly.

## Key Differences by Resource Type

### DNS Record Management

#### API Changes

| Feature | v1.0 | v1.1.0 |
|---------|------|--------|
| Get single record | List all records and filter client-side | Direct `/dns/{record_id}` endpoint |
| List records | `/dns` endpoint with filters | Same behavior |
| Create/update records | Same formats | Same formats |

#### Client Library Implementation

The client library handles these differences transparently:

```python
# Works with both v1.0 and v1.1.0
dns_record = client.dns.get("dns_12345")

# In v1.0: Lists all records and filters client-side
# In v1.1.0: Uses the dedicated endpoint
```

**Implementation details:**

```python
def get(self, record_id: str) -> DNSRecord:
    """Get DNS record by ID."""
    # Use dedicated endpoint in v1.1.0
    if self.api_version == "1.1.0":
        response = self.client.get(f"/api/v1.1.0/dns/{record_id}")
        return DNSRecord.from_dict(response.json())
    
    # Fall back to list and filter in v1.0
    records = self.list(record_id=record_id)
    for record in records:
        if record.id == record_id:
            return record
            
    raise ValueError(f"DNS record {record_id} not found")
```

### User Group Management

#### API Changes

| Feature | v1.0 | v1.1.0 |
|---------|------|--------|
| Get single group | List all groups and filter client-side | Direct `/user_groups/{group_id}` endpoint |
| List groups | `/user_groups` endpoint with filters | Same behavior |
| Create/update groups | Same formats | Same formats |

#### Client Library Implementation

The client library handles these differences transparently:

```python
# Works with both v1.0 and v1.1.0
user_group = client.user_groups.get("group_12345")

# In v1.0: Lists all groups and filters client-side
# In v1.1.0: Uses the dedicated endpoint
```

**Implementation details:**

```python
def get(self, group_id: str) -> UserGroup:
    """Get user group by ID."""
    # Use dedicated endpoint in v1.1.0
    if self.api_version == "1.1.0":
        response = self.client.get(f"/api/v1.1.0/user_groups/{group_id}")
        return UserGroup.from_dict(response.json())
    
    # Fall back to list and filter in v1.0
    groups = self.list(group_id=group_id)
    for group in groups:
        if group.id == group_id:
            return group
            
    raise ValueError(f"User group {group_id} not found")
```

### IP Service Management

#### API Changes

| Feature | v1.0 | v1.1.0 |
|---------|------|--------|
| IP Service DTO | Includes routing information | Routing information removed |
| List/get services | Same endpoints | Same endpoints |
| Create/update services | Requires routing information | No routing information |

#### Client Library Implementation

The client library handles these differences with adapters:

```python
# Works with both v1.0 and v1.1.0
ip_service = client.ip_services.get("service_12345")

# In v1.0: Response includes routing information
# In v1.1.0: Response has no routing information
# Client provides consistent object model either way
```

**Implementation details:**

```python
class IPServiceAdapter:
    """Adapter for converting between IP service formats."""
    
    def to_v110(self, v10_data: dict) -> dict:
        """Convert v1.0 IP service data to v1.1.0 format."""
        # Remove routing information
        result = v10_data.copy()
        if "routing" in result:
            del result["routing"]
        return result
        
    def to_v10(self, v110_data: dict) -> dict:
        """Convert v1.1.0 IP service data to v1.0 format."""
        # Add default routing information
        result = v110_data.copy()
        if "routing" not in result:
            result["routing"] = {
                "network": "0.0.0.0/0",
                "gateway": None
            }
        return result
```

## API Version Detection

The client automatically detects which API version is available:

```python
class CloudConnexaClient:
    """Cloud Connexa API client."""
    
    def __init__(self, api_url, client_id, client_secret):
        self.api_url = api_url
        self.client_id = client_id
        self.client_secret = client_secret
        self.api_version = self._detect_api_version()
        
    def _detect_api_version(self):
        """Detect available API version."""
        try:
            # Try v1.1.0 first
            response = self._request("GET", "/api/v1.1.0/version")
            if response.status_code == 200:
                return "1.1.0"
        except:
            pass
            
        # Fall back to v1.0
        return "1.0"
```

## Migration Best Practices

When migrating your code from v1.0 to v1.1.0, follow these best practices:

1. **Update the Client Library**: Ensure you're using the latest version of our client library
2. **Test Thoroughly**: Test your application with both API versions to ensure compatibility
3. **Use Resource IDs Consistently**: Always use unique resource IDs in your code
4. **Handle Version-Specific Features**: Be aware of version-specific features and handle them appropriately
5. **Review Performance**: Test performance with both versions to identify potential improvements

## Version Compatibility Testing

Our client library includes comprehensive tests for version compatibility:

```python
def test_dns_get_compatibility():
    """Test DNS record retrieval works with both API versions."""
    # Test with v1.0
    client_v10 = create_test_client("1.0")
    record_v10 = client_v10.dns.get("dns_12345")
    
    # Test with v1.1.0
    client_v110 = create_test_client("1.1.0")
    record_v110 = client_v110.dns.get("dns_12345")
    
    # Verify both return equivalent results
    assert record_v10.id == record_v110.id
    assert record_v10.hostname == record_v110.hostname
    assert record_v10.ip == record_v110.ip
```

## Error Handling

The client library provides consistent error handling regardless of API version:

```python
try:
    # Works with both v1.0 and v1.1.0
    record = client.dns.get("dns_12345")
except RecordNotFoundError:
    # Same error type regardless of API version
    print("Record not found")
except APIError as e:
    # Version-specific error details available
    print(f"API error: {e.message} (version: {client.api_version})")
```

## Conclusion

By using our Cloud Connexa Python client, you can work with either API version without changing your code. The library automatically handles the differences between versions, providing a consistent interface and ensuring backward compatibility while allowing you to benefit from the improvements in v1.1.0. 