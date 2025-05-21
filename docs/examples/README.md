# Cloud Connexa API Client Examples

This directory provides practical examples demonstrating how to effectively use the Cloud Connexa Python client for managing your VPN infrastructure.

## Quick Start Guide

Find solutions for common VPN management needs:

### User and Access Management

| I want to... | Example | Key Methods |
|--------------|---------|------------|
| Onboard a new employee | [User Onboarding](common_tasks.md#1-user-onboarding-workflow) | `client.users.create`, `client.user_groups.add_user` |
| Grant/revoke network access | [Access Control](common_tasks.md#9-vpn-access-control-management) | `client.network_accesses.create`, `client.network_accesses.delete` |
| Manage VPN client profiles | [Profile Management](common_tasks.md#10-vpn-client-profile-management) | `client.profiles.create`, `client.profiles.get_config` |
| Sync users from HR system | [Identity Integration](common_tasks.md#12-identity-provider-integration-and-user-provisioning) | `client.users.create`, `client.user_groups.add_user` |
| Implement emergency access controls | [Security Guide](security_troubleshooting.md#1-emergency-access-revocation) | `client.users.delete`, `client.network_accesses.delete` |

### Infrastructure Management

| I want to... | Example | Key Methods |
|--------------|---------|------------|
| Create a secure network | [Network Config](common_tasks.md#2-network-configuration-management) | `client.networks.create`, `client.networks.update` |
| Deploy VPN connectors | [Connector Setup](common_tasks.md#4-connector-deployment-and-configuration) | `client.connectors.create`, `client.connectors.get_config` |
| Configure network routes | [Route Management](common_tasks.md#5-route-management-and-dns-configuration) | `client.routes.create`, `client.routes.list` |
| Manage DNS records | [DNS Configuration](common_tasks.md#7-dns-record-management) | `client.dns.create`, `client.dns.update` |
| Automate with Terraform | [Infrastructure as Code](automation_iac.md#1-terraform-integration) | External data source patterns |

### Security and Operations

| I want to... | Example | Key Methods |
|--------------|---------|------------|
| Monitor active connections | [Audit & Monitoring](common_tasks.md#11-audit-logs-and-usage-monitoring) | `client.connections.list` |
| Set up security auditing | [Audit Logs](common_tasks.md#11-audit-logs-and-usage-monitoring) | `client.audit_logs.list` |
| Manage API credentials | [API Key Rotation](security_troubleshooting.md#2-api-key-rotation) | Token management |
| Implement high availability | [Disaster Recovery](disaster_recovery.md) | Multi-region architecture |
| Set up metrics collection | [Monitoring](monitoring_observability.md) | Prometheus integration |

### Integration Patterns

| I want to... | Example | Key Methods |
|--------------|---------|------------|
| Create a web service | [RESTful Integration](api_integration_patterns.md#1-restful-web-service-integration) | Flask/FastAPI endpoints |
| Build Slack-based access requests | [Slack Integration](slack_access_management.md) | Slack API + Cloud Connexa API |
| Create CLI tools | [Command Line Tools](api_integration_patterns.md#2-command-line-interface-cli-integration) | Click/Typer frameworks |
| Integrate with message queues | [Event-Driven Architecture](api_integration_patterns.md#4-event-driven-architecture-with-message-queues) | RabbitMQ, SQS patterns |
| Build serverless functions | [Serverless Integration](api_integration_patterns.md#3-serverless-function-integration) | AWS Lambda, Azure Functions |

## Common Developer Questions

### How do I authenticate to the API?

Use environment variables for secure credential handling:

```python
import os
from cloudconnexa import CloudConnexaClient

client = CloudConnexaClient(
    api_url=os.getenv("CLOUDCONNEXA_API_URL"),
    client_id=os.getenv("CLOUDCONNEXA_CLIENT_ID"),
    client_secret=os.getenv("CLOUDCONNEXA_CLIENT_SECRET")
)
```

See: [Authentication in Getting Started](../../README.md#authentication)

### How do I add users to my VPN?

For individual users:

```python
user = client.users.create(
    email="newuser@example.com",
    first_name="New",
    last_name="User",
    role="member"
)
```

For bulk user management, see: [User Onboarding](common_tasks.md#1-user-onboarding-workflow) or [Identity Integration](common_tasks.md#12-identity-provider-integration-and-user-provisioning)

### How do I generate VPN profiles for users?

```python
profile = client.profiles.create(
    user_id=user_id,
    network_id=network_id,
    name="Corporate-VPN"
)

# Get the configuration file contents
config = client.profiles.get_config(
    user_id=user_id,
    profile_id=profile.id
)
```

For more profile options, see: [Profile Management](common_tasks.md#10-vpn-client-profile-management)

### How do I monitor who is connected to the VPN?

```python
# List active connections on a network
connections = client.connections.list(network_id=network_id)

# See connection details
for conn in connections:
    print(f"User {conn.user_id} connected from {conn.public_ip}")
```

For more monitoring options, see: [Audit & Monitoring](common_tasks.md#11-audit-logs-and-usage-monitoring)

## Guide Categories

### Core VPN Management

- [**Common VPN Operations**](common_tasks.md) - Step-by-step examples of everyday tasks:
  - User onboarding and permissions management
  - Network creation and configuration
  - IP service management for access control
  - Connector deployment and route configuration
  - DNS record management
  - VPN access control and authorization
  - Client profile generation and management
  - Audit logs and security monitoring

### Integration Patterns

- [**API Integration Patterns**](api_integration_patterns.md) - Reference implementations for different architectures:
  - RESTful web service integration
  - Command-line interface tools
  - Serverless functions
  - Event-driven architectures with message queues
  - Microservices with gRPC

### Security and Operations

- [**Security and Troubleshooting**](security_troubleshooting.md) - Critical workflows for security:
  - Emergency access revocation
  - API key rotation
  - Security audit log collection
  - Network diagnostics
  - Policy enforcement

- [**Production-Grade Error Handling**](production_error_handling.md) - Error handling strategies:
  - Rate limiting and retry mechanisms
  - Graceful degradation
  - Comprehensive logging
  - Recovery procedures

- [**Disaster Recovery**](disaster_recovery.md) - Business continuity plans:
  - Multi-region architecture
  - Configuration backup/restore
  - Resilience patterns

### Automation and DevOps

- [**Infrastructure as Code**](automation_iac.md) - Integrations with DevOps tools:
  - Terraform integration
  - CI/CD pipeline integration
  - Ansible modules
  - Kubernetes operators

- [**Batch Operations**](batch_operations.md) - Efficiently managing multiple resources:
  - Bulk user management
  - Mass configuration updates
  - Error handling and rollback mechanisms

- [**Slack Integration**](slack_access_management.md) - Just-in-time access workflows:
  - Temporary VPN access provisioning
  - Access request approval workflows
  - Usage notifications

### Advanced Topics

- [**Monitoring and Observability**](monitoring_observability.md) - Metrics collection:
  - Prometheus integration
  - Logging best practices
  - Dashboard creation

- [**Connection Pooling**](connection_pooling.md) - Performance optimization:
  - Efficient client configuration
  - Resource management
  - High-throughput architectures

- [**Local Caching**](offline_operations.md) - Working with limited connectivity:
  - Offline read capabilities
  - Operation queuing
  - Conflict resolution

- [**API Versioning**](api_versioning.md) - Working with different API versions:
  - Version selection
  - Feature detection
  - Migration strategies

## Using These Examples

Each example is designed to be practical and ready-to-use. The code snippets are complete and include:

- Required imports
- Authentication setup
- Error handling
- Best practices

All examples follow the conventions documented in the [official Cloud Connexa API documentation](https://openvpn.net/cloud-docs/developer/cloudconnexa-api-v1-1-0.html). 