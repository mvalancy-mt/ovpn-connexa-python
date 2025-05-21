# Development Setup Guide

This guide will help you set up the Cloud Connexa Python client for development, with special attention to version compatibility features.

## Prerequisites

- Python 3.7 or higher
- pip
- virtualenv or venv (recommended)
- git

## Initial Setup

1. Clone the repository:
```bash
git clone https://github.com/yourusername/ovpn-connexa.git
cd ovpn-connexa
```

2. Create and activate a virtual environment:
```bash
# Using venv (Python 3.3+)
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate

# Or using virtualenv
virtualenv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
```

3. Install the package in development mode with all dependencies:
```bash
pip install -e ".[dev]"
```

## Configuration for Version Compatibility Testing

To test against both v1.0 and v1.1.0 API versions, you'll need credentials for each. 

1. Create a `.env` file with your credentials (never commit this file):
```bash
# .env
CLOUDCONNEXA_API_URL=https://your-cloud-id.api.openvpn.com
CLOUDCONNEXA_CLIENT_ID=your-client-id
CLOUDCONNEXA_CLIENT_SECRET=your-client-secret
```

2. Set up environment variables for specific API versions (useful for testing):
```bash
# For v1.0 testing
export CLOUDCONNEXA_API_VERSION=1.0

# For v1.1.0 testing
export CLOUDCONNEXA_API_VERSION=1.1.0
```

## Running Tests

The test suite is designed to test compatibility across API versions:

### Running All Tests

```bash
pytest
```

### Testing Specific API Versions

```bash
# Test against v1.0
pytest --api-version=1.0

# Test against v1.1.0
pytest --api-version=1.1.0
```

### Testing Version Compatibility Features

```bash
# Test version detection
pytest tests/functional/test_version_detection.py

# Test DNS record compatibility
pytest tests/integration/test_dns_compatibility.py

# Test User Group compatibility
pytest tests/integration/test_user_group_compatibility.py

# Test IP Service compatibility
pytest tests/integration/test_ip_service_compatibility.py
```

## Development Workflow for Version Compatibility

When working on features that need to support both API versions:

1. **Implement the v1.1.0 version first** - This is the preferred API version.
2. **Add fallback for v1.0** - Ensure backward compatibility where needed.
3. **Add version detection** - Use the client's version detection mechanism.
4. **Test against both versions** - Verify functionality works with both API versions.

## Code Style and Standards

We use the following tools to maintain code quality:

- **Black** for code formatting:
  ```bash
  black src tests
  ```

- **isort** for import sorting:
  ```bash
  isort src tests
  ```

- **flake8** for linting:
  ```bash
  flake8 src tests
  ```

- **mypy** for type checking:
  ```bash
  mypy src
  ```

## Troubleshooting Version Compatibility Issues

If you encounter version compatibility issues:

1. Check the API version detection in `src/cloudconnexa/client/version_detector.py`
2. Examine version-specific adapter classes in service implementations
3. Review the test fixtures in `tests/conftest.py` for correct mock responses
4. Ensure all services have proper fallback mechanisms for v1.0

## Documentation for Version Compatibility

When documenting features, always specify any version-specific behavior:

```python
def get_dns_record(self, record_id: str) -> DNSRecord:
    """Get a DNS record by ID.
    
    In v1.1.0: Uses direct endpoint /dns/{record_id}
    In v1.0: Lists all records and filters by ID
    
    Args:
        record_id: The DNS record identifier
        
    Returns:
        DNSRecord: The requested DNS record
    """
```

## Need Help?

If you have any questions about development or version compatibility, check:

- [Migration Guide](../planning/migration_v1_to_v110.md)
- [Version Compatibility Tests](../testing/version_compatibility_tests.md)
- [API Versioning Examples](../examples/api_versioning.md)
