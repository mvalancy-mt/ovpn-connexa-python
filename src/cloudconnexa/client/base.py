"""
Base client for Cloud Connexa API.

This module provides the main client interface for interacting with the
Cloud Connexa API, with automatic version detection and compatibility.
"""

import logging
import os
from typing import Dict, Optional, Union

import requests

from cloudconnexa.client.auth import Authenticator
from cloudconnexa.client.version_detector import get_api_version
from cloudconnexa.utils.errors import APIError, ConfigurationError

logger = logging.getLogger(__name__)


class CloudConnexaClient:
    """Main client for the Cloud Connexa API.
    
    This client provides access to all API services and handles authentication,
    version detection, and compatibility between API versions.
    
    Attributes:
        api_url (str): The base URL for the API
        api_version (str): The detected or specified API version
    """
    
    def __init__(
        self,
        api_url: str,
        client_id: str,
        client_secret: str,
        api_version: Optional[str] = None
    ):
        """Initialize the Cloud Connexa client.
        
        Args:
            api_url: Base URL for the API
            client_id: Client ID for authentication
            client_secret: Client secret for authentication
            api_version: Optional explicit API version to use
        
        Raises:
            ConfigurationError: If required parameters are missing
        """
        # Validate required parameters
        if not api_url:
            raise ConfigurationError("API URL is required")
        if not client_id or not client_secret:
            raise ConfigurationError("Client ID and Client Secret are required")
            
        # Initialize properties
        self.api_url = api_url
        self.session = requests.Session()
        
        # Set up authentication
        self._auth = Authenticator(api_url, client_id, client_secret, self.session)
        
        # Detect API version (or use specified version)
        self.api_version = api_version or os.getenv("CLOUDCONNEXA_API_VERSION") or get_api_version(api_url, api_version, self.session)
        logger.info(f"Using API version: {self.api_version}")
        
        # Initialize service instances
        self._services: Dict[str, object] = {}
        
    @property
    def dns(self):
        """DNS record service.
        
        Returns:
            DNSService: The DNS record service
        """
        if "dns" not in self._services:
            from cloudconnexa.services.dns.service import DNSService
            self._services["dns"] = DNSService(self)
        return self._services["dns"]
        
    @property
    def user_groups(self):
        """User group service.
        
        Returns:
            UserGroupService: The user group service
        """
        if "user_groups" not in self._services:
            from cloudconnexa.services.user_groups.service import UserGroupService
            self._services["user_groups"] = UserGroupService(self)
        return self._services["user_groups"]
        
    @property
    def ip_services(self):
        """IP service management.
        
        Returns:
            IPServiceService: The IP service management service
        """
        if "ip_services" not in self._services:
            from cloudconnexa.services.ip_services.service import IPServiceService
            self._services["ip_services"] = IPServiceService(self)
        return self._services["ip_services"]
    
    # HTTP request methods
    def get(self, path: str, **kwargs) -> dict:
        """Make a GET request to the API.
        
        Args:
            path: API path
            **kwargs: Additional arguments for requests
            
        Returns:
            dict: Response data
            
        Raises:
            APIError: If the request fails
        """
        return self._request("GET", path, **kwargs)
        
    def post(self, path: str, **kwargs) -> dict:
        """Make a POST request to the API.
        
        Args:
            path: API path
            **kwargs: Additional arguments for requests
            
        Returns:
            dict: Response data
            
        Raises:
            APIError: If the request fails
        """
        return self._request("POST", path, **kwargs)
        
    def put(self, path: str, **kwargs) -> dict:
        """Make a PUT request to the API.
        
        Args:
            path: API path
            **kwargs: Additional arguments for requests
            
        Returns:
            dict: Response data
            
        Raises:
            APIError: If the request fails
        """
        return self._request("PUT", path, **kwargs)
        
    def delete(self, path: str, **kwargs) -> dict:
        """Make a DELETE request to the API.
        
        Args:
            path: API path
            **kwargs: Additional arguments for requests
            
        Returns:
            dict: Response data
            
        Raises:
            APIError: If the request fails
        """
        return self._request("DELETE", path, **kwargs)
    
    def _request(self, method: str, path: str, **kwargs) -> dict:
        """Make a request to the API.
        
        Args:
            method: HTTP method
            path: API path
            **kwargs: Additional arguments for requests
            
        Returns:
            dict: Response data
            
        Raises:
            APIError: If the request fails
        """
        # Ensure authentication token is valid
        self._auth.ensure_authenticated()
        
        # Construct URL
        url = f"{self.api_url.rstrip('/')}{path}"
        
        # Add authentication header
        headers = kwargs.pop("headers", {})
        headers["Authorization"] = f"Bearer {self._auth.token}"
        
        try:
            # Make the request
            response = self.session.request(method, url, headers=headers, **kwargs)
            
            # Check for errors
            if response.status_code >= 400:
                raise APIError(
                    f"API request failed with status {response.status_code}",
                    status_code=response.status_code,
                    response=response
                )
                
            # Return response data
            return response.json() if response.content else {}
            
        except requests.RequestException as e:
            # Wrap request exceptions
            raise APIError(f"API request failed: {str(e)}", original_error=e)
