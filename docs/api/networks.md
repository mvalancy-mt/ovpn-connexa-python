# Network Management

The Cloud Connexa Python client provides comprehensive network management capabilities. This document explains how to work with networks.

## Quick Start

```python
from cloudconnexa import CloudConnexaClient

# Initialize client
client = CloudConnexaClient(
    api_url="https://your-cloud-id.api.openvpn.com",
    client_id="your-client-id",
    client_secret="your-client-secret"
)

# List networks
networks = client.networks.list()

# Create network
network = client.networks.create(
    name="My Network",
    description="Network description"
)
```

## Network Model

```python
@dataclass
class Network:
    id: str
    name: str
    description: Optional[str] = None
    internet_access: str = "split_tunnel_on"
    egress: bool = True
    created_at: Optional[datetime] = None
    updated_at: Optional[datetime] = None
    status: str = "active"
    vpn_region: Optional[str] = None
    dns_servers: List[str] = None
    routes: List[Dict[str, Any]] = None
    connectors: List[Dict[str, Any]] = None
```

## Operations

### List Networks

```python
# List all networks
networks = client.networks.list()

# Access network properties
for network in networks:
    print(f"Network: {network.name}")
    print(f"Status: {network.status}")
    print(f"Created: {network.created_at}")
```

### Create Network

```python
# Create a new network
network = client.networks.create(
    name="My Network",
    description="Network description",
    internet_access="split_tunnel_on",
    egress=True,
    vpn_region="us-west"
)
```

### Get Network

```python
# Get a specific network
network = client.networks.get(network_id="net_123")
```

### Update Network

```python
# Update network properties
network = client.networks.update(
    network_id="net_123",
    name="New Name",
    description="Updated description"
)
```

### Delete Network

```python
# Delete a network
client.networks.delete(network_id="net_123")
```

## Error Handling

```python
try:
    network = client.networks.get(network_id="net_123")
except ResourceNotFoundError:
    print("Network not found")
except APIError as e:
    print(f"API error: {e}")
```

## Best Practices

1. **Network Creation**
   - Use descriptive names
   - Set appropriate internet access
   - Configure DNS servers
   - Set up routes

2. **Network Updates**
   - Update one property at a time
   - Verify changes
   - Handle errors gracefully

3. **Network Deletion**
   - Check for dependencies
   - Backup configuration
   - Handle cleanup

## API Reference

### NetworkService

```python
class NetworkService:
    def list(self) -> List[Network]:
        """List all networks."""
        
    def get(self, network_id: str) -> Network:
        """Get a specific network."""
        
    def create(self, name: str, description: Optional[str] = None,
               internet_access: str = "split_tunnel_on", egress: bool = True,
               vpn_region: Optional[str] = None) -> Network:
        """Create a new network."""
        
    def update(self, network_id: str, **kwargs) -> Network:
        """Update a network."""
        
    def delete(self, network_id: str) -> bool:
        """Delete a network."""
```

## Related Documentation

- [Authentication](authentication.md) - Authentication guide
- [Error Handling](error_handling.md) - Error handling guide
- [Examples](../examples/networks.md) - Network examples
