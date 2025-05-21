# Phase 4: v1.1.0 Features

## Objectives
- Implement DNS record management (including new single record endpoint)
- Implement user group management (including new single group endpoint)
- Update IP Service DTOs to remove routing information
- Implement version compatibility layer for v1.0 and v1.1.0
- Add comprehensive tests for version-specific features
- Continue documentation with version differences highlighted

## Tasks

### 1. DNS Record Management
- [ ] Create DNSRecord model
- [ ] Implement DNS CRUD operations
- [ ] Implement single record retrieval endpoint (v1.1.0)
- [ ] Add fallback for v1.0 compatibility (list and filter)
- [ ] Add DNS validation
- [ ] Create DNS tests for both API versions
- [ ] Document DNS operations with version differences
- [ ] Add DNS examples for both API versions
- [ ] Create DNS endpoint diagrams
- [ ] Document DNS state handling

### 2. User Group Management
- [ ] Create UserGroup model
- [ ] Implement group CRUD operations
- [ ] Implement single group retrieval endpoint (v1.1.0)
- [ ] Add fallback for v1.0 compatibility (list and filter)
- [ ] Add group validation
- [ ] Create group tests for both API versions
- [ ] Document group operations with version differences
- [ ] Add group examples for both API versions
- [ ] Create group endpoint diagrams
- [ ] Document group state handling

### 3. IP Service Management
- [ ] Create IPService model without routing information (v1.1.0)
- [ ] Handle v1.0 responses with routing information
- [ ] Implement service CRUD operations
- [ ] Add adapters for version-specific DTO handling
- [ ] Add service validation
- [ ] Create IP service tests for both API versions
- [ ] Document service operations with version differences
- [ ] Add service examples for both API versions
- [ ] Create service data structure diagrams
- [ ] Document service state handling

### 4. Version Compatibility Layer
- [ ] Implement API version detection
- [ ] Create version-specific service factories
- [ ] Add version-based method switching
- [ ] Implement response format adapters
- [ ] Create compatibility test suite
- [ ] Document version compatibility strategy
- [ ] Add version migration examples
- [ ] Create version handling diagrams
- [ ] Document version-specific edge cases

## Technical Details

### DNS Record Model
```python
class DNSRecord:
    """Represents a Cloud Connexa DNS record.
    
    This model handles DNS record configuration and state management
    for both v1.0 and v1.1.0 API versions.
    
    Attributes:
        id (str): Record identifier
        network_id (str): Network identifier
        hostname (str): Hostname
        ip (str): IP address
        ttl (int): Time to live
        type (str): Record type (A, AAAA, CNAME, MX, TXT)
        created_at (str): Creation timestamp
        
    Example:
        >>> record = DNSRecord(
        ...     network_id="net_12345",
        ...     hostname="server.example.com",
        ...     ip="192.168.1.1",
        ...     type="A",
        ...     ttl=3600
        ... )
    """
    def __init__(self, network_id: str, hostname: str, ip: str, type: str = "A", ttl: int = 3600):
        self.id = None
        self.network_id = network_id
        self.hostname = hostname
        self.ip = ip
        self.type = type
        self.ttl = ttl
        self.created_at = None

    def to_dict(self) -> dict:
        """Convert DNS record to dictionary.
        
        Returns:
            dict: DNS record data
            
        Example:
            >>> record.to_dict()
            {
                'network_id': 'net_12345',
                'hostname': 'server.example.com',
                'ip': '192.168.1.1',
                'type': 'A',
                'ttl': 3600
            }
        """
        return {
            "network_id": self.network_id,
            "hostname": self.hostname,
            "ip": self.ip,
            "type": self.type,
            "ttl": self.ttl
        }

    @classmethod
    def from_dict(cls, data: dict) -> 'DNSRecord':
        """Create DNS record from dictionary.
        
        Args:
            data (dict): DNS record data
            
        Returns:
            DNSRecord: New DNS record instance
            
        Example:
            >>> record = DNSRecord.from_dict({
            ...     'id': 'dns_12345',
            ...     'network_id': 'net_12345',
            ...     'hostname': 'server.example.com',
            ...     'ip': '192.168.1.1',
            ...     'type': 'A',
            ...     'ttl': 3600,
            ...     'created_at': '2023-01-01T00:00:00Z'
            ... })
        """
        record = cls(
            network_id=data["network_id"],
            hostname=data["hostname"],
            ip=data["ip"],
            type=data.get("type", "A"),
            ttl=data.get("ttl", 3600)
        )
        record.id = data.get("id")
        record.created_at = data.get("created_at")
        return record
```

### User Group Model
```python
class UserGroup:
    """Represents a Cloud Connexa user group.
    
    This model handles user group configuration and state management
    for both v1.0 and v1.1.0 API versions.
    
    Attributes:
        id (str): Group identifier
        name (str): Group name
        description (str): Group description
        created_at (str): Creation timestamp
        updated_at (str): Last update timestamp
        
    Example:
        >>> group = UserGroup(
        ...     name="Developers",
        ...     description="Development team"
        ... )
    """
    def __init__(self, name: str, description: str = None):
        self.id = None
        self.name = name
        self.description = description
        self.created_at = None
        self.updated_at = None

    def to_dict(self) -> dict:
        """Convert user group to dictionary.
        
        Returns:
            dict: User group data
            
        Example:
            >>> group.to_dict()
            {'name': 'Developers', 'description': 'Development team'}
        """
        data = {
            "name": self.name
        }
        if self.description:
            data["description"] = self.description
        return data

    @classmethod
    def from_dict(cls, data: dict) -> 'UserGroup':
        """Create user group from dictionary.
        
        Args:
            data (dict): User group data
            
        Returns:
            UserGroup: New user group instance
            
        Example:
            >>> group = UserGroup.from_dict({
            ...     'id': 'group_12345',
            ...     'name': 'Developers',
            ...     'description': 'Development team',
            ...     'created_at': '2023-01-01T00:00:00Z'
            ... })
        """
        group = cls(
            name=data["name"],
            description=data.get("description")
        )
        group.id = data.get("id")
        group.created_at = data.get("created_at")
        group.updated_at = data.get("updated_at")
        return group
```

### IP Service Model (v1.1.0)
```python
class IPService:
    """Represents a Cloud Connexa IP service.
    
    This model handles IP service configuration without routing information
    as per v1.1.0 API specifications.
    
    Attributes:
        id (str): Service identifier
        name (str): Service name
        host_id (str): Host identifier
        enabled (bool): Service status
        protocol (str): Service protocol
        port (int): Service port
        created_at (str): Creation timestamp
        
    Example:
        >>> service = IPService(
        ...     name="Web Server",
        ...     host_id="host_12345",
        ...     protocol="tcp",
        ...     port=80
        ... )
    """
    def __init__(self, name: str, host_id: str, protocol: str, port: int, enabled: bool = True):
        self.id = None
        self.name = name
        self.host_id = host_id
        self.protocol = protocol
        self.port = port
        self.enabled = enabled
        self.created_at = None

    def to_dict(self) -> dict:
        """Convert IP service to dictionary.
        
        Returns:
            dict: IP service data
            
        Example:
            >>> service.to_dict()
            {
                'name': 'Web Server',
                'host_id': 'host_12345',
                'protocol': 'tcp',
                'port': 80,
                'enabled': True
            }
        """
        return {
            "name": self.name,
            "host_id": self.host_id,
            "protocol": self.protocol,
            "port": self.port,
            "enabled": self.enabled
        }

    @classmethod
    def from_dict(cls, data: dict) -> 'IPService':
        """Create IP service from dictionary.
        
        Args:
            data (dict): IP service data
            
        Returns:
            IPService: New IP service instance
            
        Example:
            >>> service = IPService.from_dict({
            ...     'id': 'service_12345',
            ...     'name': 'Web Server',
            ...     'host_id': 'host_12345',
            ...     'protocol': 'tcp',
            ...     'port': 80,
            ...     'enabled': True,
            ...     'created_at': '2023-01-01T00:00:00Z'
            ... })
        """
        service = cls(
            name=data["name"],
            host_id=data["host_id"],
            protocol=data["protocol"],
            port=data["port"],
            enabled=data.get("enabled", True)
        )
        service.id = data.get("id")
        service.created_at = data.get("created_at")
        return service
```

### Version Compatibility Layer
```python
class DNSService:
    """Service for managing DNS records with version compatibility.
    
    This service handles all DNS-related operations for both 
    v1.0 and v1.1.0 API versions.
    
    Example:
        >>> service = DNSService(client)
        >>> record = service.create(network_id="net_12345", hostname="server", ip="192.168.1.1")
    """
    def __init__(self, client):
        self.client = client
        self.api_version = client.api_version

    def create(self, network_id: str, hostname: str, ip: str, **kwargs) -> DNSRecord:
        """Create a new DNS record.
        
        Args:
            network_id (str): Network identifier
            hostname (str): Hostname
            ip (str): IP address
            **kwargs: Additional parameters
            
        Returns:
            DNSRecord: Created DNS record
            
        Raises:
            APIError: If DNS record creation fails
            
        Example:
            >>> record = service.create(
            ...     network_id="net_12345",
            ...     hostname="server",
            ...     ip="192.168.1.1",
            ...     type="A",
            ...     ttl=3600
            ... )
        """
        # Same implementation for both versions
        record_data = {
            "network_id": network_id,
            "hostname": hostname,
            "ip": ip,
            **kwargs
        }
        
        response = self.client.post(f"/api/{self.api_version}/dns", json=record_data)
        return DNSRecord.from_dict(response.json())

    def get(self, record_id: str) -> DNSRecord:
        """Get DNS record by ID.
        
        Args:
            record_id (str): DNS record identifier
            
        Returns:
            DNSRecord: Retrieved DNS record
            
        Raises:
            APIError: If DNS record retrieval fails
            
        Example:
            >>> record = service.get("dns_12345")
        """
        # Use dedicated endpoint in v1.1.0
        if self.api_version == "1.1.0":
            response = self.client.get(f"/api/v1.1.0/dns/{record_id}")
            return DNSRecord.from_dict(response.json())
        
        # Fall back to list and filter in v1.0
        records = self.list(record_id=record_id)
        for record in records:
            if record.id == record_id:
                return record
                
        raise ValueError(f"DNS record {record_id} not found")

    def list(self, **filters) -> list:
        """List DNS records with optional filtering.
        
        Args:
            **filters: Filter parameters
            
        Returns:
            list: List of DNS records
            
        Raises:
            APIError: If DNS record listing fails
            
        Example:
            >>> records = service.list(network_id="net_12345", type="A")
        """
        # Same implementation for both versions
        params = {k: v for k, v in filters.items() if v is not None}
        response = self.client.get(f"/api/{self.api_version}/dns", params=params)
        
        return [DNSRecord.from_dict(item) for item in response.json()["items"]]
```

### UserGroup Service Implementation
```python
class UserGroupService:
    """Service for managing user groups with version compatibility.
    
    This service handles all user group operations for both 
    v1.0 and v1.1.0 API versions.
    
    Example:
        >>> service = UserGroupService(client)
        >>> group = service.create(name="Developers", description="Dev team")
    """
    def __init__(self, client):
        self.client = client
        self.api_version = client.api_version

    def create(self, name: str, description: str = None) -> UserGroup:
        """Create a new user group.
        
        Args:
            name (str): Group name
            description (str, optional): Group description
            
        Returns:
            UserGroup: Created user group
            
        Raises:
            APIError: If group creation fails
            
        Example:
            >>> group = service.create(
            ...     name="Developers",
            ...     description="Development team"
            ... )
        """
        # Same implementation for both versions
        group_data = {"name": name}
        if description:
            group_data["description"] = description
            
        response = self.client.post(f"/api/{self.api_version}/user_groups", json=group_data)
        return UserGroup.from_dict(response.json())

    def get(self, group_id: str) -> UserGroup:
        """Get user group by ID.
        
        Args:
            group_id (str): User group identifier
            
        Returns:
            UserGroup: Retrieved user group
            
        Raises:
            APIError: If group retrieval fails
            
        Example:
            >>> group = service.get("group_12345")
        """
        # Use dedicated endpoint in v1.1.0
        if self.api_version == "1.1.0":
            response = self.client.get(f"/api/v1.1.0/user_groups/{group_id}")
            return UserGroup.from_dict(response.json())
        
        # Fall back to list and filter in v1.0
        groups = self.list(group_id=group_id)
        for group in groups:
            if group.id == group_id:
                return group
                
        raise ValueError(f"User group {group_id} not found")
```

### IP Service Adapter for Version Compatibility
```python
class IPServiceAdapter:
    """Adapter for converting between IP service formats.
    
    This adapter handles conversion between v1.0 (with routing)
    and v1.1.0 (without routing) IP service formats.
    
    Example:
        >>> adapter = IPServiceAdapter()
        >>> service_v110 = adapter.to_v110(service_v10)
    """
    def to_v110(self, v10_data: dict) -> dict:
        """Convert v1.0 IP service data to v1.1.0 format.
        
        Args:
            v10_data (dict): v1.0 format with routing
            
        Returns:
            dict: v1.1.0 format without routing
            
        Example:
            >>> v11_data = adapter.to_v110({
            ...     'id': 'service_12345',
            ...     'name': 'Web Server',
            ...     'host_id': 'host_12345',
            ...     'routing': { 'network': '192.168.1.0/24' }
            ... })
        """
        # Remove routing information
        result = v10_data.copy()
        if "routing" in result:
            del result["routing"]
        return result
        
    def to_v10(self, v110_data: dict) -> dict:
        """Convert v1.1.0 IP service data to v1.0 format.
        
        Args:
            v110_data (dict): v1.1.0 format without routing
            
        Returns:
            dict: v1.0 format with routing
            
        Example:
            >>> v10_data = adapter.to_v10({
            ...     'id': 'service_12345',
            ...     'name': 'Web Server',
            ...     'host_id': 'host_12345'
            ... })
        """
        # Add default routing information
        result = v110_data.copy()
        if "routing" not in result:
            result["routing"] = {
                "network": "0.0.0.0/0",
                "gateway": None
            }
        return result
```

## Testing Strategy

### Unit Tests
- Model serialization/deserialization
- Model validation
- Version-specific serialization
- DTO conversions
- Error handling

### Integration Tests
- End-to-end operations on both API versions
- Fallback mechanisms for v1.0
- Version switching behavior
- Error scenarios

### Compatibility Tests
- Test both v1.0 and v1.1.0 endpoints
- Verify DNS single record retrieval works with both versions
- Verify User Group single record retrieval works with both versions
- Test IP Service DTO with and without routing information
- Verify version detection works correctly

## Documentation Requirements

### API Documentation
- Version-specific endpoint differences
- Compatibility guide
- Migration guide from v1.0 to v1.1.0
- Version-specific examples

### Code Documentation
- Version handling in docstrings
- Example usage for both versions
- Error scenarios
- Version-specific edge cases

## Success Criteria
- [ ] All DNS operations work in both API versions
- [ ] All User Group operations work in both API versions
- [ ] IP Service DTOs correctly handle routing information differences
- [ ] Version compatibility test suite passes
- [ ] Documentation clearly explains version differences
- [ ] 90%+ test coverage for version-specific code
- [ ] All integration tests pass

## Dependencies
- Phase 3 completion
- requests>=2.25.0
- pytest>=6.0.0
- pytest-cov>=2.12.0

## Next Steps
- Begin Phase 5 implementation
- Review and refine Phase 4
- Gather feedback
- Continue documentation updates 