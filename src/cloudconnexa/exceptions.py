"""Custom exceptions for the Cloud Connexa client."""

class CloudConnexaError(Exception):
    """Base exception for all Cloud Connexa client errors."""
    def __init__(self, message: str, status_code: int = None):
        self.message = message
        self.status_code = status_code
        super().__init__(self.message)

class APIError(CloudConnexaError):
    """Raised when an API request fails."""
    pass

class AuthenticationError(CloudConnexaError):
    """Raised when authentication fails."""
    pass

class ResourceNotFoundError(CloudConnexaError):
    """Raised when a requested resource is not found."""
    pass

class ValidationError(CloudConnexaError):
    """Raised when input validation fails."""
    pass

class RateLimitError(CloudConnexaError):
    """Raised when API rate limit is exceeded."""
    pass 