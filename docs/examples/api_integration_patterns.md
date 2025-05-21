# API Integration Patterns

This guide demonstrates how to integrate the Cloud Connexa API client into different application architectures and development scenarios.

## Overview

The Cloud Connexa client can be integrated into various application types. This guide provides reference implementations for common integration patterns to help you get started quickly.

## 1. RESTful Web Service Integration

Integrate the Cloud Connexa client with a Flask web service to provide VPN management capabilities.

```python
# app.py - Flask web service for VPN management
from flask import Flask, request, jsonify
from cloudconnexa import CloudConnexaClient
import os

app = Flask(__name__)

# Initialize Cloud Connexa client
client = CloudConnexaClient(
    api_url=os.getenv("CLOUDCONNEXA_API_URL"),
    client_id=os.getenv("CLOUDCONNEXA_CLIENT_ID"),
    client_secret=os.getenv("CLOUDCONNEXA_CLIENT_SECRET")
)

@app.route('/networks', methods=['GET'])
def list_networks():
    """List all networks"""
    try:
        networks = client.networks.list()
        return jsonify({
            'networks': [
                {
                    'id': network.id,
                    'name': network.name,
                    'status': network.status,
                    'created_at': network.created_at
                } for network in networks
            ]
        })
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/networks', methods=['POST'])
def create_network():
    """Create a new network"""
    data = request.json
    try:
        network = client.networks.create(
            name=data['name'],
            description=data.get('description', ''),
            internet_access=data.get('internet_access', 'split_tunnel_on'),
            egress=data.get('egress', True)
        )
        return jsonify({
            'id': network.id,
            'name': network.name,
            'status': network.status,
            'created_at': network.created_at
        }), 201
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/networks/<network_id>/connectors', methods=['GET'])
def list_connectors(network_id):
    """List connectors for a network"""
    try:
        connectors = client.connectors.list(network_id=network_id)
        return jsonify({
            'connectors': [
                {
                    'id': connector.id,
                    'name': connector.name,
                    'status': connector.status,
                    'created_at': connector.created_at
                } for connector in connectors
            ]
        })
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/users', methods=['GET'])
def list_users():
    """List all users"""
    try:
        users = client.users.list()
        return jsonify({
            'users': [
                {
                    'id': user.id,
                    'email': user.email,
                    'first_name': user.first_name,
                    'last_name': user.last_name
                } for user in users
            ]
        })
    except Exception as e:
        return jsonify({'error': str(e)}), 500

if __name__ == '__main__':
    app.run(debug=True)
```

## 2. Command-Line Interface (CLI) Tool

Create a command-line tool for administrators to manage VPN resources.

```python
#!/usr/bin/env python3
# vpn_cli.py - Command line interface for VPN management
import click
import os
import json
from cloudconnexa import CloudConnexaClient
from tabulate import tabulate

# Initialize client
client = CloudConnexaClient(
    api_url=os.getenv("CLOUDCONNEXA_API_URL"),
    client_id=os.getenv("CLOUDCONNEXA_CLIENT_ID"),
    client_secret=os.getenv("CLOUDCONNEXA_CLIENT_SECRET")
)

@click.group()
def cli():
    """Cloud Connexa CLI management tool"""
    pass

# Network commands
@cli.group()
def network():
    """Manage VPN networks"""
    pass

@network.command('list')
@click.option('--output', '-o', type=click.Choice(['table', 'json']), default='table',
              help='Output format')
def list_networks(output):
    """List all networks"""
    networks = client.networks.list()
    
    if output == 'json':
        click.echo(json.dumps([{
            'id': n.id,
            'name': n.name,
            'status': n.status,
            'created_at': n.created_at
        } for n in networks], indent=2))
    else:
        table_data = [[n.id, n.name, n.status, n.created_at] for n in networks]
        headers = ['ID', 'Name', 'Status', 'Created At']
        click.echo(tabulate(table_data, headers=headers, tablefmt='grid'))

@network.command('create')
@click.option('--name', '-n', required=True, help='Network name')
@click.option('--description', '-d', default='', help='Network description')
@click.option('--internet-access', '-i', 
              type=click.Choice(['split_tunnel_on', 'split_tunnel_off', 'tunnel_all']),
              default='split_tunnel_on', help='Internet access mode')
@click.option('--egress/--no-egress', default=True, help='Enable/disable egress')
def create_network(name, description, internet_access, egress):
    """Create a new network"""
    network = client.networks.create(
        name=name,
        description=description,
        internet_access=internet_access,
        egress=egress
    )
    
    click.echo(f"Network created successfully:")
    click.echo(f"ID: {network.id}")
    click.echo(f"Name: {network.name}")
    click.echo(f"Status: {network.status}")
    click.echo(f"Created At: {network.created_at}")

# User commands
@cli.group()
def user():
    """Manage VPN users"""
    pass

@user.command('list')
@click.option('--output', '-o', type=click.Choice(['table', 'json']), default='table',
              help='Output format')
def list_users(output):
    """List all users"""
    users = client.users.list()
    
    if output == 'json':
        click.echo(json.dumps([{
            'id': u.id,
            'email': u.email,
            'first_name': u.first_name,
            'last_name': u.last_name
        } for u in users], indent=2))
    else:
        table_data = [[u.id, u.email, u.first_name, u.last_name] for u in users]
        headers = ['ID', 'Email', 'First Name', 'Last Name']
        click.echo(tabulate(table_data, headers=headers, tablefmt='grid'))

@user.command('add')
@click.option('--email', '-e', required=True, help='User email')
@click.option('--first-name', '-f', required=True, help='First name')
@click.option('--last-name', '-l', required=True, help='Last name')
@click.option('--role', '-r', 
              type=click.Choice(['user', 'superuser', 'network-admin']),
              default='user', help='User role')
def add_user(email, first_name, last_name, role):
    """Add a new user"""
    user = client.users.create(
        email=email,
        first_name=first_name,
        last_name=last_name,
        role=role
    )
    
    click.echo(f"User added successfully:")
    click.echo(f"ID: {user.id}")
    click.echo(f"Email: {user.email}")
    click.echo(f"Name: {user.first_name} {user.last_name}")
    click.echo(f"Role: {user.role}")

if __name__ == '__main__':
    cli()
```

## 3. Serverless Function Integration (AWS Lambda)

Deploy Cloud Connexa management capabilities as serverless functions.

```python
# lambda_function.py - AWS Lambda for on-demand VPN user provisioning
import json
import os
import boto3
from cloudconnexa import CloudConnexaClient

# Initialize Cloud Connexa client
client = CloudConnexaClient(
    api_url=os.getenv("CLOUDCONNEXA_API_URL"),
    client_id=os.getenv("CLOUDCONNEXA_CLIENT_ID"),
    client_secret=os.getenv("CLOUDCONNEXA_CLIENT_SECRET")
)

# Initialize DynamoDB for user tracking
dynamodb = boto3.resource('dynamodb')
user_table = dynamodb.Table(os.getenv('USER_TABLE'))

def lambda_handler(event, context):
    """
    Lambda handler for VPN user provisioning.
    Expected event format:
    {
        "action": "provision_user",
        "user": {
            "email": "user@example.com",
            "first_name": "John",
            "last_name": "Doe",
            "groups": ["developers"]
        }
    }
    """
    try:
        # Extract action and data from event
        action = event.get('action')
        
        if action == 'provision_user':
            return provision_user(event.get('user', {}))
        elif action == 'revoke_user':
            return revoke_user(event.get('user', {}))
        elif action == 'list_users':
            return list_users()
        else:
            return {
                'statusCode': 400,
                'body': json.dumps({'error': f'Unsupported action: {action}'})
            }
            
    except Exception as e:
        print(f"Error: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps({'error': str(e)})
        }

def provision_user(user_data):
    """Provision a new VPN user"""
    # Check if user already exists
    existing_users = client.users.list()
    existing_user = next((u for u in existing_users if u.email == user_data.get('email')), None)
    
    if existing_user:
        # User exists, make sure they're in the right groups
        groups = user_data.get('groups', [])
        
        # Get all groups to find the IDs
        all_groups = client.user_groups.list()
        
        # Find group IDs for the requested groups
        group_ids = [g.id for g in all_groups if g.name in groups]
        
        # Update user's groups
        client.users.update(
            user_id=existing_user.id,
            group_ids=group_ids
        )
        
        result = {
            'id': existing_user.id,
            'email': existing_user.email,
            'status': 'updated',
            'groups': groups
        }
    else:
        # Create new user
        new_user = client.users.create(
            email=user_data.get('email'),
            first_name=user_data.get('first_name', ''),
            last_name=user_data.get('last_name', ''),
            role='user'
        )
        
        # Add user to groups if specified
        if 'groups' in user_data and user_data['groups']:
            # Get all groups to find the IDs
            all_groups = client.user_groups.list()
            
            # Find group IDs for the requested groups
            group_ids = [g.id for g in all_groups if g.name in user_data['groups']]
            
            # Update user's groups
            client.users.update(
                user_id=new_user.id,
                group_ids=group_ids
            )
        
        # Store user in DynamoDB for tracking
        user_table.put_item(
            Item={
                'user_id': new_user.id,
                'email': new_user.email,
                'first_name': new_user.first_name,
                'last_name': new_user.last_name,
                'provisioned_at': new_user.created_at
            }
        )
        
        result = {
            'id': new_user.id,
            'email': new_user.email,
            'status': 'created',
            'groups': user_data.get('groups', [])
        }
    
    return {
        'statusCode': 200,
        'body': json.dumps(result)
    }

def revoke_user(user_data):
    """Revoke a user's VPN access"""
    email = user_data.get('email')
    if not email:
        return {
            'statusCode': 400,
            'body': json.dumps({'error': 'Email is required'})
        }
    
    # Find user by email
    existing_users = client.users.list()
    existing_user = next((u for u in existing_users if u.email == email), None)
    
    if not existing_user:
        return {
            'statusCode': 404,
            'body': json.dumps({'error': f'User with email {email} not found'})
        }
    
    # Delete user
    client.users.delete(user_id=existing_user.id)
    
    # Remove from tracking database
    user_table.delete_item(
        Key={
            'user_id': existing_user.id
        }
    )
    
    return {
        'statusCode': 200,
        'body': json.dumps({
            'email': email,
            'status': 'revoked'
        })
    }

def list_users():
    """List all VPN users"""
    users = client.users.list()
    
    return {
        'statusCode': 200,
        'body': json.dumps({
            'users': [
                {
                    'id': user.id,
                    'email': user.email,
                    'first_name': user.first_name,
                    'last_name': user.last_name,
                    'role': user.role
                } for user in users
            ]
        })
    }
```

## 4. Event-Driven Integration with Message Queue

Create a worker that processes VPN management tasks from a message queue.

```python
# worker.py - Process VPN management tasks from a message queue
import json
import os
import time
from cloudconnexa import CloudConnexaClient
import pika

# Initialize Cloud Connexa client
client = CloudConnexaClient(
    api_url=os.getenv("CLOUDCONNEXA_API_URL"),
    client_id=os.getenv("CLOUDCONNEXA_CLIENT_ID"),
    client_secret=os.getenv("CLOUDCONNEXA_CLIENT_SECRET")
)

# Connect to RabbitMQ
connection = pika.BlockingConnection(
    pika.ConnectionParameters(
        host=os.getenv('RABBITMQ_HOST', 'localhost'),
        credentials=pika.PlainCredentials(
            os.getenv('RABBITMQ_USER', 'guest'),
            os.getenv('RABBITMQ_PASSWORD', 'guest')
        )
    )
)
channel = connection.channel()

# Declare queue
QUEUE_NAME = 'vpn_tasks'
channel.queue_declare(queue=QUEUE_NAME, durable=True)
print(f" [*] Waiting for messages in {QUEUE_NAME}. To exit press CTRL+C")

def callback(ch, method, properties, body):
    """Process task from message queue"""
    try:
        # Parse message
        message = json.loads(body)
        task_id = message.get('task_id')
        task_type = message.get('task_type')
        data = message.get('data', {})
        
        print(f" [x] Received {task_type} task {task_id}")
        
        # Process task based on type
        if task_type == 'create_network':
            result = create_network(data)
        elif task_type == 'create_connector':
            result = create_connector(data)
        elif task_type == 'add_user':
            result = add_user(data)
        elif task_type == 'add_routes':
            result = add_routes(data)
        else:
            result = {'error': f'Unknown task type: {task_type}'}
            
        # Publish result to result queue
        channel.basic_publish(
            exchange='',
            routing_key='vpn_results',
            body=json.dumps({
                'task_id': task_id,
                'status': 'completed' if 'error' not in result else 'failed',
                'result': result
            }),
            properties=pika.BasicProperties(
                delivery_mode=2,  # make message persistent
            )
        )
        
        print(f" [x] Completed task {task_id}")
        
    except Exception as e:
        print(f" [!] Error processing task: {str(e)}")
        # Publish error to result queue
        channel.basic_publish(
            exchange='',
            routing_key='vpn_results',
            body=json.dumps({
                'task_id': message.get('task_id', 'unknown'),
                'status': 'failed',
                'error': str(e)
            }),
            properties=pika.BasicProperties(
                delivery_mode=2,  # make message persistent
            )
        )
    
    # Acknowledge message
    ch.basic_ack(delivery_tag=method.delivery_tag)

def create_network(data):
    """Create a new network"""
    network = client.networks.create(
        name=data.get('name'),
        description=data.get('description', ''),
        internet_access=data.get('internet_access', 'split_tunnel_on'),
        egress=data.get('egress', True)
    )
    
    return {
        'id': network.id,
        'name': network.name,
        'status': network.status,
        'created_at': network.created_at
    }

def create_connector(data):
    """Create a new connector"""
    connector = client.connectors.create(
        network_id=data.get('network_id'),
        name=data.get('name'),
        vpn_region=data.get('vpn_region')
    )
    
    config = None
    if data.get('get_config', False):
        config_data = client.connectors.get_config(
            network_id=data.get('network_id'),
            connector_id=connector.id
        )
        config = config_data.config_text
    
    return {
        'id': connector.id,
        'name': connector.name,
        'status': connector.status,
        'created_at': connector.created_at,
        'config': config
    }

def add_user(data):
    """Add a new user"""
    user = client.users.create(
        email=data.get('email'),
        first_name=data.get('first_name', ''),
        last_name=data.get('last_name', ''),
        role=data.get('role', 'user')
    )
    
    # Add user to groups if specified
    if 'group_ids' in data and data['group_ids']:
        client.users.update(
            user_id=user.id,
            group_ids=data['group_ids']
        )
    
    return {
        'id': user.id,
        'email': user.email,
        'first_name': user.first_name,
        'last_name': user.last_name,
        'role': user.role
    }

def add_routes(data):
    """Add routes to a connector"""
    results = []
    
    for route_data in data.get('routes', []):
        route = client.routes.create(
            network_id=data.get('network_id'),
            connector_id=data.get('connector_id'),
            cidr=route_data.get('cidr'),
            description=route_data.get('description', '')
        )
        
        results.append({
            'id': route.id,
            'cidr': route.cidr,
            'description': route.description
        })
    
    return {'routes': results}

# Set up consumer
channel.basic_qos(prefetch_count=1)
channel.basic_consume(queue=QUEUE_NAME, on_message_callback=callback)

# Start consuming
try:
    channel.start_consuming()
except KeyboardInterrupt:
    channel.stop_consuming()

connection.close()
```

## 5. Microservices Architecture Integration

Implement a microservice for managing VPN infrastructure with gRPC.

```python
# vpn_service.py - gRPC service for VPN management
import grpc
import os
import time
import json
from concurrent import futures
from cloudconnexa import CloudConnexaClient
import vpn_pb2
import vpn_pb2_grpc

# Initialize Cloud Connexa client
client = CloudConnexaClient(
    api_url=os.getenv("CLOUDCONNEXA_API_URL"),
    client_id=os.getenv("CLOUDCONNEXA_CLIENT_ID"),
    client_secret=os.getenv("CLOUDCONNEXA_CLIENT_SECRET")
)

class VpnServiceServicer(vpn_pb2_grpc.VpnServiceServicer):
    """Implements the gRPC VPN service"""
    
    def ListNetworks(self, request, context):
        """List all networks"""
        try:
            networks = client.networks.list()
            
            response = vpn_pb2.NetworkList()
            for network in networks:
                network_pb = response.networks.add()
                network_pb.id = network.id
                network_pb.name = network.name
                network_pb.status = network.status
                network_pb.created_at = network.created_at
                
            return response
        except Exception as e:
            context.set_code(grpc.StatusCode.INTERNAL)
            context.set_details(str(e))
            return vpn_pb2.NetworkList()
    
    def CreateNetwork(self, request, context):
        """Create a new network"""
        try:
            network = client.networks.create(
                name=request.name,
                description=request.description,
                internet_access=request.internet_access,
                egress=request.egress
            )
            
            response = vpn_pb2.Network()
            response.id = network.id
            response.name = network.name
            response.status = network.status
            response.created_at = network.created_at
            
            return response
        except Exception as e:
            context.set_code(grpc.StatusCode.INTERNAL)
            context.set_details(str(e))
            return vpn_pb2.Network()
    
    def ListConnectors(self, request, context):
        """List connectors for a network"""
        try:
            connectors = client.connectors.list(network_id=request.network_id)
            
            response = vpn_pb2.ConnectorList()
            for connector in connectors:
                connector_pb = response.connectors.add()
                connector_pb.id = connector.id
                connector_pb.name = connector.name
                connector_pb.status = connector.status
                connector_pb.created_at = connector.created_at
                
            return response
        except Exception as e:
            context.set_code(grpc.StatusCode.INTERNAL)
            context.set_details(str(e))
            return vpn_pb2.ConnectorList()
    
    def CreateConnector(self, request, context):
        """Create a new connector"""
        try:
            connector = client.connectors.create(
                network_id=request.network_id,
                name=request.name,
                vpn_region=request.vpn_region
            )
            
            response = vpn_pb2.Connector()
            response.id = connector.id
            response.name = connector.name
            response.status = connector.status
            response.created_at = connector.created_at
            
            return response
        except Exception as e:
            context.set_code(grpc.StatusCode.INTERNAL)
            context.set_details(str(e))
            return vpn_pb2.Connector()
    
    def ListUsers(self, request, context):
        """List all users"""
        try:
            users = client.users.list()
            
            response = vpn_pb2.UserList()
            for user in users:
                user_pb = response.users.add()
                user_pb.id = user.id
                user_pb.email = user.email
                user_pb.first_name = user.first_name
                user_pb.last_name = user.last_name
                user_pb.role = user.role
                
            return response
        except Exception as e:
            context.set_code(grpc.StatusCode.INTERNAL)
            context.set_details(str(e))
            return vpn_pb2.UserList()
    
    def CreateUser(self, request, context):
        """Create a new user"""
        try:
            user = client.users.create(
                email=request.email,
                first_name=request.first_name,
                last_name=request.last_name,
                role=request.role
            )
            
            response = vpn_pb2.User()
            response.id = user.id
            response.email = user.email
            response.first_name = user.first_name
            response.last_name = user.last_name
            response.role = user.role
            
            return response
        except Exception as e:
            context.set_code(grpc.StatusCode.INTERNAL)
            context.set_details(str(e))
            return vpn_pb2.User()

def serve():
    """Start the gRPC server"""
    server = grpc.server(futures.ThreadPoolExecutor(max_workers=10))
    vpn_pb2_grpc.add_VpnServiceServicer_to_server(
        VpnServiceServicer(), server
    )
    server.add_insecure_port('[::]:50051')
    server.start()
    print("Server started on port 50051")
    server.wait_for_termination()

if __name__ == '__main__':
    serve()
```

## Conclusion

These integration patterns demonstrate how to incorporate the Cloud Connexa client into different application architectures. By leveraging these patterns, you can quickly build robust VPN management applications tailored to your specific requirements.

For more advanced usage, refer to the [automation and infrastructure as code guide](automation_iac.md) or the [security and troubleshooting guide](security_troubleshooting.md). 