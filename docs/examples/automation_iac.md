# Automation and Infrastructure as Code with Cloud Connexa

This guide demonstrates how to use the Cloud Connexa API client in automation workflows and infrastructure as code (IaC) scenarios.

## Overview

Modern infrastructure management requires automation and infrastructure as code practices. This document provides patterns for integrating Cloud Connexa into DevOps workflows, CI/CD pipelines, and infrastructure provisioning systems.

## 1. Terraform Integration

Terraform is a popular IaC tool. Here's how to integrate Cloud Connexa with Terraform using the external data source.

```python
#!/usr/bin/env python3
# terraform_connector.py - Bridge between Terraform and Cloud Connexa API

import json
import sys
import os
from cloudconnexa import CloudConnexaClient

def process_terraform_command():
    """Process command from Terraform external data source"""
    # Read input from stdin (Terraform passes JSON)
    input_data = json.load(sys.stdin)
    
    # Get command and parameters
    command = input_data.get('command')
    params = input_data.get('params', {})
    
    # Initialize client
    client = CloudConnexaClient(
        api_url=os.getenv("CLOUDCONNEXA_API_URL"),
        client_id=os.getenv("CLOUDCONNEXA_CLIENT_ID"),
        client_secret=os.getenv("CLOUDCONNEXA_CLIENT_SECRET")
    )
    
    result = {}
    
    # Route to appropriate handler based on command
    if command == 'get_networks':
        result = get_networks(client)
    elif command == 'create_network':
        result = create_network(client, params)
    elif command == 'create_connector':
        result = create_connector(client, params)
    elif command == 'add_routes':
        result = add_routes(client, params)
    else:
        result = {"error": f"Unknown command: {command}"}
    
    # Output result as JSON for Terraform to read
    print(json.dumps(result))

def get_networks(client):
    """Get all networks for Terraform state"""
    networks = client.networks.list()
    return {
        "networks": [
            {
                "id": network.id,
                "name": network.name,
                "status": network.status,
                "created_at": network.created_at
            } for network in networks
        ]
    }

def create_network(client, params):
    """Create a network with parameters from Terraform"""
    try:
        network = client.networks.create(
            name=params.get('name'),
            description=params.get('description', f"Network created via Terraform"),
            internet_access=params.get('internet_access', 'split_tunnel_on'),
            egress=params.get('egress', True)
        )
        
        return {
            "id": network.id,
            "name": network.name,
            "status": network.status,
            "created_at": network.created_at
        }
    except Exception as e:
        return {"error": str(e)}

def create_connector(client, params):
    """Create a connector with parameters from Terraform"""
    try:
        connector = client.connectors.create(
            network_id=params.get('network_id'),
            name=params.get('name'),
            vpn_region=params.get('vpn_region')
        )
        
        # Optionally get connector configuration
        if params.get('export_config'):
            config = client.connectors.get_config(
                network_id=params.get('network_id'),
                connector_id=connector.id
            )
            
            # Save configuration to file if requested
            if params.get('config_path'):
                with open(params.get('config_path'), 'w') as f:
                    f.write(config.config_text)
        
        return {
            "id": connector.id,
            "name": connector.name,
            "status": connector.status,
            "created_at": connector.created_at
        }
    except Exception as e:
        return {"error": str(e)}

def add_routes(client, params):
    """Add routes to a connector from Terraform"""
    results = []
    error = None
    
    try:
        # Process each route in the list
        for route_data in params.get('routes', []):
            route = client.routes.create(
                network_id=params.get('network_id'),
                connector_id=params.get('connector_id'),
                cidr=route_data.get('cidr'),
                description=route_data.get('description', '')
            )
            
            results.append({
                "id": route.id,
                "cidr": route.cidr
            })
    except Exception as e:
        error = str(e)
    
    return {
        "routes": results,
        "error": error
    }

if __name__ == "__main__":
    process_terraform_command()
```

### Terraform Configuration Example

```hcl
# Example Terraform configuration using the Python bridge

data "external" "cloud_connexa_network" {
  program = ["python3", "${path.module}/terraform_connector.py"]
  query = {
    command = "create_network"
    params = jsonencode({
      name = "production-network"
      description = "Production VPN Network"
      internet_access = "split_tunnel_on"
      egress = true
    })
  }
}

data "external" "cloud_connexa_connector" {
  program = ["python3", "${path.module}/terraform_connector.py"]
  query = {
    command = "create_connector"
    params = jsonencode({
      network_id = data.external.cloud_connexa_network.result.id
      name = "datacenter-connector"
      vpn_region = "us-east-1"
      export_config = true
      config_path = "${path.module}/configs/connector-config.ovpn"
    })
  }
  
  depends_on = [data.external.cloud_connexa_network]
}

data "external" "cloud_connexa_routes" {
  program = ["python3", "${path.module}/terraform_connector.py"]
  query = {
    command = "add_routes"
    params = jsonencode({
      network_id = data.external.cloud_connexa_network.result.id
      connector_id = data.external.cloud_connexa_connector.result.id
      routes = [
        {
          cidr = "10.0.0.0/8"
          description = "Internal network"
        },
        {
          cidr = "172.16.0.0/12"
          description = "Development network"
        }
      ]
    })
  }
  
  depends_on = [data.external.cloud_connexa_connector]
}

output "network" {
  value = data.external.cloud_connexa_network.result
}

output "connector" {
  value = data.external.cloud_connexa_connector.result
}

output "routes" {
  value = data.external.cloud_connexa_routes.result
}
```

## 2. CI/CD Pipeline Integration

This example shows how to integrate Cloud Connexa into a CI/CD pipeline using GitHub Actions.

```yaml
# .github/workflows/deploy-vpn.yml

name: Deploy VPN Infrastructure

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]
  workflow_dispatch:

jobs:
  deploy-vpn:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      
      - name: Set up Python
        uses: actions/setup-python@v2
        with:
          python-version: '3.9'
      
      - name: Install dependencies
        run: |
          python -m pip install --upgrade pip
          pip install ovpn-connexa
      
      - name: Deploy VPN Infrastructure
        env:
          CLOUDCONNEXA_API_URL: ${{ secrets.CLOUDCONNEXA_API_URL }}
          CLOUDCONNEXA_CLIENT_ID: ${{ secrets.CLOUDCONNEXA_CLIENT_ID }}
          CLOUDCONNEXA_CLIENT_SECRET: ${{ secrets.CLOUDCONNEXA_CLIENT_SECRET }}
        run: |
          python deploy_vpn.py

      - name: Save connector configurations
        if: success()
        uses: actions/upload-artifact@v2
        with:
          name: connector-configs
          path: ./configs/*.ovpn
```

GitHub Actions deployment script:

```python
# deploy_vpn.py - CI/CD deployment script

import os
import json
import yaml
from cloudconnexa import CloudConnexaClient

# Load configuration from infrastructure YAML file
def load_infrastructure_config(file_path='infrastructure.yml'):
    with open(file_path, 'r') as f:
        return yaml.safe_load(f)

# Main deployment function
def deploy_vpn_infrastructure():
    # Initialize client
    client = CloudConnexaClient(
        api_url=os.getenv("CLOUDCONNEXA_API_URL"),
        client_id=os.getenv("CLOUDCONNEXA_CLIENT_ID"),
        client_secret=os.getenv("CLOUDCONNEXA_CLIENT_SECRET")
    )
    
    # Load infrastructure definition
    config = load_infrastructure_config()
    
    # Process each network defined in the configuration
    for network_config in config.get('networks', []):
        # Check if network already exists
        existing_networks = client.networks.list()
        existing_network = next((n for n in existing_networks 
                               if n.name == network_config['name']), None)
        
        if existing_network:
            print(f"Network {network_config['name']} already exists, updating...")
            network = client.networks.update(
                network_id=existing_network.id,
                **{k: v for k, v in network_config.items() if k != 'connectors'}
            )
        else:
            print(f"Creating network {network_config['name']}...")
            network = client.networks.create(
                **{k: v for k, v in network_config.items() if k != 'connectors'}
            )
        
        print(f"Network ID: {network.id}")
        
        # Process connectors for this network
        for connector_config in network_config.get('connectors', []):
            # Check if connector already exists
            existing_connectors = client.connectors.list(network_id=network.id)
            existing_connector = next((c for c in existing_connectors 
                                    if c.name == connector_config['name']), None)
            
            if existing_connector:
                print(f"Connector {connector_config['name']} already exists, skipping...")
                connector = existing_connector
            else:
                print(f"Creating connector {connector_config['name']}...")
                connector = client.connectors.create(
                    network_id=network.id,
                    **{k: v for k, v in connector_config.items() if k != 'routes'}
                )
            
            print(f"Connector ID: {connector.id}")
            
            # Export connector configuration
            config_dir = './configs'
            os.makedirs(config_dir, exist_ok=True)
            
            config = client.connectors.get_config(
                network_id=network.id,
                connector_id=connector.id
            )
            
            config_path = f"{config_dir}/{connector.name}-{connector.id}.ovpn"
            with open(config_path, 'w') as f:
                f.write(config.config_text)
            
            print(f"Saved connector configuration to {config_path}")
            
            # Process routes for this connector
            for route_config in connector_config.get('routes', []):
                # Check if route already exists
                existing_routes = client.routes.list(
                    network_id=network.id,
                    connector_id=connector.id
                )
                
                existing_route = next((r for r in existing_routes 
                                    if r.cidr == route_config['cidr']), None)
                
                if existing_route:
                    print(f"Route {route_config['cidr']} already exists, updating...")
                    client.routes.update(
                        network_id=network.id,
                        connector_id=connector.id,
                        route_id=existing_route.id,
                        **route_config
                    )
                else:
                    print(f"Creating route {route_config['cidr']}...")
                    client.routes.create(
                        network_id=network.id,
                        connector_id=connector.id,
                        **route_config
                    )

if __name__ == "__main__":
    deploy_vpn_infrastructure()
```

Infrastructure configuration file:

```yaml
# infrastructure.yml - Infrastructure as Code definition

networks:
  - name: prod-network
    description: Production VPN Network
    internet_access: split_tunnel_on
    egress: true
    connectors:
      - name: us-east-connector
        vpn_region: us-east-1
        routes:
          - cidr: 10.0.0.0/8
            description: Production internal network
          - cidr: 192.168.1.0/24
            description: Production DMZ
      
      - name: eu-west-connector
        vpn_region: eu-west-1
        routes:
          - cidr: 10.1.0.0/16
            description: EU production network
          - cidr: 192.168.2.0/24
            description: EU DMZ
  
  - name: dev-network
    description: Development VPN Network
    internet_access: split_tunnel_on
    egress: true
    connectors:
      - name: dev-connector
        vpn_region: us-west-1
        routes:
          - cidr: 172.16.0.0/12
            description: Development subnet
```

## 3. Ansible Integration

You can also use Cloud Connexa with Ansible for infrastructure automation.

```python
#!/usr/bin/env python3
# connexa_ansible_module.py

from ansible.module_utils.basic import AnsibleModule
import os
import sys
from cloudconnexa import CloudConnexaClient

def run_module():
    # Define module arguments
    module_args = dict(
        api_url=dict(type='str', required=True),
        client_id=dict(type='str', required=True),
        client_secret=dict(type='str', required=True, no_log=True),
        state=dict(type='str', default='present', choices=['present', 'absent']),
        resource_type=dict(type='str', required=True, 
                           choices=['network', 'connector', 'route', 'user', 'group']),
        resource_params=dict(type='dict', required=True),
        parent_resources=dict(type='dict', default=dict())
    )
    
    # Setup module
    module = AnsibleModule(
        argument_spec=module_args,
        supports_check_mode=True
    )
    
    # Initialize result dictionary
    result = dict(
        changed=False,
        resource=None,
        message=''
    )
    
    # Initialize client
    client = CloudConnexaClient(
        api_url=module.params['api_url'],
        client_id=module.params['client_id'],
        client_secret=module.params['client_secret']
    )
    
    # Handle resource operations based on resource_type
    resource_type = module.params['resource_type']
    resource_params = module.params['resource_params']
    parent_resources = module.params['parent_resources']
    state = module.params['state']
    
    try:
        if resource_type == 'network':
            handle_network(module, client, result, state, resource_params)
        elif resource_type == 'connector':
            handle_connector(module, client, result, state, resource_params, parent_resources)
        elif resource_type == 'route':
            handle_route(module, client, result, state, resource_params, parent_resources)
        elif resource_type == 'user':
            handle_user(module, client, result, state, resource_params)
        elif resource_type == 'group':
            handle_group(module, client, result, state, resource_params)
        
        # Return result
        module.exit_json(**result)
    
    except Exception as e:
        module.fail_json(msg=str(e), **result)

def handle_network(module, client, result, state, params):
    # Get existing networks
    networks = client.networks.list()
    
    # Look for existing network by name
    existing_network = next((n for n in networks if n.name == params['name']), None)
    
    if state == 'present':
        if existing_network:
            # Update existing network
            if not module.check_mode:
                network = client.networks.update(
                    network_id=existing_network.id,
                    **params
                )
                result['resource'] = {'id': network.id, 'name': network.name}
                result['message'] = f"Updated network: {network.name}"
            result['changed'] = True
        else:
            # Create new network
            if not module.check_mode:
                network = client.networks.create(**params)
                result['resource'] = {'id': network.id, 'name': network.name}
                result['message'] = f"Created network: {network.name}"
            result['changed'] = True
    
    elif state == 'absent' and existing_network:
        # Delete network
        if not module.check_mode:
            client.networks.delete(network_id=existing_network.id)
            result['message'] = f"Deleted network: {existing_network.name}"
        result['changed'] = True

def handle_connector(module, client, result, state, params, parent_resources):
    # Ensure network_id is provided
    network_id = parent_resources.get('network_id')
    if not network_id:
        module.fail_json(msg="network_id is required for connector operations")
    
    # Get existing connectors
    connectors = client.connectors.list(network_id=network_id)
    
    # Look for existing connector by name
    existing_connector = next((c for c in connectors if c.name == params['name']), None)
    
    if state == 'present':
        if existing_connector:
            # Connectors typically can't be updated, so we'll skip
            result['resource'] = {'id': existing_connector.id, 'name': existing_connector.name}
            result['message'] = f"Connector already exists: {existing_connector.name}"
        else:
            # Create new connector
            if not module.check_mode:
                connector = client.connectors.create(
                    network_id=network_id,
                    **params
                )
                result['resource'] = {'id': connector.id, 'name': connector.name}
                result['message'] = f"Created connector: {connector.name}"
            result['changed'] = True
    
    elif state == 'absent' and existing_connector:
        # Delete connector
        if not module.check_mode:
            client.connectors.delete(
                network_id=network_id,
                connector_id=existing_connector.id
            )
            result['message'] = f"Deleted connector: {existing_connector.name}"
        result['changed'] = True

def handle_route(module, client, result, state, params, parent_resources):
    # Ensure network_id and connector_id are provided
    network_id = parent_resources.get('network_id')
    connector_id = parent_resources.get('connector_id')
    if not network_id or not connector_id:
        module.fail_json(msg="network_id and connector_id are required for route operations")
    
    # Get existing routes
    routes = client.routes.list(
        network_id=network_id,
        connector_id=connector_id
    )
    
    # Look for existing route by CIDR
    existing_route = next((r for r in routes if r.cidr == params['cidr']), None)
    
    if state == 'present':
        if existing_route:
            # Update existing route
            if not module.check_mode:
                route = client.routes.update(
                    network_id=network_id,
                    connector_id=connector_id,
                    route_id=existing_route.id,
                    **params
                )
                result['resource'] = {'id': route.id, 'cidr': route.cidr}
                result['message'] = f"Updated route: {route.cidr}"
            result['changed'] = True
        else:
            # Create new route
            if not module.check_mode:
                route = client.routes.create(
                    network_id=network_id,
                    connector_id=connector_id,
                    **params
                )
                result['resource'] = {'id': route.id, 'cidr': route.cidr}
                result['message'] = f"Created route: {route.cidr}"
            result['changed'] = True
    
    elif state == 'absent' and existing_route:
        # Delete route
        if not module.check_mode:
            client.routes.delete(
                network_id=network_id,
                connector_id=connector_id,
                route_id=existing_route.id
            )
            result['message'] = f"Deleted route: {existing_route.cidr}"
        result['changed'] = True

def handle_user(module, client, result, state, params):
    # Get existing users
    users = client.users.list()
    
    # Look for existing user by email
    existing_user = next((u for u in users if u.email == params['email']), None)
    
    if state == 'present':
        if existing_user:
            # Update existing user
            if not module.check_mode:
                user = client.users.update(
                    user_id=existing_user.id,
                    **{k: v for k, v in params.items() if k != 'email'}
                )
                result['resource'] = {'id': user.id, 'email': user.email}
                result['message'] = f"Updated user: {user.email}"
            result['changed'] = True
        else:
            # Create new user
            if not module.check_mode:
                user = client.users.create(**params)
                result['resource'] = {'id': user.id, 'email': user.email}
                result['message'] = f"Created user: {user.email}"
            result['changed'] = True
    
    elif state == 'absent' and existing_user:
        # Delete user
        if not module.check_mode:
            client.users.delete(user_id=existing_user.id)
            result['message'] = f"Deleted user: {existing_user.email}"
        result['changed'] = True

def handle_group(module, client, result, state, params):
    # Get existing groups
    groups = client.user_groups.list()
    
    # Look for existing group by name
    existing_group = next((g for g in groups if g.name == params['name']), None)
    
    if state == 'present':
        if existing_group:
            # Update existing group
            if not module.check_mode:
                group = client.user_groups.update(
                    group_id=existing_group.id,
                    **params
                )
                result['resource'] = {'id': group.id, 'name': group.name}
                result['message'] = f"Updated group: {group.name}"
            result['changed'] = True
        else:
            # Create new group
            if not module.check_mode:
                group = client.user_groups.create(**params)
                result['resource'] = {'id': group.id, 'name': group.name}
                result['message'] = f"Created group: {group.name}"
            result['changed'] = True
    
    elif state == 'absent' and existing_group:
        # Delete group
        if not module.check_mode:
            client.user_groups.delete(group_id=existing_group.id)
            result['message'] = f"Deleted group: {existing_group.name}"
        result['changed'] = True

if __name__ == '__main__':
    run_module()
```

Example Ansible playbook:

```yaml
# deploy_vpn.yml - Ansible playbook

---
- name: Deploy Cloud Connexa VPN Infrastructure
  hosts: localhost
  gather_facts: no
  
  vars_files:
    - vars/connexa_credentials.yml
  
  tasks:
    - name: Create Production Network
      connexa_ansible_module:
        api_url: "{{ connexa_api_url }}"
        client_id: "{{ connexa_client_id }}"
        client_secret: "{{ connexa_client_secret }}"
        state: present
        resource_type: network
        resource_params:
          name: "production-network"
          description: "Production VPN Network"
          internet_access: "split_tunnel_on"
          egress: true
      register: prod_network
      
    - name: Create Production Connector
      connexa_ansible_module:
        api_url: "{{ connexa_api_url }}"
        client_id: "{{ connexa_client_id }}"
        client_secret: "{{ connexa_client_secret }}"
        state: present
        resource_type: connector
        parent_resources:
          network_id: "{{ prod_network.resource.id }}"
        resource_params:
          name: "prod-connector-1"
          vpn_region: "us-east-1"
      register: prod_connector
      
    - name: Add Routes to Production Connector
      connexa_ansible_module:
        api_url: "{{ connexa_api_url }}"
        client_id: "{{ connexa_client_id }}"
        client_secret: "{{ connexa_client_secret }}"
        state: present
        resource_type: route
        parent_resources:
          network_id: "{{ prod_network.resource.id }}"
          connector_id: "{{ prod_connector.resource.id }}"
        resource_params:
          cidr: "10.0.0.0/8"
          description: "Production internal network"
```

## 4. Kubernetes Operator Integration

For Kubernetes environments, you can create a Custom Resource Definition (CRD) and operator to manage Cloud Connexa resources.

```python
# This is a simplified example of a Kubernetes operator for Cloud Connexa
# In a real-world scenario, you would use frameworks like Kopf or Operator SDK

import os
import time
import yaml
import kubernetes
from kubernetes import client, config, watch
from cloudconnexa import CloudConnexaClient

# Initialize Kubernetes client
config.load_incluster_config()  # When running inside a Kubernetes pod
custom_api = client.CustomObjectsApi()

# Initialize Cloud Connexa client
connexa_client = CloudConnexaClient(
    api_url=os.getenv("CLOUDCONNEXA_API_URL"),
    client_id=os.getenv("CLOUDCONNEXA_CLIENT_ID"),
    client_secret=os.getenv("CLOUDCONNEXA_CLIENT_SECRET")
)

# Constants
GROUP = "connexa.example.com"
VERSION = "v1"
NETWORK_PLURAL = "connexanetworks"
CONNECTOR_PLURAL = "connexaconnectors"
NAMESPACE = "default"

def main():
    """Main operator loop."""
    # Watch for changes to the custom resources
    watcher = watch.Watch()
    
    while True:
        try:
            # Watch network resources
            for event in watcher.stream(
                custom_api.list_namespaced_custom_object,
                group=GROUP,
                version=VERSION,
                namespace=NAMESPACE,
                plural=NETWORK_PLURAL
            ):
                handle_network_event(event)
            
            # Watch connector resources
            for event in watcher.stream(
                custom_api.list_namespaced_custom_object,
                group=GROUP,
                version=VERSION,
                namespace=NAMESPACE,
                plural=CONNECTOR_PLURAL
            ):
                handle_connector_event(event)
                
        except Exception as e:
            print(f"Error in watch loop: {e}")
            time.sleep(5)  # Wait before reconnecting

def handle_network_event(event):
    """Handle events for ConexaNetwork resources."""
    event_type = event['type']
    network_obj = event['object']
    network_name = network_obj['metadata']['name']
    network_spec = network_obj['spec']
    
    print(f"Processing {event_type} event for network {network_name}")
    
    try:
        if event_type == "ADDED" or event_type == "MODIFIED":
            # Check if network exists
            existing_networks = connexa_client.networks.list()
            existing_network = next((n for n in existing_networks if n.name == network_name), None)
            
            if existing_network:
                # Update network
                print(f"Updating network {network_name}")
                network = connexa_client.networks.update(
                    network_id=existing_network.id,
                    name=network_name,
                    description=network_spec.get('description', ''),
                    internet_access=network_spec.get('internetAccess', 'split_tunnel_on'),
                    egress=network_spec.get('egress', True)
                )
            else:
                # Create network
                print(f"Creating network {network_name}")
                network = connexa_client.networks.create(
                    name=network_name,
                    description=network_spec.get('description', ''),
                    internet_access=network_spec.get('internetAccess', 'split_tunnel_on'),
                    egress=network_spec.get('egress', True)
                )
            
            # Update status in the custom resource
            patch_status = {
                "status": {
                    "id": network.id,
                    "state": network.status,
                    "created": network.created_at
                }
            }
            
            custom_api.patch_namespaced_custom_object_status(
                group=GROUP,
                version=VERSION,
                namespace=NAMESPACE,
                plural=NETWORK_PLURAL,
                name=network_name,
                body=patch_status
            )
        
        elif event_type == "DELETED":
            # Delete network if it exists
            existing_networks = connexa_client.networks.list()
            existing_network = next((n for n in existing_networks if n.name == network_name), None)
            
            if existing_network:
                print(f"Deleting network {network_name}")
                connexa_client.networks.delete(network_id=existing_network.id)
    
    except Exception as e:
        print(f"Error handling network event: {e}")

def handle_connector_event(event):
    """Handle events for ConexaConnector resources."""
    event_type = event['type']
    connector_obj = event['object']
    connector_name = connector_obj['metadata']['name']
    connector_spec = connector_obj['spec']
    
    # Get network ID from spec
    network_name = connector_spec.get('networkName')
    if not network_name:
        print(f"Error: networkName not specified for connector {connector_name}")
        return
    
    print(f"Processing {event_type} event for connector {connector_name} in network {network_name}")
    
    try:
        # Find network ID
        existing_networks = connexa_client.networks.list()
        network = next((n for n in existing_networks if n.name == network_name), None)
        
        if not network:
            print(f"Error: Network {network_name} not found for connector {connector_name}")
            return
        
        if event_type == "ADDED" or event_type == "MODIFIED":
            # Check if connector exists
            existing_connectors = connexa_client.connectors.list(network_id=network.id)
            existing_connector = next((c for c in existing_connectors if c.name == connector_name), None)
            
            if existing_connector:
                # Connectors typically can't be updated, so we'll just use the existing one
                connector = existing_connector
                print(f"Connector {connector_name} already exists, skipping update.")
            else:
                # Create connector
                print(f"Creating connector {connector_name}")
                connector = connexa_client.connectors.create(
                    network_id=network.id,
                    name=connector_name,
                    vpn_region=connector_spec.get('vpnRegion', 'us-east-1')
                )
            
            # Process routes if specified
            if 'routes' in connector_spec:
                for route_spec in connector_spec['routes']:
                    # Check if route exists
                    existing_routes = connexa_client.routes.list(
                        network_id=network.id,
                        connector_id=connector.id
                    )
                    existing_route = next((r for r in existing_routes if r.cidr == route_spec['cidr']), None)
                    
                    if existing_route:
                        # Update route
                        print(f"Updating route {route_spec['cidr']}")
                        connexa_client.routes.update(
                            network_id=network.id,
                            connector_id=connector.id,
                            route_id=existing_route.id,
                            cidr=route_spec['cidr'],
                            description=route_spec.get('description', '')
                        )
                    else:
                        # Create route
                        print(f"Creating route {route_spec['cidr']}")
                        connexa_client.routes.create(
                            network_id=network.id,
                            connector_id=connector.id,
                            cidr=route_spec['cidr'],
                            description=route_spec.get('description', '')
                        )
            
            # Update status in the custom resource
            patch_status = {
                "status": {
                    "id": connector.id,
                    "state": connector.status,
                    "networkId": network.id,
                    "created": connector.created_at
                }
            }
            
            custom_api.patch_namespaced_custom_object_status(
                group=GROUP,
                version=VERSION,
                namespace=NAMESPACE,
                plural=CONNECTOR_PLURAL,
                name=connector_name,
                body=patch_status
            )
        
        elif event_type == "DELETED":
            # Delete connector if it exists
            existing_connectors = connexa_client.connectors.list(network_id=network.id)
            existing_connector = next((c for c in existing_connectors if c.name == connector_name), None)
            
            if existing_connector:
                print(f"Deleting connector {connector_name}")
                connexa_client.connectors.delete(
                    network_id=network.id,
                    connector_id=existing_connector.id
                )
    
    except Exception as e:
        print(f"Error handling connector event: {e}")

if __name__ == "__main__":
    main()
```

Example Kubernetes CRD definitions:

```yaml
# connexa-network-crd.yaml
apiVersion: apiextensions.k8s.io/v1
kind: CustomResourceDefinition
metadata:
  name: connexanetworks.connexa.example.com
spec:
  group: connexa.example.com
  names:
    kind: ConnexaNetwork
    plural: connexanetworks
    singular: connexanetwork
    shortNames:
      - cxnet
  scope: Namespaced
  versions:
    - name: v1
      served: true
      storage: true
      schema:
        openAPIV3Schema:
          type: object
          properties:
            spec:
              type: object
              properties:
                description:
                  type: string
                internetAccess:
                  type: string
                  enum: ['split_tunnel_on', 'split_tunnel_off', 'tunnel_all']
                egress:
                  type: boolean
              required:
                - internetAccess
            status:
              type: object
              properties:
                id:
                  type: string
                state:
                  type: string
                created:
                  type: string
      subresources:
        status: {}
```

```yaml
# connexa-connector-crd.yaml
apiVersion: apiextensions.k8s.io/v1
kind: CustomResourceDefinition
metadata:
  name: connexaconnectors.connexa.example.com
spec:
  group: connexa.example.com
  names:
    kind: ConnexaConnector
    plural: connexaconnectors
    singular: connexaconnector
    shortNames:
      - cxconn
  scope: Namespaced
  versions:
    - name: v1
      served: true
      storage: true
      schema:
        openAPIV3Schema:
          type: object
          properties:
            spec:
              type: object
              properties:
                networkName:
                  type: string
                vpnRegion:
                  type: string
                routes:
                  type: array
                  items:
                    type: object
                    properties:
                      cidr:
                        type: string
                      description:
                        type: string
                    required:
                      - cidr
              required:
                - networkName
                - vpnRegion
            status:
              type: object
              properties:
                id:
                  type: string
                state:
                  type: string
                networkId:
                  type: string
                created:
                  type: string
      subresources:
        status: {}
```

Example custom resources:

```yaml
# example-network.yaml
apiVersion: connexa.example.com/v1
kind: ConnexaNetwork
metadata:
  name: production-network
spec:
  description: "Production VPN Network"
  internetAccess: "split_tunnel_on"
  egress: true
```

```yaml
# example-connector.yaml
apiVersion: connexa.example.com/v1
kind: ConnexaConnector
metadata:
  name: prod-connector-1
spec:
  networkName: production-network
  vpnRegion: us-east-1
  routes:
    - cidr: 10.0.0.0/8
      description: "Production internal network"
    - cidr: 192.168.1.0/24
      description: "Production DMZ"
```

## Conclusion

These examples demonstrate how to integrate Cloud Connexa VPN management into various DevOps and IaC workflows. By automating VPN infrastructure deployment and management, you can ensure consistency, reduce manual errors, and seamlessly integrate your VPN infrastructure into your CI/CD pipelines and infrastructure provisioning systems. 