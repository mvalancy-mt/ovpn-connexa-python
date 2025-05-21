"""
Cloud Connexa Python Client

A Python client for the Cloud Connexa API, providing a simple and intuitive interface 
for managing Cloud Connexa resources.
"""

# Import from the client package
from .client import CloudConnexaClient
from .exceptions import (
    CloudConnexaError,
    APIError,
    AuthenticationError,
    ResourceNotFoundError,
    ValidationError,
    RateLimitError
)

__version__ = "0.1.0"
__all__ = [
    "CloudConnexaClient",
    "CloudConnexaError",
    "APIError",
    "AuthenticationError",
    "ResourceNotFoundError",
    "ValidationError",
    "RateLimitError"
]
