"""
CloudConnexa Client Module

This module contains the main client class for interacting with the Cloud Connexa API.
"""

import os
import requests
from dotenv import load_dotenv

from cloudconnexa.client.auth import Authenticator
from cloudconnexa.utils.errors import ConfigurationError

# Load environment variables from .env if present
load_dotenv()

class CloudConnexaClient:
    """
    CloudConnexa API client.
    
    This client provides a Python interface to the Cloud Connexa API, allowing you 
    to manage networks, users, connectors, routes, and other resources.
    """
    
    def __init__(self, api_url=None, client_id=None, client_secret=None, api_version="1.1.0"):
        """
        Initialize the CloudConnexa client.
        
        Args:
            api_url (str): The base URL for the Cloud Connexa API
            client_id (str): Client ID for API authentication
            client_secret (str): Client secret for API authentication
            api_version (str, optional): API version to use. Defaults to "1.1.0".
            
        Raises:
            ConfigurationError: If required parameters are missing
        """
        # Use environment variables if arguments are not provided
        api_url = api_url or os.getenv("CLOUDCONNEXA_API_URL")
        client_id = client_id or os.getenv("CLOUDCONNEXA_CLIENT_ID")
        client_secret = client_secret or os.getenv("CLOUDCONNEXA_CLIENT_SECRET")
        
        # Validate required parameters
        if not api_url:
            raise ConfigurationError("API URL is required (set CLOUDCONNEXA_API_URL or pass as argument)")
        if not client_id or not client_secret:
            raise ConfigurationError("Client ID and Client Secret are required (set CLOUDCONNEXA_CLIENT_ID and CLOUDCONNEXA_CLIENT_SECRET or pass as arguments)")
            
        self.api_url = api_url
        self.client_id = client_id
        self.client_secret = client_secret
        self.api_version = api_version
        
        # Initialize session and authenticator
        self.session = requests.Session()
        self._auth = Authenticator(api_url, client_id, client_secret, self.session)
        
        # These will be initialized lazily
        self._networks = None
        self._users = None
        self._user_groups = None
        self._connectors = None
        self._routes = None
        self._profiles = None
        self._audit_logs = None
        self._connections = None
    
    def authenticate(self):
        """
        Authenticate with the Cloud Connexa API and get an access token.
        
        Returns:
            bool: True if authentication was successful, False otherwise.
        """
        try:
            self._auth.ensure_authenticated()
            return True
        except Exception as e:
            return False
    
    @property
    def networks(self):
        """
        Get the networks service.
        
        Returns:
            NetworkService: The networks service.
        """
        # This is a stub that will be implemented later
        return None
    
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
