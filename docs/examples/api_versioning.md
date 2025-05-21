# API Versioning and Migration

This example demonstrates how to work with different API versions in the Cloud Connexa client, including handling version transitions in your application.

## Basic Version Selection

You can specify which API version to use when initializing the client:

```python
from cloudconnexa import CloudConnexaClient
import os

# Default to latest version (currently 1.1.0)
client = CloudConnexaClient(
    api_url=os.getenv("CLOUDCONNEXA_API_URL"),
    client_id=os.getenv("CLOUDCONNEXA_CLIENT_ID"),
    client_secret=os.getenv("CLOUDCONNEXA_CLIENT_SECRET")
)

# Explicitly use v1.0
client_v1_0 = CloudConnexaClient(
    api_url=os.getenv("CLOUDCONNEXA_API_URL"),
    client_id=os.getenv("CLOUDCONNEXA_CLIENT_ID"),
    client_secret=os.getenv("CLOUDCONNEXA_CLIENT_SECRET"),
    api_version="1.0"
)
```

## Understanding Version Differences

The main differences between v1.0 and v1.1.0 are:

1. **DNS Record Retrieval**
   - v1.0: No single record endpoint, must list and filter
   - v1.1.0: Direct single record retrieval endpoint

2. **User Group Retrieval**
   - v1.0: No single group endpoint, must list and filter
   - v1.1.0: Direct single group retrieval endpoint

3. **IP Service DTO**
   - v1.0: Includes routing information
   - v1.1.0: Routing information removed

## Using Version-Specific Features

The client automatically uses the appropriate implementation based on your configured version:

```python
# Using v1.1.0 DNS features
client = CloudConnexaClient(
    # ... auth credentials ...
    api_version="1.1.0"  # This is the default
)

# This uses the dedicated endpoint in v1.1.0
dns_record = client.dns.get("record_123")

# Using v1.0 DNS features
client_v1_0 = CloudConnexaClient(
    # ... auth credentials ...
    api_version="1.0"
)

# This will list and filter since v1.0 has no dedicated endpoint
dns_record = client_v1_0.dns.get("record_123")
```

The API differences are abstracted away, so your code remains consistent regardless of version.

## Migrating Between Versions

When migrating your application from v1.0 to v1.1.0, you have several options:

### Option 1: Direct Migration

Simply update the client initialization to use v1.1.0 (or remove the version parameter):

```python
# Before: v1.0
client = CloudConnexaClient(
    # ... auth credentials ...
    api_version="1.0"
)

# After: v1.1.0
client = CloudConnexaClient(
    # ... auth credentials ...
    # No version specified defaults to latest (1.1.0)
)
```

### Option 2: Gradual Migration with Feature Detection

You can detect which features are supported by the configured version:

```python
import cloudconnexa
from cloudconnexa import CloudConnexaClient

def get_dns_record(client, record_id):
    """Get DNS record with version-aware implementation."""
    try:
        # Try to use the v1.1.0 approach
        return client.dns.get(record_id)
    except cloudconnexa.FeatureNotSupportedError:
        # Fall back to v1.0 approach if needed
        records = client.dns.list(record_id=record_id)
        return next((r for r in records if r.id == record_id), None)
```

### Option 3: Version-Specific Code Paths

For more complex scenarios, you can check the client version and use specific code paths:

```python
def handle_ip_service(client, service_data):
    """Handle IP service data with version-specific logic."""
    if client.api_version == "1.0":
        # v1.0 specific handling (includes routing)
        routing = service_data.get("routing", {})
        network = routing.get("network")
        gateway = routing.get("gateway")
        print(f"Service uses routing: network={network}, gateway={gateway}")
    else:
        # v1.1.0 handling (no routing data)
        print("Service routing managed separately in v1.1.0")
```

## Handling Version-Specific Response Formats

The client automatically translates responses to consistent model formats through adapters:

```python
# This works with both v1.0 and v1.1.0
networks = client.networks.list()

# Model properties are consistent regardless of API version
for network in networks:
    print(f"Network: {network.name} ({network.cidr})")
    
    # If you need to access version-specific data that might not be present
    if hasattr(network, "some_new_v110_property"):
        print(f"New property: {network.some_new_v110_property}")
```

## Testing with Multiple Versions

When testing your application, you should verify behavior with both versions:

```python
import pytest
from cloudconnexa import CloudConnexaClient

@pytest.fixture
def v1_0_client():
    return CloudConnexaClient(
        # ... test credentials ...
        api_version="1.0"
    )

@pytest.fixture
def v1_1_0_client():
    return CloudConnexaClient(
        # ... test credentials ...
        api_version="1.1.0"
    )

def test_application_with_both_versions(v1_0_client, v1_1_0_client):
    """Test application behavior with both client versions."""
    # Test with v1.0
    result_v1 = my_application_function(v1_0_client)
    assert result_v1 is not None
    
    # Test with v1.1.0
    result_v110 = my_application_function(v1_1_0_client)
    assert result_v110 is not None
    
    # Results should be equivalent regardless of version
    assert result_v1 == result_v110
```

## Best Practices for Version Management

1. **Default to Latest**
   - Use the latest version by default for new code
   - Specify explicit versions only when needed

2. **Version Consistency**
   - Use the same version throughout your application
   - Avoid mixing different client versions

3. **Gradual Migration**
   - Test thoroughly when upgrading versions
   - Consider a phased migration for critical applications

4. **Feature Detection**
   - Use feature detection over version checking when possible
   - Handle unsupported features gracefully

5. **Monitor Version Deprecation**
   - Stay informed about API version deprecation timelines
   - Plan migrations well in advance

## Complete Migration Example

Here's a complete example of migrating an application from v1.0 to v1.1.0:

```python
import os
import logging
from cloudconnexa import CloudConnexaClient, FeatureNotSupportedError

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class NetworkManager:
    """Example application class that works with both v1.0 and v1.1.0."""
    
    def __init__(self, api_version=None):
        """Initialize with specific API version if needed."""
        self.client = CloudConnexaClient(
            api_url=os.getenv("CLOUDCONNEXA_API_URL"),
            client_id=os.getenv("CLOUDCONNEXA_CLIENT_ID"),
            client_secret=os.getenv("CLOUDCONNEXA_CLIENT_SECRET"),
            api_version=api_version
        )
        logger.info(f"Using API version: {self.client.api_version}")
        
    def get_dns_record(self, record_id):
        """Get a DNS record, handling version differences."""
        try:
            # Attempt to use v1.1.0 endpoint
            return self.client.dns.get(record_id)
        except FeatureNotSupportedError:
            logger.warning(
                "Single DNS record endpoint not available, falling back to list and filter"
            )
            records = self.client.dns.list(record_id=record_id)
            return next((r for r in records if r.id == record_id), None)
            
    def get_user_group(self, group_id):
        """Get a user group, handling version differences."""
        try:
            # Attempt to use v1.1.0 endpoint
            return self.client.user_groups.get(group_id)
        except FeatureNotSupportedError:
            logger.warning(
                "Single user group endpoint not available, falling back to list and filter"
            )
            groups = self.client.user_groups.list(group_id=group_id)
            return next((g for g in groups if g.id == group_id), None)
            
    def create_ip_service(self, name, host_id, **kwargs):
        """Create IP service, handling version differences."""
        if self.client.api_version == "1.0":
            # v1.0 required routing information
            if "routing" not in kwargs:
                logger.warning("Adding default routing for v1.0 API")
                kwargs["routing"] = {
                    "network": "192.168.1.0/24",
                    "gateway": "192.168.1.1"
                }
        elif self.client.api_version == "1.1.0":
            # v1.1.0 doesn't use routing
            if "routing" in kwargs:
                logger.warning("Removing routing information for v1.1.0 API")
                kwargs.pop("routing")
                
        return self.client.ip_services.create(
            name=name,
            host_id=host_id,
            **kwargs
        )

# Example usage with v1.0
manager_v1 = NetworkManager(api_version="1.0")
dns_v1 = manager_v1.get_dns_record("record_123")
group_v1 = manager_v1.get_user_group("group_123")
service_v1 = manager_v1.create_ip_service("service-name", "host_123")

# Example usage with v1.1.0 (default)
manager_v110 = NetworkManager()  # Defaults to latest
dns_v110 = manager_v110.get_dns_record("record_123")
group_v110 = manager_v110.get_user_group("group_123")
service_v110 = manager_v110.create_ip_service("service-name", "host_123")

# Migrate by updating version or removing version parameter
manager_v1 = NetworkManager(api_version="1.0")
# Later, migrate to v1.1.0:
manager_v1 = NetworkManager()  # Defaults to v1.1.0
```

## Version Compatibility Matrix

| Feature | v1.0 | v1.1.0 | Notes |
|---------|------|--------|-------|
| Authentication | ✅ | ✅ | Same in both versions |
| Network CRUD | ✅ | ✅ | Same in both versions |
| User CRUD | ✅ | ✅ | Same in both versions |
| Connector CRUD | ✅ | ✅ | Same in both versions |
| Route CRUD | ✅ | ✅ | Same in both versions |
| VPN Region List | ✅ | ✅ | Same in both versions |
| DNS Record List | ✅ | ✅ | Same in both versions |
| DNS Record Get | ⚠️ | ✅ | v1.0: List and filter<br>v1.1.0: Direct endpoint |
| User Group List | ✅ | ✅ | Same in both versions |
| User Group Get | ⚠️ | ✅ | v1.0: List and filter<br>v1.1.0: Direct endpoint |
| IP Service CRUD | ✅ | ✅ | v1.0: Includes routing<br>v1.1.0: No routing | 