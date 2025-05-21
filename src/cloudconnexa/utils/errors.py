"""
Error classes for the Cloud Connexa client.

This module provides exception classes used throughout the client.
"""

from typing import Any, Dict, Optional


class CloudConnexaError(Exception):
    """Base exception for all Cloud Connexa errors."""
    
    def __init__(self, message: str, **kwargs):
        """Initialize the error.
        
        Args:
            message: Error message
            **kwargs: Additional error context
        """
        super().__init__(message)
        self.message = message
        self.context = kwargs


class ConfigurationError(CloudConnexaError):
    """Error raised when there is a configuration issue."""
    pass


class AuthenticationError(CloudConnexaError):
    """Error raised when authentication fails."""
    
    def __init__(self, message: str, status_code: Optional[int] = None, **kwargs):
        """Initialize the authentication error.
        
        Args:
            message: Error message
            status_code: HTTP status code
            **kwargs: Additional error context
        """
        super().__init__(message, status_code=status_code, **kwargs)
        self.status_code = status_code


class APIError(CloudConnexaError):
    """Error raised when an API request fails."""
    
    def __init__(
        self, 
        message: str, 
        status_code: Optional[int] = None,
        response: Optional[Any] = None,
        original_error: Optional[Exception] = None,
        **kwargs
    ):
        """Initialize the API error.
        
        Args:
            message: Error message
            status_code: HTTP status code
            response: Response object
            original_error: Original exception
            **kwargs: Additional error context
        """
        super().__init__(
            message, 
            status_code=status_code, 
            response=response, 
            original_error=original_error,
            **kwargs
        )
        self.status_code = status_code
        self.response = response
        self.original_error = original_error
        
    @property
    def response_json(self) -> Dict[str, Any]:
        """Get the response JSON if available.
        
        Returns:
            dict: Response JSON or empty dict
        """
        if self.response and hasattr(self.response, "json"):
            try:
                return self.response.json()
            except:
                pass
        return {}


class VersionCompatibilityError(CloudConnexaError):
    """Error raised when a feature is not supported in the current API version."""
    
    def __init__(self, message: str, feature: str, current_version: str, **kwargs):
        """Initialize the version compatibility error.
        
        Args:
            message: Error message
            feature: Unsupported feature
            current_version: Current API version
            **kwargs: Additional error context
        """
        super().__init__(
            message, 
            feature=feature,
            current_version=current_version,
            **kwargs
        )
        self.feature = feature
        self.current_version = current_version


class ResourceNotFoundError(APIError):
    """Error raised when a resource is not found."""
    
    def __init__(self, resource_type: str, resource_id: str, **kwargs):
        """Initialize the resource not found error.
        
        Args:
            resource_type: Type of resource
            resource_id: ID of resource
            **kwargs: Additional error context
        """
        message = f"{resource_type} with ID '{resource_id}' not found"
        super().__init__(message, status_code=404, **kwargs)
        self.resource_type = resource_type
        self.resource_id = resource_id
