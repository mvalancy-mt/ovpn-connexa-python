"""
Authentication handling for the Cloud Connexa client.

This module handles OAuth2 token acquisition and management.
"""

import logging
import time
from typing import Optional

import requests

from cloudconnexa.utils.errors import AuthenticationError

logger = logging.getLogger(__name__)

class Authenticator:
    """Handles OAuth2 authentication for the Cloud Connexa API.
    
    This class manages token acquisition, refresh, and validation.
    
    Args:
        api_url: Base URL for the API
        client_id: OAuth2 client ID
        client_secret: OAuth2 client secret
        session: Requests session to use
    """
    
    def __init__(self, api_url: str, client_id: str, client_secret: str, session: requests.Session):
        """Initialize the authenticator."""
        self.api_url = api_url
        self.client_id = client_id
        self.client_secret = client_secret
        self.session = session
        self._token: Optional[str] = None
        self._token_expiry: Optional[float] = None
        
    @property
    def token(self) -> Optional[str]:
        """Get the current access token.
        
        Returns:
            str: The access token if available
        """
        return self._token
        
    def ensure_authenticated(self) -> None:
        """Ensure we have a valid authentication token.
        
        This will acquire a new token if needed or refresh an existing one.
        
        Raises:
            AuthenticationError: If authentication fails
        """
        # If we have a valid token, no need to do anything
        if self._is_token_valid():
            return
            
        # Try to refresh the token if we have one
        if self._token and self._refresh_token():
            return
            
        # Otherwise, get a new token
        self._acquire_token()
        
    def _is_token_valid(self) -> bool:
        """Check if the current token is valid.
        
        Returns:
            bool: True if the token is valid and not expired
        """
        if not self._token or not self._token_expiry:
            return False
            
        # Add a 30-second buffer to prevent edge cases
        return time.time() < (self._token_expiry - 30)
        
    def _acquire_token(self) -> None:
        """Acquire a new OAuth2 token.
        
        Raises:
            AuthenticationError: If token acquisition fails
        """
        try:
            # Make token request
            response = self.session.post(
                f"{self.api_url}/oauth2/token",
                data={
                    "grant_type": "client_credentials",
                    "client_id": self.client_id,
                    "client_secret": self.client_secret
                }
            )
            
            # Check for errors
            if response.status_code != 200:
                raise AuthenticationError(
                    f"Failed to acquire token: {response.status_code}",
                    status_code=response.status_code,
                    response=response
                )
                
            # Parse response
            data = response.json()
            self._token = data["access_token"]
            self._token_expiry = time.time() + data["expires_in"]
            
            logger.info("Successfully acquired new access token")
            
        except requests.RequestException as e:
            raise AuthenticationError(f"Failed to acquire token: {str(e)}", original_error=e)
            
    def _refresh_token(self) -> bool:
        """Attempt to refresh the current token.
        
        Returns:
            bool: True if refresh was successful
        """
        try:
            # Make refresh request
            response = self.session.post(
                f"{self.api_url}/oauth2/token",
                data={
                    "grant_type": "refresh_token",
                    "client_id": self.client_id,
                    "client_secret": self.client_secret,
                    "refresh_token": self._token
                }
            )
            
            # Check for errors
            if response.status_code != 200:
                logger.warning(f"Token refresh failed: {response.status_code}")
                return False
                
            # Parse response
            data = response.json()
            self._token = data["access_token"]
            self._token_expiry = time.time() + data["expires_in"]
            
            logger.info("Successfully refreshed access token")
            return True
            
        except requests.RequestException as e:
            logger.warning(f"Token refresh failed: {str(e)}")
            return False
