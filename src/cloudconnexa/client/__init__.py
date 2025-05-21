"""
Cloud Connexa API Client.

This module provides the main client interface for interacting with the Cloud Connexa API.
"""

import os
import requests
from typing import Optional
from dotenv import load_dotenv
from ..utils.errors import ConfigurationError
from ..services.network import NetworkService
from .auth import Authenticator

class CloudConnexaClient:
    """Main client for interacting with Cloud Connexa API.
    
    This client handles authentication, request signing, and API communication.
    
    Args:
        api_url (str): The base URL for the Cloud Connexa API
        client_id (str): OAuth2 client ID
        client_secret (str): OAuth2 client secret
        api_version (str, optional): API version to use. Defaults to "1.1.0".
    
    Example:
        >>> client = CloudConnexaClient(
        ...     api_url="https://api.openvpn.com",
        ...     client_id="your_client_id",
        ...     client_secret="your_client_secret"
        ... )
    """
    
    def __init__(self, api_url: Optional[str] = None, client_id: Optional[str] = None,
                 client_secret: Optional[str] = None, api_version: str = "1.1.0"):
        """Initialize the Cloud Connexa client.
        
        Args:
            api_url: The base URL for the Cloud Connexa API
            client_id: OAuth2 client ID
            client_secret: OAuth2 client secret
            api_version: API version to use
        """
        # Load environment variables from .env file if it exists
        load_dotenv()
        
        # Get configuration from environment variables if not provided
        self.api_url = api_url or os.getenv('CLOUDCONNEXA_API_URL')
        self.client_id = client_id or os.getenv('CLOUDCONNEXA_CLIENT_ID')
        self.client_secret = client_secret or os.getenv('CLOUDCONNEXA_CLIENT_SECRET')
        self.api_version = api_version
        
        # Validate required parameters
        if not self.api_url:
            raise ConfigurationError("API URL is required")
        if not self.client_id:
            raise ConfigurationError("Client ID is required")
        if not self.client_secret:
            raise ConfigurationError("Client Secret is required")
        
        # Initialize session and authenticator
        self._session = requests.Session()
        self._auth = None
        self._networks = None
        
    @property
    def networks(self) -> NetworkService:
        """Get the networks service.
        
        Returns:
            NetworkService: The networks service
        """
        if self._networks is None:
            self._networks = NetworkService(self)
        return self._networks
    
    def authenticate(self) -> bool:
        """Authenticate with the Cloud Connexa API.
        
        Returns:
            bool: True if authentication was successful
        """
        if self._auth is None:
            self._auth = Authenticator(
                api_url=self.api_url,
                client_id=self.client_id,
                client_secret=self.client_secret,
                session=self._session
            )
        try:
            return self._auth.ensure_authenticated()
        except Exception:
            return False
    
    @property
    def users(self):
        """
        Get the users service.
        
        Returns:
            UserService: The users service.
        """
        # This is a stub that will be implemented later
        return None
    
    # Additional service properties will be added here
