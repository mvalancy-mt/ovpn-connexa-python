# Error Handling

The Cloud Connexa Python client provides comprehensive error handling capabilities. This document explains how to handle various types of errors that may occur when using the client.

## Error Types

The client defines several custom exception classes:

```python
class CloudConnexaError(Exception):
    """Base exception for all Cloud Connexa errors."""
    pass

class APIError(CloudConnexaError):
    """Raised when the API returns an error."""
    def __init__(self, message: str, status_code: int, response: Optional[Dict] = None):
        self.message = message
        self.status_code = status_code
        self.response = response
        super().__init__(f"{message} (Status: {status_code})")

class AuthenticationError(APIError):
    """Raised when authentication fails."""
    pass

class ResourceNotFoundError(APIError):
    """Raised when a requested resource is not found."""
    pass

class ValidationError(APIError):
    """Raised when request validation fails."""
    pass

class RateLimitError(APIError):
    """Raised when rate limit is exceeded."""
    pass
```

## Basic Error Handling

```python
from cloudconnexa import CloudConnexaClient, APIError, ResourceNotFoundError

client = CloudConnexaClient(...)

try:
    network = client.networks.get(network_id="net_123")
except ResourceNotFoundError:
    print("Network not found")
except APIError as e:
    print(f"API error: {e}")
    print(f"Status code: {e.status_code}")
    if e.response:
        print(f"Response: {e.response}")
```

## Authentication Errors

```python
try:
    client = CloudConnexaClient(
        api_url="https://invalid.api.openvpn.com",
        client_id="invalid",
        client_secret="invalid"
    )
    client.authenticate()
except AuthenticationError as e:
    print(f"Authentication failed: {e}")
```

## Validation Errors

```python
try:
    network = client.networks.create(
        name="",  # Invalid empty name
        description="Network description"
    )
except ValidationError as e:
    print(f"Validation error: {e}")
    if e.response and "errors" in e.response:
        for field, errors in e.response["errors"].items():
            print(f"{field}: {errors}")
```

## Rate Limiting

```python
try:
    # Make multiple requests
    for i in range(100):
        client.networks.list()
except RateLimitError as e:
    print(f"Rate limit exceeded: {e}")
    # Wait and retry
    time.sleep(60)
```

## Best Practices

1. **Always Use Try-Except**
   ```python
   try:
       result = client.some_operation()
   except APIError as e:
       # Handle error
   ```

2. **Handle Specific Errors**
   ```python
   try:
       network = client.networks.get(network_id="net_123")
   except ResourceNotFoundError:
       # Handle not found
   except ValidationError:
       # Handle validation
   except RateLimitError:
       # Handle rate limit
   except APIError:
       # Handle other API errors
   ```

3. **Log Errors**
   ```python
   import logging

   try:
       result = client.some_operation()
   except APIError as e:
       logging.error(f"API error: {e}", exc_info=True)
   ```

4. **Retry Logic**
   ```python
   from tenacity import retry, stop_after_attempt, wait_exponential

   @retry(stop=stop_after_attempt(3), wait=wait_exponential(multiplier=1, min=4, max=10))
   def get_network_with_retry(client, network_id):
       return client.networks.get(network_id=network_id)
   ```

## Error Response Format

API errors typically return a response in this format:

```json
{
    "error": {
        "code": "error_code",
        "message": "Error message",
        "details": {
            "field": ["error message"]
        }
    }
}
```

## Related Documentation

- [Authentication](authentication.md) - Authentication guide
- [Networks](networks.md) - Network management guide
- [Examples](../examples/error_handling.md) - Error handling examples 