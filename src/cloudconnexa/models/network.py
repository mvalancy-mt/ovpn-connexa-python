"""
Network model for Cloud Connexa API.

This module defines the Network class to represent networks in CloudConnexa.
"""

from dataclasses import dataclass
from typing import Optional, List, Dict, Any
from datetime import datetime

@dataclass
class Network:
    """Represents a Cloud Connexa network.
    
    Attributes:
        id (str): The unique identifier for the network
        name (str): The name of the network
        description (Optional[str]): A description of the network
        internet_access (str): The internet access configuration
        egress (bool): Whether egress is enabled
        created_at (datetime): When the network was created
        updated_at (datetime): When the network was last updated
        status (str): The current status of the network
        vpn_region (Optional[str]): The VPN region for the network
        dns_servers (List[str]): List of DNS servers
        routes (List[Dict[str, Any]]): List of routes
        connectors (List[Dict[str, Any]]): List of connectors
    """
    
    id: str
    name: str
    description: Optional[str] = None
    internet_access: str = "split_tunnel_on"
    egress: bool = True
    created_at: Optional[datetime] = None
    updated_at: Optional[datetime] = None
    status: str = "active"
    vpn_region: Optional[str] = None
    dns_servers: List[str] = None
    routes: List[Dict[str, Any]] = None
    connectors: List[Dict[str, Any]] = None
    
    @classmethod
    def from_dict(cls, data: Dict[str, Any]) -> 'Network':
        """Create a Network instance from a dictionary.
        
        Args:
            data: Dictionary containing network data
            
        Returns:
            Network: A new Network instance
        """
        # Convert timestamp strings to datetime objects if present
        if 'created_at' in data and data['created_at']:
            data['created_at'] = datetime.fromisoformat(data['created_at'].replace('Z', '+00:00'))
        if 'updated_at' in data and data['updated_at']:
            data['updated_at'] = datetime.fromisoformat(data['updated_at'].replace('Z', '+00:00'))
            
        return cls(**data)
    
    def to_dict(self) -> Dict[str, Any]:
        """Convert the Network instance to a dictionary.
        
        Returns:
            dict: Dictionary representation of the network
        """
        data = {
            'id': self.id,
            'name': self.name,
            'description': self.description,
            'internet_access': self.internet_access,
            'egress': self.egress,
            'status': self.status,
            'vpn_region': self.vpn_region,
            'dns_servers': self.dns_servers or [],
            'routes': self.routes or [],
            'connectors': self.connectors or []
        }
        
        # Convert datetime objects to ISO format strings
        if self.created_at:
            data['created_at'] = self.created_at.isoformat()
        if self.updated_at:
            data['updated_at'] = self.updated_at.isoformat()
            
        return data 