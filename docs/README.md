# Cloud Connexa Python Client Documentation

This directory contains comprehensive documentation for the Cloud Connexa Python client, designed to help developers understand and use the client effectively.

## Documentation Structure

```
docs/
├── examples/            # Usage examples for common scenarios
│   ├── README.md        # Index of examples
│   ├── api_versioning.md # API version handling examples
│   ├── common_tasks.md  # Examples for common VPN tasks
│   └── ...
├── testing/             # Testing documentation and strategies
│   ├── dns_tests.md     # DNS-specific testing
│   ├── user_group_tests.md # User Group testing
│   ├── ip_service_tests.md # IP Service testing
│   ├── version_compatibility_tests.md # Version compatibility testing
│   └── ...
└── planning/            # Project planning documents
    ├── README.md        # Main planning document
    ├── plan_ph1.md      # Phase 1: Core Infrastructure
    ├── plan_ph2.md      # Phase 2: Basic API Services
    ├── plan_ph3.md      # Phase 3: Advanced Features
    ├── plan_ph4.md      # Phase 4: v1.1.0 Features
    ├── plan_ph5.md      # Phase 5: Final Testing & Review
    └── migration_v1_to_v110.md # Migration guide for API versions
```

## Key Documentation Resources

### For Developers

- [Examples README](examples/README.md) - Start here for practical code examples
- [Common Tasks](examples/common_tasks.md) - Find solutions for common VPN management tasks
- [API Versioning Guide](examples/api_versioning.md) - Learn how to work with different API versions

### For Contributors

- [Project Plan](planning/README.md) - Understand the project structure and phases
- [Version Compatibility Tests](testing/version_compatibility_tests.md) - See how we test compatibility
- [Migration Guide](planning/migration_v1_to_v110.md) - Detailed guide on v1.0 to v1.1.0 differences

## API Version Compatibility

The Cloud Connexa Python client supports both v1.0 and v1.1.0 of the API. Key differences between versions include:

1. **Single Resource Endpoints** (v1.1.0) - Direct access to individual DNS records and User Groups
2. **Simplified IP Service DTO** (v1.1.0) - Removal of routing information
3. **Performance Improvements** (v1.1.0) - Optimized endpoint responses

Our client library handles these differences transparently, providing a consistent interface regardless of the API version in use. For detailed information on how this works, see:

- [Migration Guide](planning/migration_v1_to_v110.md)
- [Version Compatibility Tests](testing/version_compatibility_tests.md)
- [API Versioning Examples](examples/api_versioning.md)

## Documentation Standards

All documentation follows these standards:

1. **Code Examples** - Every feature includes practical code examples
2. **Version Information** - All examples note any version-specific behavior
3. **Error Handling** - Examples show appropriate error handling
4. **Consistent Style** - Documentation uses consistent formatting and style
5. **Task-Oriented** - Documentation is organized around common tasks 