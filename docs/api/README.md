# Cloud Connexa API Reference

This directory contains the official API reference documentation for the Cloud Connexa Python client.

## Core Concepts

- [Authentication](authentication.md) - OAuth2 authentication and token management
- [Networks](networks.md) - Network management and configuration
- [Users](users.md) - User management and access control
- [Connectors](connectors.md) - VPN connector management
- [Routes](routes.md) - Network routing configuration

## API Versioning

The client supports both v1.0 and v1.1.0 of the Cloud Connexa API. See [Version Compatibility](version_compatibility.md) for details.

## Quick Start

```python
from cloudconnexa import CloudConnexaClient

# Initialize client
client = CloudConnexaClient(
    api_url="https://your-cloud-id.api.openvpn.com",
    client_id="your-client-id",
    client_secret="your-client-secret"
)

# Authenticate
client.authenticate()

# List networks
networks = client.networks.list()
```

## Authentication

The client uses OAuth2 for authentication. See [Authentication](authentication.md) for details.

## Error Handling

All API methods raise appropriate exceptions. See [Error Handling](error_handling.md) for details.

## Rate Limiting

The API implements rate limiting. See [Rate Limiting](rate_limiting.md) for details.

## Best Practices

- Always handle authentication errors
- Implement proper error handling
- Use appropriate timeouts
- Handle rate limiting
- Cache tokens appropriately

## API Reference

### Networks

```python
# List networks
networks = client.networks.list()

# Create network
network = client.networks.create(
    name="My Network",
    description="Network description"
)

# Get network
network = client.networks.get(network_id="net_123")

# Update network
network = client.networks.update(
    network_id="net_123",
    name="New Name"
)

# Delete network
client.networks.delete(network_id="net_123")
```

### Users

```python
# List users
users = client.users.list()

# Create user
user = client.users.create(
    email="user@example.com",
    name="User Name"
)

# Get user
user = client.users.get(user_id="user_123")

# Update user
user = client.users.update(
    user_id="user_123",
    name="New Name"
)

# Delete user
client.users.delete(user_id="user_123")
```

## Related Documentation

- [Examples](../examples/README.md) - Practical usage examples
- [Testing](../testing/README.md) - Testing strategies
- [Planning](../planning/README.md) - Project planning 