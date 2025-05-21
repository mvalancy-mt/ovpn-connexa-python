# Authentication

The Cloud Connexa Python client uses OAuth2 for authentication. This document explains how to authenticate and manage tokens.

## Quick Start

```python
from cloudconnexa import CloudConnexaClient

# Initialize client with credentials
client = CloudConnexaClient(
    api_url="https://your-cloud-id.api.openvpn.com",
    client_id="your-client-id",
    client_secret="your-client-secret"
)

# Authenticate
client.authenticate()
```

## Environment Variables

You can also provide credentials through environment variables:

```bash
CLOUDCONNEXA_API_URL=https://your-cloud-id.api.openvpn.com
CLOUDCONNEXA_CLIENT_ID=your-client-id
CLOUDCONNEXA_CLIENT_SECRET=your-client-secret
```

## Token Management

The client automatically handles token management:

- Acquires tokens using client credentials
- Refreshes tokens before they expire
- Handles token errors gracefully

## Error Handling

```python
try:
    client.authenticate()
except AuthenticationError as e:
    print(f"Authentication failed: {e}")
    # Handle authentication error
```

## Best Practices

1. **Secure Storage**
   - Never commit credentials to version control
   - Use environment variables or secure configuration
   - Rotate credentials regularly

2. **Error Handling**
   - Always handle authentication errors
   - Implement proper retry logic
   - Log authentication failures

3. **Token Management**
   - Let the client handle token refresh
   - Don't store tokens manually
   - Monitor token expiration

## API Reference

### CloudConnexaClient

```python
class CloudConnexaClient:
    def __init__(self, api_url=None, client_id=None, client_secret=None, api_version="1.1.0"):
        """Initialize the client.
        
        Args:
            api_url: The base URL for the Cloud Connexa API
            client_id: OAuth2 client ID
            client_secret: OAuth2 client secret
            api_version: API version to use
        """
        
    def authenticate(self) -> bool:
        """Authenticate with the Cloud Connexa API.
        
        Returns:
            bool: True if authentication was successful
        """
```

## Related Documentation

- [Error Handling](error_handling.md) - Detailed error handling guide
- [Best Practices](../examples/best_practices.md) - Security best practices
- [Examples](../examples/authentication.md) - Authentication examples
