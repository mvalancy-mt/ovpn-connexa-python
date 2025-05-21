"""
Network service for Cloud Connexa API.

This module provides the NetworkService class for managing networks.
"""

from typing import List, Optional, Dict, Any
from ..models.network import Network
from ..utils.errors import APIError

class NetworkService:
    """Service for managing Cloud Connexa networks.
    
    This service provides methods for listing, creating, updating, and deleting networks.
    
    Args:
        client: The CloudConnexaClient instance
    """
    
    def __init__(self, client):
        """Initialize the NetworkService.
        
        Args:
            client: The CloudConnexaClient instance
        """
        self._client = client
        self._base_url = f"{client.api_url}/networks"
    
    def list(self) -> List[Network]:
        """List all networks.
        
        Returns:
            List[Network]: List of networks
            
        Raises:
            APIError: If the API request fails
        """
        response = self._client._session.get(self._base_url)
        if response.status_code != 200:
            raise APIError(f"Failed to list networks: {response.text}")
            
        data = response.json()
        return [Network.from_dict(network) for network in data]
    
    def get(self, network_id: str) -> Network:
        """Get a specific network.
        
        Args:
            network_id: The ID of the network to get
            
        Returns:
            Network: The requested network
            
        Raises:
            APIError: If the API request fails
        """
        response = self._client._session.get(f"{self._base_url}/{network_id}")
        if response.status_code != 200:
            raise APIError(f"Failed to get network {network_id}: {response.text}")
            
        return Network.from_dict(response.json())
    
    def create(self, name: str, description: Optional[str] = None, 
               internet_access: str = "split_tunnel_on", egress: bool = True,
               vpn_region: Optional[str] = None) -> Network:
        """Create a new network.
        
        Args:
            name: The name of the network
            description: Optional description of the network
            internet_access: Internet access configuration
            egress: Whether egress is enabled
            vpn_region: Optional VPN region
            
        Returns:
            Network: The created network
            
        Raises:
            APIError: If the API request fails
        """
        data = {
            "name": name,
            "description": description,
            "internet_access": internet_access,
            "egress": egress,
            "vpn_region": vpn_region
        }
        
        response = self._client._session.post(self._base_url, json=data)
        if response.status_code != 201:
            raise APIError(f"Failed to create network: {response.text}")
            
        return Network.from_dict(response.json())
    
    def update(self, network_id: str, **kwargs) -> Network:
        """Update a network.
        
        Args:
            network_id: The ID of the network to update
            **kwargs: Network attributes to update
            
        Returns:
            Network: The updated network
            
        Raises:
            APIError: If the API request fails
        """
        response = self._client._session.patch(f"{self._base_url}/{network_id}", json=kwargs)
        if response.status_code != 200:
            raise APIError(f"Failed to update network {network_id}: {response.text}")
            
        return Network.from_dict(response.json())
    
    def delete(self, network_id: str) -> bool:
        """Delete a network.
        
        Args:
            network_id: The ID of the network to delete
            
        Returns:
            bool: True if deletion was successful
            
        Raises:
            APIError: If the API request fails
        """
        response = self._client._session.delete(f"{self._base_url}/{network_id}")
        if response.status_code != 204:
            raise APIError(f"Failed to delete network {network_id}: {response.text}")
            
        return True 