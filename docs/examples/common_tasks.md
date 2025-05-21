# Common VPN Operations with Cloud Connexa API Client

This guide provides practical examples of everyday VPN management tasks that developers commonly need to perform with the Cloud Connexa API client.

## Overview

This document presents step-by-step solutions for frequent operations developers need to perform when managing VPN infrastructure with Cloud Connexa. Each example includes complete, runnable code with proper error handling and follows the patterns in the official API documentation.

## 1. User Onboarding Workflow

One of the most common tasks is onboarding new users to your organization's VPN service.

```python
from cloudconnexa import CloudConnexaClient
import os

# Initialize client with environment variables for secure credential handling
client = CloudConnexaClient(
    api_url=os.getenv("CLOUDCONNEXA_API_URL"),
    client_id=os.getenv("CLOUDCONNEXA_CLIENT_ID"),
    client_secret=os.getenv("CLOUDCONNEXA_CLIENT_SECRET")
)

def onboard_new_user(email, first_name, last_name, group_names=None):
    """
    Onboard a new user to Cloud Connexa.
    
    Args:
        email: User's email address
        first_name: User's first name
        last_name: User's last name
        group_names: List of group names to add the user to
    
    Returns:
        User object and a list of groups the user was added to
    """
    # 1. Create the user
    user = client.users.create(
        email=email,
        first_name=first_name,
        last_name=last_name,
        role="member"  # Standard member role
    )
    
    print(f"Created user: {user.email} (ID: {user.id})")
    
    added_groups = []
    
    # 2. Add user to specified groups if provided
    if group_names:
        # First get all groups to resolve names to IDs
        all_groups = client.user_groups.list()
        group_map = {group.name: group.id for group in all_groups}
        
        for group_name in group_names:
            if group_name in group_map:
                # Add user to group
                client.user_groups.add_user(
                    group_id=group_map[group_name],
                    user_id=user.id
                )
                added_groups.append(group_name)
                print(f"Added user to group: {group_name}")
            else:
                print(f"Warning: Group '{group_name}' not found")
    
    return user, added_groups

# Example usage
new_user, groups = onboard_new_user(
    email="new.employee@example.com",
    first_name="Jane",
    last_name="Smith",
    group_names=["Engineering", "VPN Users"]
)
```

## 2. Network Configuration Management

Managing network configurations is another frequent task for administrators.

```python
from cloudconnexa import CloudConnexaClient
import os

client = CloudConnexaClient(
    api_url=os.getenv("CLOUDCONNEXA_API_URL"),
    client_id=os.getenv("CLOUDCONNEXA_CLIENT_ID"),
    client_secret=os.getenv("CLOUDCONNEXA_CLIENT_SECRET")
)

def configure_network(network_name, description=None, update_existing=True):
    """
    Create or update a network with standard configurations.
    
    Args:
        network_name: Name of the network
        description: Optional network description
        update_existing: Whether to update if network already exists
    
    Returns:
        The created or updated network
    """
    # Check if network already exists
    existing_networks = client.networks.list()
    existing_network = next((n for n in existing_networks if n.name == network_name), None)
    
    if existing_network and update_existing:
        # Update existing network
        network = client.networks.update(
            network_id=existing_network.id,
            name=network_name,
            description=description or existing_network.description,
            internet_access="split_tunnel_on",  # Allow internet access with split tunneling
            egress=True  # Allow egress traffic
        )
        print(f"Updated network: {network.name} (ID: {network.id})")
    elif not existing_network:
        # Create new network
        network = client.networks.create(
            name=network_name,
            description=description or f"Network for {network_name}",
            internet_access="split_tunnel_on",
            egress=True
        )
        print(f"Created network: {network.name} (ID: {network.id})")
    else:
        # Network exists but update_existing is False
        print(f"Network '{network_name}' already exists and update_existing=False")
        network = existing_network
    
    return network

# Example usage
network = configure_network(
    network_name="Development",
    description="Network for development team",
    update_existing=True
)
```

## 3. IP Service Management for Access Control

Managing IP services for access control is essential for network security.

```python
from cloudconnexa import CloudConnexaClient
import os

client = CloudConnexaClient(
    api_url=os.getenv("CLOUDCONNEXA_API_URL"),
    client_id=os.getenv("CLOUDCONNEXA_CLIENT_ID"),
    client_secret=os.getenv("CLOUDCONNEXA_CLIENT_SECRET")
)

def manage_ip_services(network_id, services_config):
    """
    Create or update IP services for a network.
    
    Args:
        network_id: ID of the network to manage IP services for
        services_config: List of dicts with service configurations
                        [{"name": "Web", "protocol": "tcp", "port": 80}, ...]
    
    Returns:
        Dictionary mapping service names to created/updated service objects
    """
    # Get existing IP services
    existing_services = client.ip_services.list(network_id=network_id)
    existing_service_map = {service.name: service for service in existing_services}
    
    result_services = {}
    
    for service_config in services_config:
        service_name = service_config["name"]
        
        if service_name in existing_service_map:
            # Update existing service
            service = client.ip_services.update(
                network_id=network_id,
                service_id=existing_service_map[service_name].id,
                **service_config
            )
            print(f"Updated IP service: {service.name}")
        else:
            # Create new service
            service = client.ip_services.create(
                network_id=network_id,
                **service_config
            )
            print(f"Created IP service: {service.name}")
        
        result_services[service_name] = service
    
    return result_services

# Example usage
network_id = "net_abc123"  # Replace with actual network ID
services = manage_ip_services(
    network_id=network_id,
    services_config=[
        {"name": "HTTP", "protocol": "tcp", "port": 80},
        {"name": "HTTPS", "protocol": "tcp", "port": 443},
        {"name": "SSH", "protocol": "tcp", "port": 22},
        {"name": "DNS", "protocol": "udp", "port": 53}
    ]
)
```

## 4. Connector Deployment and Configuration

Connectors are key components that provide network connectivity.

```python
from cloudconnexa import CloudConnexaClient
import os

client = CloudConnexaClient(
    api_url=os.getenv("CLOUDCONNEXA_API_URL"),
    client_id=os.getenv("CLOUDCONNEXA_CLIENT_ID"),
    client_secret=os.getenv("CLOUDCONNEXA_CLIENT_SECRET")
)

def deploy_connector(network_id, connector_name, region_code=None):
    """
    Deploy a new connector in a specific region.
    
    Args:
        network_id: The network ID to deploy the connector in
        connector_name: Name for the new connector
        region_code: Optional region code, if None, first available region is used
    
    Returns:
        The created connector and its configuration
    """
    # If no region specified, get available regions and use the first one
    if not region_code:
        regions = client.vpn_regions.list()
        if not regions:
            raise ValueError("No VPN regions available")
        region_code = regions[0].vpn_region_code
        print(f"No region specified, using: {region_code}")
    
    # Create the connector
    connector = client.connectors.create(
        network_id=network_id,
        name=connector_name,
        vpn_region=region_code
    )
    print(f"Created connector: {connector.name} (ID: {connector.id})")
    
    # Get connector configuration (for installation)
    connector_config = client.connectors.get_config(
        network_id=network_id,
        connector_id=connector.id
    )
    
    return connector, connector_config

# Example usage
network_id = "net_abc123"  # Replace with actual network ID
connector, config = deploy_connector(
    network_id=network_id,
    connector_name="nyc-datacenter-1",
    region_code="us-east-1"  # AWS US East region
)

# Save connector configuration to file
with open(f"{connector.name}-config.ovpn", "w") as f:
    f.write(config.config_text)
print(f"Saved connector configuration to {connector.name}-config.ovpn")
```

## 5. Route Management and DNS Configuration

Managing routes and DNS records is essential for proper network connectivity.

```python
from cloudconnexa import CloudConnexaClient
import os

client = CloudConnexaClient(
    api_url=os.getenv("CLOUDCONNEXA_API_URL"),
    client_id=os.getenv("CLOUDCONNEXA_CLIENT_ID"),
    client_secret=os.getenv("CLOUDCONNEXA_CLIENT_SECRET")
)

def configure_routes_and_dns(network_id, connector_id, routes, dns_records=None):
    """
    Configure routes and DNS records for a connector.
    
    Args:
        network_id: ID of the network
        connector_id: ID of the connector to configure
        routes: List of dicts with route configurations
               [{"cidr": "10.0.0.0/8", "description": "Internal network"}, ...]
        dns_records: Optional list of DNS records to configure
                    [{"hostname": "db.internal", "ip": "10.0.0.5"}, ...]
    
    Returns:
        Dictionary containing created routes and DNS records
    """
    created_routes = []
    created_dns_records = []
    
    # 1. Add routes to the connector
    for route_config in routes:
        try:
            route = client.routes.create(
                network_id=network_id,
                connector_id=connector_id,
                cidr=route_config["cidr"],
                description=route_config.get("description", "")
            )
            created_routes.append(route)
            print(f"Created route: {route.cidr} (ID: {route.id})")
        except Exception as e:
            print(f"Error creating route {route_config['cidr']}: {str(e)}")
    
    # 2. Add DNS records if provided
    if dns_records:
        for dns_config in dns_records:
            try:
                dns_record = client.dns.create(
                    network_id=network_id,
                    hostname=dns_config["hostname"],
                    ip=dns_config["ip"]
                )
                created_dns_records.append(dns_record)
                print(f"Created DNS record: {dns_record.hostname} -> {dns_record.ip}")
            except Exception as e:
                print(f"Error creating DNS record {dns_config['hostname']}: {str(e)}")
    
    return {
        "routes": created_routes,
        "dns_records": created_dns_records
    }

# Example usage
network_id = "net_abc123"  # Replace with actual network ID
connector_id = "conn_xyz789"  # Replace with actual connector ID

config_result = configure_routes_and_dns(
    network_id=network_id,
    connector_id=connector_id,
    routes=[
        {"cidr": "10.0.0.0/8", "description": "Internal network"},
        {"cidr": "172.16.0.0/12", "description": "Development network"}
    ],
    dns_records=[
        {"hostname": "db.internal", "ip": "10.0.0.5"},
        {"hostname": "api.internal", "ip": "10.0.0.10"}
    ]
)

print(f"Created {len(config_result['routes'])} routes and {len(config_result['dns_records'])} DNS records")
```

This example shows how to:
1. Create routes for a connector to enable network communication
2. Add DNS records to resolve hostnames within the VPN network
3. Handle potential errors during the configuration process

Routes enable traffic to flow through the VPN to specific network ranges, while DNS records help users connect to resources using names instead of IP addresses. Both are essential for a well-configured VPN solution.

## 6. User Access Audit and Reporting

Auditing user access is important for security compliance.

```python
from cloudconnexa import CloudConnexaClient
import os
import csv
from datetime import datetime

client = CloudConnexaClient(
    api_url=os.getenv("CLOUDCONNEXA_API_URL"),
    client_id=os.getenv("CLOUDCONNEXA_CLIENT_ID"),
    client_secret=os.getenv("CLOUDCONNEXA_CLIENT_SECRET")
)

def generate_access_report():
    """
    Generate a comprehensive access report of all users and their group memberships.
    
    Returns:
        Path to the generated CSV report
    """
    # Get all users
    users = client.users.list()
    print(f"Found {len(users)} users")
    
    # Get all groups
    groups = client.user_groups.list()
    print(f"Found {len(groups)} user groups")
    
    # Build a map of group members
    group_members = {}
    for group in groups:
        # Get members for each group
        members = client.user_groups.list_users(group_id=group.id)
        group_members[group.id] = {member.id: member for member in members}
    
    # Prepare report data
    report_data = []
    for user in users:
        # Find which groups this user belongs to
        user_groups = []
        for group_id, members in group_members.items():
            if user.id in members:
                group = next(g for g in groups if g.id == group_id)
                user_groups.append(group.name)
        
        report_data.append({
            "user_id": user.id,
            "email": user.email,
            "name": f"{user.first_name} {user.last_name}",
            "role": user.role,
            "groups": ", ".join(user_groups) if user_groups else "None",
            "created_at": user.created_at
        })
    
    # Generate CSV report
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    report_path = f"user_access_report_{timestamp}.csv"
    
    with open(report_path, "w", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=["user_id", "email", "name", "role", "groups", "created_at"])
        writer.writeheader()
        writer.writerows(report_data)
    
    print(f"Generated access report: {report_path}")
    return report_path

# Generate the access report
report_file = generate_access_report()
```

## 7. DNS Record Management

Managing DNS records for your network.

```python
from cloudconnexa import CloudConnexaClient
import os

client = CloudConnexaClient(
    api_url=os.getenv("CLOUDCONNEXA_API_URL"),
    client_id=os.getenv("CLOUDCONNEXA_CLIENT_ID"),
    client_secret=os.getenv("CLOUDCONNEXA_CLIENT_SECRET")
)

def manage_dns_records(network_id, dns_records):
    """
    Create or update DNS records for a network.
    
    Args:
        network_id: The network ID
        dns_records: List of dicts with DNS record configurations
                    [{"name": "server1", "type": "A", "value": "192.168.1.10"}, ...]
    
    Returns:
        Dictionary mapping record names to created/updated record objects
    """
    # Get existing DNS records
    existing_records = client.dns.list(network_id=network_id)
    
    # Create a map for easy lookup (name+type -> record)
    record_key = lambda r: f"{r.name}:{r.type}"
    existing_record_map = {record_key(record): record for record in existing_records}
    
    result_records = {}
    
    for record_config in dns_records:
        record_name = record_config["name"]
        record_type = record_config["type"]
        key = f"{record_name}:{record_type}"
        
        if key in existing_record_map:
            # Update existing record
            record = client.dns.update(
                network_id=network_id,
                record_id=existing_record_map[key].id,
                **record_config
            )
            print(f"Updated DNS record: {record.name} ({record.type})")
        else:
            # Create new record
            record = client.dns.create(
                network_id=network_id,
                **record_config
            )
            print(f"Created DNS record: {record.name} ({record.type})")
        
        result_records[key] = record
    
    return result_records

# Example usage
network_id = "net_abc123"  # Replace with actual network ID
dns_records = manage_dns_records(
    network_id=network_id,
    dns_records=[
        {"name": "www", "type": "A", "value": "192.168.1.10", "ttl": 3600},
        {"name": "db", "type": "A", "value": "192.168.1.20", "ttl": 3600},
        {"name": "api", "type": "CNAME", "value": "services.example.com", "ttl": 3600},
        {"name": "mail", "type": "MX", "value": "mail.example.com", "priority": 10, "ttl": 3600}
    ]
)
```

## 8. Automated User Provisioning from HR System

Integrate with your HR system to automatically provision and deprovision users.

```python
from cloudconnexa import CloudConnexaClient
import os
import csv
import time

client = CloudConnexaClient(
    api_url=os.getenv("CLOUDCONNEXA_API_URL"),
    client_id=os.getenv("CLOUDCONNEXA_CLIENT_ID"),
    client_secret=os.getenv("CLOUDCONNEXA_CLIENT_SECRET")
)

def sync_users_from_hr_system(hr_data_file, default_groups=None):
    """
    Sync users from HR system data file to Cloud Connexa.
    
    Args:
        hr_data_file: CSV file with HR data (columns: email, first_name, last_name, department)
        default_groups: List of default group names to add all users to
    
    Returns:
        Tuple of (users_added, users_updated, users_removed) counts
    """
    # Get current users from Cloud Connexa
    existing_users = client.users.list()
    email_to_user = {user.email.lower(): user for user in existing_users}
    
    # Get groups for mapping departments to groups
    all_groups = client.user_groups.list()
    group_name_to_id = {group.name: group.id for group in all_groups}
    
    # Create missing groups for departments
    def ensure_group_exists(group_name):
        if group_name not in group_name_to_id:
            group = client.user_groups.create(name=group_name)
            group_name_to_id[group_name] = group.id
            print(f"Created group: {group_name}")
        return group_name_to_id[group_name]
    
    # Process HR data
    hr_emails = set()
    users_added = 0
    users_updated = 0
    
    with open(hr_data_file, 'r') as f:
        reader = csv.DictReader(f)
        for row in reader:
            email = row['email'].lower()
            hr_emails.add(email)
            
            department = row.get('department', '')
            department_group = f"Department-{department}" if department else None
            
            # Ensure department group exists if provided
            if department_group:
                ensure_group_exists(department_group)
            
            # Collect groups for this user
            user_groups = []
            if default_groups:
                user_groups.extend(default_groups)
            if department_group:
                user_groups.append(department_group)
            
            if email in email_to_user:
                # Update existing user
                user = email_to_user[email]
                client.users.update(
                    user_id=user.id,
                    first_name=row['first_name'],
                    last_name=row['last_name']
                )
                users_updated += 1
            else:
                # Create new user
                user = client.users.create(
                    email=email,
                    first_name=row['first_name'],
                    last_name=row['last_name'],
                    role="member"
                )
                users_added += 1
                time.sleep(1)  # Rate limiting precaution
            
            # Manage group memberships
            for group_name in user_groups:
                if group_name in group_name_to_id:
                    try:
                        client.user_groups.add_user(
                            group_id=group_name_to_id[group_name],
                            user_id=user.id
                        )
                    except Exception as e:
                        # Might fail if user is already in group, which is fine
                        pass
    
    # Handle user removals (in HR file but not in system)
    users_to_remove = set(email_to_user.keys()) - hr_emails
    users_removed = 0
    
    for email in users_to_remove:
        user = email_to_user[email]
        try:
            client.users.delete(user_id=user.id)
            users_removed += 1
            print(f"Removed user no longer in HR system: {email}")
            time.sleep(1)  # Rate limiting precaution
        except Exception as e:
            print(f"Error removing user {email}: {str(e)}")
    
    print(f"Sync completed: {users_added} added, {users_updated} updated, {users_removed} removed")
    return users_added, users_updated, users_removed

# Example usage
added, updated, removed = sync_users_from_hr_system(
    hr_data_file="hr_employees.csv",
    default_groups=["All Users", "VPN Access"]
)
```

## 9. VPN Access Control Management

Managing which users and groups can access specific networks and resources is a critical security task.

```python
from cloudconnexa import CloudConnexaClient
import os

client = CloudConnexaClient(
    api_url=os.getenv("CLOUDCONNEXA_API_URL"),
    client_id=os.getenv("CLOUDCONNEXA_CLIENT_ID"),
    client_secret=os.getenv("CLOUDCONNEXA_CLIENT_SECRET")
)

def setup_network_access_control(network_name, allowed_groups=None, allowed_users=None):
    """
    Configure access control for a network, limiting access to specific groups and/or users.
    
    Args:
        network_name: Name of the network to configure
        allowed_groups: List of group names that should have access
        allowed_users: List of user emails that should have access regardless of group
    
    Returns:
        Dict containing access control details
    """
    # Find the network by name
    networks = client.networks.list()
    network = next((n for n in networks if n.name == network_name), None)
    
    if not network:
        raise ValueError(f"Network '{network_name}' not found")
    
    print(f"Configuring access control for network: {network.name} (ID: {network.id})")
    
    # Get all user groups
    all_groups = client.user_groups.list()
    group_name_map = {g.name: g for g in all_groups}
    
    # Get all users
    all_users = client.users.list()
    user_email_map = {u.email.lower(): u for u in all_users}
    
    # Track which groups and users were granted access
    access_granted = {
        "groups": [],
        "users": []
    }
    
    # Configure group access
    if allowed_groups:
        for group_name in allowed_groups:
            if group_name in group_name_map:
                group = group_name_map[group_name]
                
                # Grant network access to the group
                client.network_accesses.create(
                    network_id=network.id,
                    group_id=group.id
                )
                
                access_granted["groups"].append({
                    "name": group.name,
                    "id": group.id
                })
                
                print(f"Granted network access to group: {group.name}")
            else:
                print(f"Warning: Group '{group_name}' not found")
    
    # Configure individual user access
    if allowed_users:
        for email in allowed_users:
            email = email.lower()
            if email in user_email_map:
                user = user_email_map[email]
                
                # Grant network access to the user
                client.network_accesses.create(
                    network_id=network.id,
                    user_id=user.id
                )
                
                access_granted["users"].append({
                    "email": user.email,
                    "id": user.id
                })
                
                print(f"Granted network access to user: {user.email}")
            else:
                print(f"Warning: User with email '{email}' not found")
    
    return access_granted

def revoke_network_access(network_name, revoke_groups=None, revoke_users=None):
    """
    Revoke access to a network for specific groups and/or users.
    
    Args:
        network_name: Name of the network
        revoke_groups: List of group names to revoke access from
        revoke_users: List of user emails to revoke access from
    
    Returns:
        Dict containing revoked access details
    """
    # Find the network by name
    networks = client.networks.list()
    network = next((n for n in networks if n.name == network_name), None)
    
    if not network:
        raise ValueError(f"Network '{network_name}' not found")
    
    print(f"Revoking access for network: {network.name} (ID: {network.id})")
    
    # Get all current network accesses
    accesses = client.network_accesses.list(network_id=network.id)
    
    # Get all groups and users for reference
    all_groups = client.user_groups.list()
    group_map = {g.id: g for g in all_groups}
    group_name_to_id = {g.name: g.id for g in all_groups}
    
    all_users = client.users.list()
    user_map = {u.id: u for u in all_users}
    user_email_to_id = {u.email.lower(): u.id for u in all_users}
    
    # Track what was revoked
    access_revoked = {
        "groups": [],
        "users": []
    }
    
    # Process group revocations
    if revoke_groups:
        for group_name in revoke_groups:
            if group_name in group_name_to_id:
                group_id = group_name_to_id[group_name]
                
                # Find the access object for this group
                access = next((a for a in accesses 
                              if a.group_id == group_id), None)
                
                if access:
                    # Revoke the access
                    client.network_accesses.delete(
                        network_id=network.id,
                        access_id=access.id
                    )
                    
                    access_revoked["groups"].append({
                        "name": group_name,
                        "id": group_id
                    })
                    
                    print(f"Revoked network access from group: {group_name}")
                else:
                    print(f"Note: Group '{group_name}' did not have access to revoke")
            else:
                print(f"Warning: Group '{group_name}' not found")
    
    # Process user revocations
    if revoke_users:
        for email in revoke_users:
            email = email.lower()
            if email in user_email_to_id:
                user_id = user_email_to_id[email]
                
                # Find the access object for this user
                access = next((a for a in accesses 
                              if a.user_id == user_id), None)
                
                if access:
                    # Revoke the access
                    client.network_accesses.delete(
                        network_id=network.id,
                        access_id=access.id
                    )
                    
                    access_revoked["users"].append({
                        "email": email,
                        "id": user_id
                    })
                    
                    print(f"Revoked network access from user: {email}")
                else:
                    print(f"Note: User '{email}' did not have access to revoke")
            else:
                print(f"Warning: User with email '{email}' not found")
    
    return access_revoked

def list_network_access(network_name):
    """
    List all users and groups with access to a specific network.
    
    Args:
        network_name: Name of the network to check
    
    Returns:
        Dict containing access details
    """
    # Find the network by name
    networks = client.networks.list()
    network = next((n for n in networks if n.name == network_name), None)
    
    if not network:
        raise ValueError(f"Network '{network_name}' not found")
    
    # Get all current network accesses
    accesses = client.network_accesses.list(network_id=network.id)
    
    # Get all groups and users for reference
    all_groups = client.user_groups.list()
    group_map = {g.id: g for g in all_groups}
    
    all_users = client.users.list()
    user_map = {u.id: u for u in all_users}
    
    # Map accesses to meaningful names
    access_details = {
        "network": {
            "name": network.name,
            "id": network.id
        },
        "groups": [],
        "users": []
    }
    
    for access in accesses:
        if access.group_id and access.group_id in group_map:
            group = group_map[access.group_id]
            access_details["groups"].append({
                "name": group.name,
                "id": group.id
            })
        elif access.user_id and access.user_id in user_map:
            user = user_map[access.user_id]
            access_details["users"].append({
                "email": user.email,
                "name": f"{user.first_name} {user.last_name}",
                "id": user.id
            })
    
    print(f"Network '{network.name}' access:")
    print(f"- Groups with access: {len(access_details['groups'])}")
    print(f"- Individual users with access: {len(access_details['users'])}")
    
    return access_details

# Example 1: Grant access to a network
access_granted = setup_network_access_control(
    network_name="Finance",
    allowed_groups=["Finance Team", "Executive Management"],
    allowed_users=["contractor@example.com", "auditor@example.com"]
)

# Example 2: Revoke access from specific users or groups
access_revoked = revoke_network_access(
    network_name="Development",
    revoke_groups=["Interns"],
    revoke_users=["former.employee@example.com"]
)

# Example 3: List current access for a network
access_details = list_network_access(network_name="Production")
```

This example demonstrates how to:
1. Grant network access to specific user groups and individual users
2. Revoke access when needed (e.g., for departing employees or project completion)
3. List and audit current network access permissions

These operations are essential for maintaining proper security controls in your VPN environment, especially in organizations with staff changes or projects that require temporary access to specific resources.

## 10. VPN Client Profile Management

Managing client profiles (VPN configurations) is a critical administrative task for deploying and maintaining your VPN service.

```python
from cloudconnexa import CloudConnexaClient
import os
import base64
import json
from datetime import datetime
import zipfile
import io

client = CloudConnexaClient(
    api_url=os.getenv("CLOUDCONNEXA_API_URL"),
    client_id=os.getenv("CLOUDCONNEXA_CLIENT_ID"),
    client_secret=os.getenv("CLOUDCONNEXA_CLIENT_SECRET")
)

def generate_client_profile(user_email, network_name, profile_name=None, profile_type="ovpn"):
    """
    Generate a VPN client profile for a specific user and network.
    
    Args:
        user_email: Email of the user to generate profile for
        network_name: Name of the network to connect to
        profile_name: Optional custom name for the profile (defaults to network name)
        profile_type: Type of profile to generate ('ovpn' or 'wireguard')
    
    Returns:
        Dict containing profile details and configuration content
    """
    # Find the user by email
    users = client.users.list()
    user = next((u for u in users if u.email.lower() == user_email.lower()), None)
    
    if not user:
        raise ValueError(f"User with email '{user_email}' not found")
    
    # Find the network by name
    networks = client.networks.list()
    network = next((n for n in networks if n.name == network_name), None)
    
    if not network:
        raise ValueError(f"Network '{network_name}' not found")
    
    # Generate the profile name if not provided
    if not profile_name:
        profile_name = f"{network_name}-{datetime.now().strftime('%Y%m%d')}"
    
    print(f"Generating {profile_type} profile '{profile_name}' for {user.email} on network '{network.name}'")
    
    # Request profile generation
    profile_response = client.profiles.create(
        user_id=user.id,
        network_id=network.id,
        name=profile_name,
        type=profile_type
    )
    
    if not profile_response or not hasattr(profile_response, 'id'):
        raise Exception("Failed to generate profile")
    
    # Get the profile configuration
    profile_config = client.profiles.get_config(
        user_id=user.id,
        profile_id=profile_response.id
    )
    
    # Create result with profile details
    result = {
        "profile_id": profile_response.id,
        "name": profile_response.name,
        "type": profile_response.type,
        "user_email": user.email,
        "user_id": user.id,
        "network_name": network.name,
        "network_id": network.id,
        "config_text": profile_config.config_text,
        "created_at": datetime.now().isoformat()
    }
    
    print(f"Successfully generated {profile_type} profile for {user.email}")
    return result

def generate_bulk_profiles(user_emails, network_name, profile_type="ovpn"):
    """
    Generate VPN profiles for multiple users for the same network.
    
    Args:
        user_emails: List of user email addresses
        network_name: Name of the network to connect to
        profile_type: Type of profile to generate ('ovpn' or 'wireguard')
        
    Returns:
        List of generated profiles and a ZIP file containing all configurations
    """
    profiles = []
    
    # Generate profiles for each user
    for email in user_emails:
        try:
            profile = generate_client_profile(
                user_email=email,
                network_name=network_name,
                profile_name=f"{network_name}-{email.split('@')[0]}",
                profile_type=profile_type
            )
            profiles.append(profile)
        except Exception as e:
            print(f"Error generating profile for {email}: {str(e)}")
    
    # Create a ZIP file with all the profiles
    if profiles:
        zip_buffer = io.BytesIO()
        with zipfile.ZipFile(zip_buffer, 'a', zipfile.ZIP_DEFLATED) as zip_file:
            for profile in profiles:
                filename = f"{profile['name']}.{profile_type}"
                zip_file.writestr(filename, profile["config_text"])
                
                # Also add a JSON metadata file
                metadata = {k: v for k, v in profile.items() if k != 'config_text'}
                metadata_filename = f"{profile['name']}_metadata.json"
                zip_file.writestr(metadata_filename, json.dumps(metadata, indent=2))
        
        # Write the ZIP file
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        zip_filename = f"vpn_profiles_{network_name}_{timestamp}.zip"
        with open(zip_filename, 'wb') as f:
            f.write(zip_buffer.getvalue())
        
        print(f"Created ZIP file with {len(profiles)} profiles: {zip_filename}")
        
        return {
            "profiles": profiles,
            "zip_file": zip_filename
        }
    
    return {"profiles": profiles}

def list_user_profiles(user_email):
    """
    List all VPN profiles for a specific user.
    
    Args:
        user_email: Email of the user to list profiles for
        
    Returns:
        List of profile details
    """
    # Find the user by email
    users = client.users.list()
    user = next((u for u in users if u.email.lower() == user_email.lower()), None)
    
    if not user:
        raise ValueError(f"User with email '{user_email}' not found")
    
    # Get all profiles for the user
    profiles = client.profiles.list(user_id=user.id)
    
    # Get network details for each profile
    networks = {n.id: n for n in client.networks.list()}
    
    # Format the results
    result = []
    for profile in profiles:
        network = networks.get(profile.network_id, {"name": "Unknown"})
        result.append({
            "id": profile.id,
            "name": profile.name,
            "type": profile.type,
            "network_id": profile.network_id,
            "network_name": network.name if hasattr(network, 'name') else "Unknown",
            "created_at": profile.created_at if hasattr(profile, 'created_at') else "Unknown"
        })
    
    print(f"Found {len(result)} profiles for user {user_email}")
    return result

def revoke_profile(user_email, profile_id=None, profile_name=None):
    """
    Revoke a VPN profile for a user by ID or name.
    
    Args:
        user_email: Email of the user
        profile_id: ID of the profile to revoke (takes precedence if both provided)
        profile_name: Name of the profile to revoke (only used if profile_id not provided)
        
    Returns:
        Dict with revocation details
    """
    if not profile_id and not profile_name:
        raise ValueError("Either profile_id or profile_name must be provided")
    
    # Find the user by email
    users = client.users.list()
    user = next((u for u in users if u.email.lower() == user_email.lower()), None)
    
    if not user:
        raise ValueError(f"User with email '{user_email}' not found")
    
    # If only name provided, get ID by listing profiles
    if not profile_id and profile_name:
        profiles = client.profiles.list(user_id=user.id)
        profile = next((p for p in profiles if p.name == profile_name), None)
        
        if not profile:
            raise ValueError(f"Profile with name '{profile_name}' not found for user {user_email}")
        
        profile_id = profile.id
    
    # Revoke the profile
    try:
        client.profiles.delete(
            user_id=user.id,
            profile_id=profile_id
        )
        
        result = {
            "status": "revoked",
            "user_email": user_email,
            "user_id": user.id,
            "profile_id": profile_id,
            "profile_name": profile_name,
            "revoked_at": datetime.now().isoformat()
        }
        
        print(f"Successfully revoked profile for {user_email}")
        return result
    
    except Exception as e:
        print(f"Error revoking profile: {str(e)}")
        raise

# Example 1: Generate a profile for a single user
profile = generate_client_profile(
    user_email="employee@example.com",
    network_name="Corporate-HQ",
    profile_type="ovpn"
)

# Save the configuration to a file
with open(f"{profile['name']}.ovpn", "w") as f:
    f.write(profile['config_text'])

# Example 2: Generate profiles for a team
marketing_team = [
    "marketer1@example.com",
    "marketer2@example.com",
    "marketer3@example.com"
]

team_profiles = generate_bulk_profiles(
    user_emails=marketing_team,
    network_name="Marketing-Network",
    profile_type="ovpn"
)

# Example 3: List all profiles for a user
user_profiles = list_user_profiles("employee@example.com")
for p in user_profiles:
    print(f"Profile: {p['name']} ({p['network_name']})")

# Example 4: Revoke a profile that's no longer needed
revocation = revoke_profile(
    user_email="former.employee@example.com",
    profile_name="Corporate-HQ-profile"
)
```

This example demonstrates how to:
1. Generate individual VPN client profiles for users
2. Bulk generate profiles for multiple users with a single function
3. List existing profiles for any user
4. Revoke profiles when they're no longer needed

Client profile management is essential for deploying your VPN to end users. By automating these tasks, you can efficiently onboard new users, manage access changes, and maintain security by revoking access when needed.

## 11. Audit Logs and Usage Monitoring

Retrieving and analyzing audit logs is essential for security compliance, troubleshooting, and maintaining visibility into your VPN usage.

```python
from cloudconnexa import CloudConnexaClient
import os
import csv
import json
from datetime import datetime, timedelta

client = CloudConnexaClient(
    api_url=os.getenv("CLOUDCONNEXA_API_URL"),
    client_id=os.getenv("CLOUDCONNEXA_CLIENT_ID"),
    client_secret=os.getenv("CLOUDCONNEXA_CLIENT_SECRET")
)

def retrieve_audit_logs(start_time=None, end_time=None, event_types=None, user_email=None, 
                       network_id=None, limit=1000, export_format="json"):
    """
    Retrieve and filter audit logs for analysis.
    
    Args:
        start_time: Start time for logs (default: 24 hours ago)
        end_time: End time for logs (default: now)
        event_types: List of event types to filter (e.g., ["LOGIN", "PROFILE_CREATE"])
        user_email: Filter logs for a specific user
        network_id: Filter logs for a specific network
        limit: Maximum number of logs to retrieve
        export_format: Format for export file ("json" or "csv")
    
    Returns:
        Dictionary with retrieved logs and export file path
    """
    # Set default time range if not provided
    if not end_time:
        end_time = datetime.utcnow()
    if not start_time:
        start_time = end_time - timedelta(hours=24)
    
    # Format times for API
    start_time_str = start_time.isoformat() + "Z"
    end_time_str = end_time.isoformat() + "Z"
    
    print(f"Retrieving audit logs from {start_time_str} to {end_time_str}")
    
    # Prepare filter parameters
    params = {
        "start_time": start_time_str,
        "end_time": end_time_str,
        "limit": limit
    }
    
    if event_types:
        params["event_types"] = event_types
    
    # If user email provided, find the user ID
    user_id = None
    if user_email:
        users = client.users.list()
        user = next((u for u in users if u.email.lower() == user_email.lower()), None)
        if user:
            user_id = user.id
            params["user_id"] = user_id
        else:
            print(f"Warning: User with email '{user_email}' not found, proceeding without user filter")
    
    if network_id:
        params["network_id"] = network_id
    
    # Retrieve logs
    logs = client.audit_logs.list(**params)
    
    print(f"Retrieved {len(logs)} audit log entries")
    
    # Format logs for better readability
    formatted_logs = []
    for log in logs:
        formatted_log = {
            "id": log.id,
            "event_type": log.event_type,
            "timestamp": log.timestamp,
            "user_id": log.user_id,
            "resource_type": log.resource_type,
            "resource_id": log.resource_id,
            "description": log.description,
            "ip_address": log.ip_address if hasattr(log, 'ip_address') else None,
            "metadata": log.metadata if hasattr(log, 'metadata') else {}
        }
        formatted_logs.append(formatted_log)
    
    # Export logs to file
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    
    if export_format.lower() == "json":
        export_file = f"audit_logs_{timestamp}.json"
        with open(export_file, 'w') as f:
            json.dump(formatted_logs, f, indent=2)
    else:  # CSV
        export_file = f"audit_logs_{timestamp}.csv"
        if formatted_logs:
            with open(export_file, 'w', newline='') as f:
                writer = csv.DictWriter(f, fieldnames=formatted_logs[0].keys())
                writer.writeheader()
                writer.writerows(formatted_logs)
        else:
            with open(export_file, 'w', newline='') as f:
                f.write("No audit logs found for the specified criteria")
    
    print(f"Exported audit logs to {export_file}")
    
    return {
        "logs": formatted_logs,
        "export_file": export_file,
        "filter_criteria": {
            "start_time": start_time_str,
            "end_time": end_time_str,
            "event_types": event_types,
            "user_email": user_email,
            "user_id": user_id,
            "network_id": network_id,
            "limit": limit
        }
    }

def generate_security_report(last_days=7):
    """
    Generate a security report summarizing important events over a period.
    
    Args:
        last_days: Number of days to include in the report
    
    Returns:
        Report data and export file path
    """
    # Calculate time range
    end_time = datetime.utcnow()
    start_time = end_time - timedelta(days=last_days)
    
    print(f"Generating security report for the last {last_days} days")
    
    # Get all users and networks for reference
    users = {u.id: u for u in client.users.list()}
    networks = {n.id: n for n in client.networks.list()}
    
    # Retrieve audit logs for the period
    params = {
        "start_time": start_time.isoformat() + "Z",
        "end_time": end_time.isoformat() + "Z",
        "limit": 5000  # Increase limit for comprehensive report
    }
    
    logs = client.audit_logs.list(**params)
    
    # Categorize logs by event type
    categorized_logs = {}
    for log in logs:
        event_type = log.event_type
        if event_type not in categorized_logs:
            categorized_logs[event_type] = []
        categorized_logs[event_type].append(log)
    
    # Initialize security metrics
    security_metrics = {
        "total_events": len(logs),
        "login_attempts": len(categorized_logs.get("LOGIN", [])),
        "failed_logins": len([l for l in categorized_logs.get("LOGIN_FAILED", []) or []]),
        "user_creations": len(categorized_logs.get("USER_CREATE", [])),
        "user_deletions": len(categorized_logs.get("USER_DELETE", [])),
        "profile_creations": len(categorized_logs.get("PROFILE_CREATE", [])),
        "profile_revocations": len(categorized_logs.get("PROFILE_DELETE", [])),
        "network_creations": len(categorized_logs.get("NETWORK_CREATE", [])),
        "network_updates": len(categorized_logs.get("NETWORK_UPDATE", [])),
        "network_deletions": len(categorized_logs.get("NETWORK_DELETE", [])),
        "period_start": start_time.isoformat(),
        "period_end": end_time.isoformat(),
        "generated_at": datetime.now().isoformat()
    }
    
    # Extract key security events
    security_events = []
    
    # Failed logins (potential security concern)
    for log in categorized_logs.get("LOGIN_FAILED", []) or []:
        user_info = "Unknown User"
        if hasattr(log, 'user_id') and log.user_id in users:
            user = users[log.user_id]
            user_info = f"{user.email} ({user.first_name} {user.last_name})"
        
        security_events.append({
            "type": "Failed Login",
            "timestamp": log.timestamp,
            "user": user_info,
            "ip_address": log.ip_address if hasattr(log, 'ip_address') else "Unknown",
            "details": log.description
        })
    
    # User deletions (audit for proper offboarding)
    for log in categorized_logs.get("USER_DELETE", []) or []:
        # For user deletions, the user_id may not be in users dict anymore
        user_info = log.resource_id or "Unknown User"
        if hasattr(log, 'user_id') and log.user_id in users:
            user = users[log.user_id]
            user_info = f"{user.email} ({user.first_name} {user.last_name})"
        
        security_events.append({
            "type": "User Deletion",
            "timestamp": log.timestamp,
            "user": user_info,
            "ip_address": log.ip_address if hasattr(log, 'ip_address') else "Unknown",
            "details": log.description
        })
    
    # Network accesses (track who can access what)
    for log in categorized_logs.get("NETWORK_ACCESS_CREATE", []) or []:
        user_info = "Unknown User"
        if hasattr(log, 'user_id') and log.user_id in users:
            user = users[log.user_id]
            user_info = f"{user.email} ({user.first_name} {user.last_name})"
        
        network_info = "Unknown Network"
        if hasattr(log, 'resource_id') and log.resource_id in networks:
            network = networks[log.resource_id]
            network_info = f"{network.name} ({network.id})"
            
        security_events.append({
            "type": "Network Access Granted",
            "timestamp": log.timestamp,
            "user": user_info,
            "network": network_info,
            "details": log.description
        })
    
    # Export the report
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    report_file = f"security_report_{timestamp}.json"
    
    report_data = {
        "security_metrics": security_metrics,
        "security_events": security_events
    }
    
    with open(report_file, 'w') as f:
        json.dump(report_data, f, indent=2)
    
    print(f"Generated security report: {report_file}")
    print(f"Summary: {security_metrics['total_events']} events, {security_metrics['failed_logins']} failed logins")
    
    return {
        "report_data": report_data,
        "report_file": report_file
    }

def monitor_connection_status(network_name=None):
    """
    Monitor the current connection status of VPN users.
    
    Args:
        network_name: Optional name of network to filter by
    
    Returns:
        Dictionary with connection statistics
    """
    # Get users and networks for reference
    users = {u.id: u for u in client.users.list()}
    
    # Get networks, optionally filtering by name
    networks = client.networks.list()
    if network_name:
        networks = [n for n in networks if n.name == network_name]
        if not networks:
            raise ValueError(f"Network '{network_name}' not found")
    
    # Store connection statistics
    connection_stats = {
        "total_users": len(users),
        "active_connections": 0,
        "networks": [],
        "timestamp": datetime.now().isoformat()
    }
    
    # Process each network
    for network in networks:
        # Get active connections for this network
        try:
            connections = client.connections.list(network_id=network.id)
            
            network_stats = {
                "network_id": network.id,
                "network_name": network.name,
                "total_connections": len(connections),
                "connections": []
            }
            
            # Process each connection
            for conn in connections:
                user_info = {
                    "user_id": conn.user_id,
                    "email": users[conn.user_id].email if conn.user_id in users else "Unknown",
                    "name": f"{users[conn.user_id].first_name} {users[conn.user_id].last_name}" if conn.user_id in users else "Unknown",
                    "connected_since": conn.connected_since if hasattr(conn, 'connected_since') else "Unknown",
                    "last_activity": conn.last_activity if hasattr(conn, 'last_activity') else "Unknown",
                    "ip_address": conn.virtual_ip if hasattr(conn, 'virtual_ip') else "Unknown",
                    "device": conn.device_name if hasattr(conn, 'device_name') else "Unknown",
                    "connection_id": conn.id
                }
                
                network_stats["connections"].append(user_info)
            
            connection_stats["active_connections"] += len(connections)
            connection_stats["networks"].append(network_stats)
            
        except Exception as e:
            print(f"Error retrieving connections for network {network.name}: {str(e)}")
    
    print(f"Active VPN connections: {connection_stats['active_connections']} across {len(connection_stats['networks'])} networks")
    
    return connection_stats

# Example 1: Retrieve recent audit logs
audit_result = retrieve_audit_logs(
    start_time=datetime.utcnow() - timedelta(days=3),
    export_format="csv"
)

# Example 2: Get security report for the last week
security_report = generate_security_report(last_days=7)

# Example 3: Monitor active connections
active_connections = monitor_connection_status(network_name="Corporate-Network")
for network in active_connections["networks"]:
    print(f"Network: {network['network_name']}")
    print(f"Active connections: {network['total_connections']}")
    for conn in network["connections"]:
        print(f"  - {conn['name']} ({conn['email']}) connected since {conn['connected_since']}")
```

This example demonstrates how to:
1. Retrieve and filter audit logs for specific time periods, users, or event types
2. Generate security reports that highlight important security events and metrics
3. Monitor active VPN connections across your networks

These operations are essential for security compliance, operational visibility, and troubleshooting. By automating audit log collection and analysis, you can maintain a robust security posture and quickly identify potential issues or anomalies in your VPN environment.

## 12. Identity Provider Integration and User Provisioning

Synchronizing users between your identity provider and Cloud Connexa is a common requirement for enterprise environments.

```python
from cloudconnexa import CloudConnexaClient
import os
import json
import csv
import requests
from datetime import datetime, timedelta

client = CloudConnexaClient(
    api_url=os.getenv("CLOUDCONNEXA_API_URL"),
    client_id=os.getenv("CLOUDCONNEXA_CLIENT_ID"),
    client_secret=os.getenv("CLOUDCONNEXA_CLIENT_SECRET")
)

def sync_users_from_scim_provider(scim_api_url, scim_api_token, default_role="member", default_groups=None):
    """
    Synchronize users from a SCIM-compatible identity provider (like Okta, Azure AD).
    
    Args:
        scim_api_url: Base URL for the SCIM API
        scim_api_token: API token for SCIM authentication
        default_role: Default role for new users
        default_groups: List of group names to add all users to
    
    Returns:
        Dictionary with synchronization results
    """
    print(f"Synchronizing users from SCIM provider: {scim_api_url}")
    
    # Get existing users from Cloud Connexa
    existing_users = client.users.list()
    email_to_user = {user.email.lower(): user for user in existing_users}
    
    # Get groups for mapping
    all_groups = client.user_groups.list()
    group_name_to_id = {group.name: group.id for group in all_groups}
    
    # Ensure default groups exist
    if default_groups:
        for group_name in default_groups:
            if group_name not in group_name_to_id:
                try:
                    group = client.user_groups.create(name=group_name)
                    group_name_to_id[group_name] = group.id
                    print(f"Created group: {group_name} (ID: {group.id})")
                except Exception as e:
                    print(f"Error creating group {group_name}: {str(e)}")
    
    # Retrieve users from SCIM provider
    headers = {
        "Authorization": f"Bearer {scim_api_token}",
        "Content-Type": "application/scim+json"
    }
    
    try:
        response = requests.get(f"{scim_api_url}/Users", headers=headers)
        response.raise_for_status()
        scim_data = response.json()
    except Exception as e:
        print(f"Error retrieving users from SCIM provider: {str(e)}")
        return {"error": str(e)}
    
    # Track synchronization results
    results = {
        "total_scim_users": 0,
        "users_created": [],
        "users_updated": [],
        "users_deactivated": [],
        "errors": []
    }
    
    # Process users from SCIM
    scim_emails = set()
    
    if "Resources" in scim_data:
        results["total_scim_users"] = len(scim_data["Resources"])
        
        for scim_user in scim_data["Resources"]:
            try:
                # Extract user information
                email = scim_user.get("emails", [{}])[0].get("value", "").lower()
                if not email:
                    results["errors"].append({"error": "Missing email", "user": scim_user.get("id")})
                    continue
                
                scim_emails.add(email)
                
                # Extract name information
                first_name = scim_user.get("name", {}).get("givenName", "")
                last_name = scim_user.get("name", {}).get("familyName", "")
                
                # Check if user is active
                is_active = scim_user.get("active", True)
                
                if email in email_to_user:
                    # User exists, update if needed
                    existing_user = email_to_user[email]
                    
                    # Check if user should be deactivated
                    if not is_active:
                        # In Cloud Connexa, we can delete or revoke access
                        # Here we'll choose to revoke network access instead of deleting
                        networks = client.networks.list()
                        for network in networks:
                            accesses = client.network_accesses.list(network_id=network.id)
                            for access in accesses:
                                if hasattr(access, 'user_id') and access.user_id == existing_user.id:
                                    client.network_accesses.delete(
                                        network_id=network.id,
                                        access_id=access.id
                                    )
                        
                        results["users_deactivated"].append({
                            "email": email,
                            "id": existing_user.id
                        })
                        print(f"Deactivated user: {email}")
                        continue
                    
                    # Update user information if changed
                    if existing_user.first_name != first_name or existing_user.last_name != last_name:
                        client.users.update(
                            user_id=existing_user.id,
                            first_name=first_name,
                            last_name=last_name
                        )
                        
                        results["users_updated"].append({
                            "email": email,
                            "id": existing_user.id
                        })
                        print(f"Updated user: {email}")
                    
                else:
                    # Create new user
                    if is_active:
                        new_user = client.users.create(
                            email=email,
                            first_name=first_name,
                            last_name=last_name,
                            role=default_role
                        )
                        
                        results["users_created"].append({
                            "email": email,
                            "id": new_user.id
                        })
                        print(f"Created user: {email}")
                        
                        # Add user to default groups
                        if default_groups:
                            for group_name in default_groups:
                                if group_name in group_name_to_id:
                                    try:
                                        client.user_groups.add_user(
                                            group_id=group_name_to_id[group_name],
                                            user_id=new_user.id
                                        )
                                    except Exception as e:
                                        print(f"Error adding {email} to group {group_name}: {str(e)}")
            
            except Exception as e:
                results["errors"].append({
                    "error": str(e),
                    "user": scim_user.get("id"),
                    "email": email if 'email' in locals() else "Unknown"
                })
    
    # Generate summary
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    summary_file = f"user_sync_summary_{timestamp}.json"
    
    with open(summary_file, 'w') as f:
        json.dump(results, f, indent=2)
    
    print(f"Synchronization complete: {len(results['users_created'])} created, "
          f"{len(results['users_updated'])} updated, {len(results['users_deactivated'])} deactivated")
    print(f"Summary saved to: {summary_file}")
    
    return results

def sync_users_from_csv(csv_file_path, email_column="email", first_name_column="first_name", 
                       last_name_column="last_name", groups_column=None, role_column=None,
                       default_role="member", default_groups=None, delete_missing=False):
    """
    Synchronize users from a CSV file, commonly exported from HR systems.
    
    Args:
        csv_file_path: Path to the CSV file with user data
        email_column: Name of the column containing email addresses
        first_name_column: Name of the column containing first names
        last_name_column: Name of the column containing last names
        groups_column: Optional name of column containing comma-separated group names
        role_column: Optional name of column containing user role
        default_role: Default role for new users
        default_groups: List of group names to add all users to
        delete_missing: Whether to delete users not in the CSV
    
    Returns:
        Dictionary with synchronization results
    """
    print(f"Synchronizing users from CSV file: {csv_file_path}")
    
    # Get existing users from Cloud Connexa
    existing_users = client.users.list()
    email_to_user = {user.email.lower(): user for user in existing_users}
    
    # Get groups for mapping
    all_groups = client.user_groups.list()
    group_name_to_id = {group.name: group.id for group in all_groups}
    
    # Ensure default groups exist
    if default_groups:
        for group_name in default_groups:
            if group_name not in group_name_to_id:
                try:
                    group = client.user_groups.create(name=group_name)
                    group_name_to_id[group_name] = group.id
                    print(f"Created group: {group_name} (ID: {group.id})")
                except Exception as e:
                    print(f"Error creating group {group_name}: {str(e)}")
    
    # Track synchronization results
    results = {
        "users_created": [],
        "users_updated": [],
        "users_deleted": [],
        "errors": []
    }
    
    # Process CSV file
    csv_emails = set()
    
    try:
        with open(csv_file_path, 'r', newline='') as csvfile:
            reader = csv.DictReader(csvfile)
            
            for row in reader:
                try:
                    # Extract user information
                    email = row.get(email_column, "").lower()
                    if not email:
                        results["errors"].append({"error": "Missing email", "row": row})
                        continue
                    
                    csv_emails.add(email)
                    
                    first_name = row.get(first_name_column, "")
                    last_name = row.get(last_name_column, "")
                    
                    # Determine role
                    role = default_role
                    if role_column and role_column in row and row[role_column]:
                        role = row[role_column]
                    
                    # Determine groups
                    user_groups = list(default_groups or [])
                    if groups_column and groups_column in row and row[groups_column]:
                        csv_groups = [g.strip() for g in row[groups_column].split(',')]
                        user_groups.extend([g for g in csv_groups if g])
                    
                    if email in email_to_user:
                        # User exists, update if needed
                        existing_user = email_to_user[email]
                        
                        # Update user information if changed
                        if (existing_user.first_name != first_name or 
                            existing_user.last_name != last_name or 
                            existing_user.role != role):
                            
                            client.users.update(
                                user_id=existing_user.id,
                                first_name=first_name,
                                last_name=last_name,
                                role=role
                            )
                            
                            results["users_updated"].append({
                                "email": email,
                                "id": existing_user.id
                            })
                            print(f"Updated user: {email}")
                        
                        # Process group memberships
                        if user_groups:
                            for group_name in user_groups:
                                if group_name in group_name_to_id:
                                    try:
                                        client.user_groups.add_user(
                                            group_id=group_name_to_id[group_name],
                                            user_id=existing_user.id
                                        )
                                    except Exception as e:
                                        # User might already be in the group
                                        pass
                    
                    else:
                        # Create new user
                        new_user = client.users.create(
                            email=email,
                            first_name=first_name,
                            last_name=last_name,
                            role=role
                        )
                        
                        results["users_created"].append({
                            "email": email,
                            "id": new_user.id
                        })
                        print(f"Created user: {email}")
                        
                        # Add user to groups
                        if user_groups:
                            for group_name in user_groups:
                                if group_name in group_name_to_id:
                                    try:
                                        client.user_groups.add_user(
                                            group_id=group_name_to_id[group_name],
                                            user_id=new_user.id
                                        )
                                    except Exception as e:
                                        print(f"Error adding {email} to group {group_name}: {str(e)}")
                
                except Exception as e:
                    results["errors"].append({
                        "error": str(e),
                        "row": row,
                        "email": email if 'email' in locals() else "Unknown"
                    })
    
    except Exception as e:
        print(f"Error processing CSV file: {str(e)}")
        return {"error": str(e)}
    
    # Handle users not in CSV
    if delete_missing:
        users_to_delete = [u for email, u in email_to_user.items() if email not in csv_emails]
        
        for user in users_to_delete:
            try:
                client.users.delete(user_id=user.id)
                
                results["users_deleted"].append({
                    "email": user.email,
                    "id": user.id
                })
                print(f"Deleted user not in CSV: {user.email}")
            
            except Exception as e:
                results["errors"].append({
                    "error": str(e),
                    "user_id": user.id,
                    "email": user.email
                })
    
    # Generate summary
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    summary_file = f"csv_sync_summary_{timestamp}.json"
    
    with open(summary_file, 'w') as f:
        json.dump(results, f, indent=2)
    
    print(f"CSV synchronization complete: {len(results['users_created'])} created, "
          f"{len(results['users_updated'])} updated, {len(results['users_deleted'])} deleted")
    print(f"Summary saved to: {summary_file}")
    
    return results

def provision_from_user_directory(api_url, api_token, department_to_group_mapping=None, default_groups=None):
    """
    Provision users from a generic user directory API.
    
    Args:
        api_url: URL for the user directory API endpoint
        api_token: Authentication token for the API
        department_to_group_mapping: Dict mapping departments to group names
        default_groups: List of default groups for all users
    
    Returns:
        Dictionary with provisioning results
    """
    print(f"Provisioning users from directory API: {api_url}")
    
    # Define headers for API request
    headers = {
        "Authorization": f"Bearer {api_token}",
        "Content-Type": "application/json"
    }
    
    # Get users from directory
    try:
        response = requests.get(api_url, headers=headers)
        response.raise_for_status()
        directory_users = response.json().get("users", [])
    except Exception as e:
        print(f"Error retrieving users from directory: {str(e)}")
        return {"error": str(e)}
    
    # Get existing Cloud Connexa users
    existing_users = client.users.list()
    email_to_user = {user.email.lower(): user for user in existing_users}
    
    # Get groups and create mapping for departments
    all_groups = client.user_groups.list()
    group_name_to_id = {group.name: group.id for group in all_groups}
    
    # Ensure all required groups exist
    required_groups = set(default_groups or [])
    if department_to_group_mapping:
        required_groups.update(department_to_group_mapping.values())
    
    for group_name in required_groups:
        if group_name and group_name not in group_name_to_id:
            try:
                group = client.user_groups.create(name=group_name)
                group_name_to_id[group_name] = group.id
                print(f"Created group: {group_name} (ID: {group.id})")
            except Exception as e:
                print(f"Error creating group {group_name}: {str(e)}")
    
    # Track results
    results = {
        "users_created": [],
        "users_updated": [],
        "errors": []
    }
    
    # Process directory users
    for user_data in directory_users:
        try:
            email = user_data.get("email", "").lower()
            if not email:
                results["errors"].append({"error": "Missing email", "user": user_data})
                continue
            
            first_name = user_data.get("firstName", "")
            last_name = user_data.get("lastName", "")
            department = user_data.get("department", "")
            
            # Determine which groups user should be in
            user_groups = list(default_groups or [])
            
            if department and department_to_group_mapping and department in department_to_group_mapping:
                dept_group = department_to_group_mapping[department]
                if dept_group:
                    user_groups.append(dept_group)
            
            if email in email_to_user:
                # Update existing user
                existing_user = email_to_user[email]
                
                if existing_user.first_name != first_name or existing_user.last_name != last_name:
                    client.users.update(
                        user_id=existing_user.id,
                        first_name=first_name,
                        last_name=last_name
                    )
                    
                    results["users_updated"].append({
                        "email": email,
                        "id": existing_user.id,
                        "groups": user_groups
                    })
                    print(f"Updated user: {email}")
                
                # Sync group membership
                if user_groups:
                    for group_name in user_groups:
                        if group_name in group_name_to_id:
                            try:
                                client.user_groups.add_user(
                                    group_id=group_name_to_id[group_name],
                                    user_id=existing_user.id
                                )
                            except Exception as e:
                                # User might already be in the group
                                pass
            
            else:
                # Create new user
                new_user = client.users.create(
                    email=email,
                    first_name=first_name,
                    last_name=last_name,
                    role="member"
                )
                
                results["users_created"].append({
                    "email": email,
                    "id": new_user.id,
                    "groups": user_groups
                })
                print(f"Created user: {email}")
                
                # Add to groups
                if user_groups:
                    for group_name in user_groups:
                        if group_name in group_name_to_id:
                            try:
                                client.user_groups.add_user(
                                    group_id=group_name_to_id[group_name],
                                    user_id=new_user.id
                                )
                            except Exception as e:
                                print(f"Error adding {email} to group {group_name}: {str(e)}")
        
        except Exception as e:
            results["errors"].append({
                "error": str(e),
                "user": user_data,
                "email": email if 'email' in locals() else "Unknown"
            })
    
    # Generate summary
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    summary_file = f"directory_sync_summary_{timestamp}.json"
    
    with open(summary_file, 'w') as f:
        json.dump(results, f, indent=2)
    
    print(f"Directory synchronization complete: {len(results['users_created'])} created, "
          f"{len(results['users_updated'])} updated")
    print(f"Summary saved to: {summary_file}")
    
    return results

# Example 1: Sync from a SCIM provider like Okta or Azure AD
scim_results = sync_users_from_scim_provider(
    scim_api_url="https://example.okta.com/scim/v2",
    scim_api_token="your_scim_api_token",
    default_groups=["All Users", "VPN Access"]
)

# Example 2: Sync from a CSV file (e.g., exported from HR system)
csv_results = sync_users_from_csv(
    csv_file_path="employees.csv",
    email_column="Email Address",
    first_name_column="First Name",
    last_name_column="Last Name",
    groups_column="Department",
    default_groups=["All Employees"],
    delete_missing=False
)

# Example 3: Provision from a custom user directory API
mapping = {
    "Engineering": "Engineering Team",
    "Sales": "Sales Team",
    "Marketing": "Marketing Team",
    "HR": "Human Resources"
}

directory_results = provision_from_user_directory(
    api_url="https://api.example.com/users",
    api_token="your_api_token",
    department_to_group_mapping=mapping,
    default_groups=["All Users"]
)
```

This example demonstrates how to:
1. Synchronize users from a SCIM-compatible identity provider like Okta or Azure Active Directory
2. Import users from a CSV file, which is commonly exported from HR systems
3. Provision users from a custom user directory API with department-based group mapping

These operations enable automated user lifecycle management, ensuring that your VPN user directory stays in sync with your organization's primary identity systems. By automating these processes, you can reduce administrative overhead and ensure users have appropriate access based on their organizational role or department.

## Conclusion

These examples cover the most common tasks developers need to perform with the Cloud Connexa API client. For more advanced usage scenarios, refer to the other example documents in this directory.

Each example is designed to be modular, allowing you to incorporate these patterns into your own applications and scripts. By following these patterns, you can efficiently manage your Cloud Connexa resources while following best practices for security and error handling. 