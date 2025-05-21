"""
User service implementation.

This module provides the UserService class for managing users through the CloudConnexa API.
"""

import logging
from typing import Any, Dict, List, Optional
from datetime import datetime

from cloudconnexa.utils.errors import (
    APIError,
    ResourceNotFoundError,
    ValidationError,
    RateLimitError
)

logger = logging.getLogger(__name__)

def parse_datetime(value):
    """Parse datetime string to datetime object."""
    if isinstance(value, str):
        try:
            # Handle Zulu time
            if value.endswith('Z'):
                value = value[:-1] + '+00:00'
            return datetime.fromisoformat(value)
        except Exception:
            return value
    return value

class User:
    """Represents a Cloud Connexa user.
    
    Attributes:
        id (str): User identifier
        email (str): User email
        first_name (str): User's first name
        last_name (str): User's last name
        role (str): User's role
        status (str): Current user status
        created_at (datetime): Creation timestamp
        updated_at (datetime): Last update timestamp
    """
    def __init__(self, **kwargs):
        for k, v in kwargs.items():
            if k in ("created_at", "updated_at"):
                setattr(self, k, parse_datetime(v))
            else:
                setattr(self, k, v)

class UserService:
    """Service for managing users.
    
    This service handles all user operations including creation,
    retrieval, updates, and deletion.
    """
    def __init__(self, client):
        """Initialize the user service.
        
        Args:
            client: CloudConnexaClient instance
        """
        self.client = client

    def _default_pagination(self, total: int = 0, per_page: int = 0) -> Dict[str, Any]:
        """Create default pagination object.
        
        Args:
            total: Total number of items
            per_page: Items per page
            
        Returns:
            dict: Pagination object
        """
        return {"total": total, "page": 1, "per_page": per_page, "has_more": False}

    def list(self, **kwargs) -> Dict[str, Any]:
        """List users with optional filtering.
        
        Args:
            **kwargs: Filter parameters
            
        Returns:
            dict: Dictionary containing users and pagination info
            
        Raises:
            APIError: If user listing fails
            RateLimitError: If rate limit is exceeded
        """
        try:
            response = self.client._session.get(
                f"{self.client.api_url}/api/v{self.client.api_version}/users",
                params=kwargs
            )
            if response.status_code == 429:
                raise RateLimitError("Rate limit exceeded", response=response)
            if response.status_code != 200:
                raise APIError(f"Failed to list users: {response.status_code}", response=response)
                
            data = response.json()
            # Always return a dict with 'data' and 'pagination' keys
            if isinstance(data, list):
                total = len(data)
                return {
                    "data": [User(**item) for item in data],
                    "pagination": self._default_pagination(total, total)
                }
            if isinstance(data, dict):
                users = [User(**item) for item in data.get("data", [])]
                pagination = data.get("pagination", {})
                # Fill in missing pagination keys with defaults
                default_pagination = self._default_pagination(len(users), len(users))
                for key, value in default_pagination.items():
                    pagination.setdefault(key, value)
                return {"data": users, "pagination": pagination}
            return {"data": [], "pagination": self._default_pagination(0, 0)}
        except Exception as e:
            logger.error(f"Error listing users: {e}")
            raise

    def create(self, **kwargs) -> User:
        """Create a new user.
        
        Args:
            **kwargs: User data
            
        Returns:
            User: Created user
            
        Raises:
            ValidationError: If user data is invalid
            APIError: If user creation fails
        """
        if not kwargs.get("email"):
            raise ValidationError("Email cannot be empty")
            
        response = self.client._session.post(
            f"{self.client.api_url}/api/v{self.client.api_version}/users",
            json=kwargs
        )
        if response.status_code == 400:
            raise ValidationError("Validation failed", response=response)
        if response.status_code != 201:
            raise APIError(f"Failed to create user: {response.status_code}", response=response)
        return User(**response.json())

    def get(self, user_id: str) -> User:
        """Get user by ID.
        
        Args:
            user_id: User identifier
            
        Returns:
            User: Retrieved user
            
        Raises:
            ResourceNotFoundError: If user is not found
            APIError: If user retrieval fails
        """
        response = self.client._session.get(
            f"{self.client.api_url}/api/v{self.client.api_version}/users/{user_id}"
        )
        if response.status_code == 404:
            raise ResourceNotFoundError("User not found", resource_id=user_id, response=response)
        if response.status_code != 200:
            raise APIError(f"Failed to get user: {response.status_code}", response=response)
        return User(**response.json())

    def update(self, user_id: str, **kwargs) -> User:
        """Update user.
        
        Args:
            user_id: User identifier
            **kwargs: User data to update
            
        Returns:
            User: Updated user
            
        Raises:
            ResourceNotFoundError: If user is not found
            ValidationError: If update data is invalid
            APIError: If user update fails
        """
        response = self.client._session.patch(
            f"{self.client.api_url}/api/v{self.client.api_version}/users/{user_id}",
            json=kwargs
        )
        if response.status_code == 404:
            raise ResourceNotFoundError("User not found", resource_id=user_id, response=response)
        if response.status_code == 400:
            raise ValidationError("Validation failed", response=response)
        if response.status_code != 200:
            raise APIError(f"Failed to update user: {response.status_code}", response=response)
        return User(**response.json())

    def delete(self, user_id: str) -> bool:
        """Delete user.
        
        Args:
            user_id: User identifier
            
        Returns:
            bool: True if deletion was successful
            
        Raises:
            ResourceNotFoundError: If user is not found
            APIError: If user deletion fails
            RateLimitError: If rate limit is exceeded
        """
        response = self.client._session.delete(
            f"{self.client.api_url}/api/v{self.client.api_version}/users/{user_id}"
        )
        if response.status_code == 404:
            raise ResourceNotFoundError("User not found", resource_id=user_id, response=response)
        if response.status_code == 204:
            return True
        if response.status_code == 429:
            raise RateLimitError("Rate limit exceeded", response=response)
        if response.status_code >= 400:
            raise APIError(f"Failed to delete user: {response.status_code}", response=response)
        return False 