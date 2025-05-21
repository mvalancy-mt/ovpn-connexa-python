"""
Network service for Cloud Connexa API.

This module provides the NetworkService class for managing networks.
"""

from typing import List, Optional, Dict, Any
from ..models.network import Network
from ..utils.errors import APIError, ResourceNotFoundError, ValidationError, RateLimitError

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
    
    def list(
        self,
        page: Optional[int] = None,
        per_page: Optional[int] = None,
        status: Optional[str] = None,
        name: Optional[str] = None,
        sort_by: Optional[str] = None,
        sort_order: Optional[str] = None
    ) -> Dict[str, Any]:
        """List all networks with optional filtering, sorting, and pagination.
        
        Args:
            page: Page number for pagination
            per_page: Number of items per page
            status: Filter by network status
            name: Filter by network name
            sort_by: Field to sort by
            sort_order: Sort order ('asc' or 'desc')
            
        Returns:
            Dict containing 'data' (List[Network]) and 'pagination' info
            
        Raises:
            APIError: If the API request fails
            RateLimitError: If rate limit is exceeded
        """
        params = {}
        if page is not None:
            params['page'] = page
        if per_page is not None:
            params['per_page'] = per_page
        if status:
            params['status'] = status
        if name:
            params['name'] = name
        if sort_by:
            params['sort_by'] = sort_by
        if sort_order:
            if sort_order not in ['asc', 'desc']:
                raise ValueError("sort_order must be 'asc' or 'desc'")
            params['sort_order'] = sort_order
            
        response = self._client._session.get(self._base_url, params=params)
        if response.status_code == 429:
            retry_after = response.headers.get('Retry-After')
            raise RateLimitError(
                "Rate limit exceeded",
                retry_after=int(retry_after) if retry_after else None,
                response=response
            )
        if response.status_code != 200:
            self._raise_api_error(response)
            
        data = response.json()
        
        # Handle both old and new response formats
        if isinstance(data, list):
            # Old format: direct list of networks
            return {
                'data': [Network.from_dict(network) for network in data],
                'pagination': {
                    'total': len(data),
                    'page': 1,
                    'per_page': len(data),
                    'has_more': False
                }
            }
        else:
            # New format: {data: [...], pagination: {...}}
            return {
                'data': [Network.from_dict(network) for network in data.get('data', [])],
                'pagination': data.get('pagination', {
                    'total': len(data.get('data', [])),
                    'page': 1,
                    'per_page': len(data.get('data', [])),
                    'has_more': False
                })
            }
    
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
            self._raise_api_error(response, resource_id=network_id)
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
            self._raise_api_error(response)
            
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
            self._raise_api_error(response, resource_id=network_id)
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
            self._raise_api_error(response, resource_id=network_id)
        return True

    def _raise_api_error(self, response, resource_id=None):
        try:
            error_json = response.json()
        except Exception:
            error_json = {}
        code = error_json.get("error", {}).get("code")
        message = error_json.get("error", {}).get("message", response.text)
        status = response.status_code
        if status == 404 or code == "not_found":
            raise ResourceNotFoundError("Network", resource_id or "unknown")
        if status == 400 or code == "validation_error":
            raise ValidationError(message, status_code=status)
        raise APIError(f"API error: {message}", status_code=status, response=response) 