# Getting Started with Cloud Connexa Python Client

Welcome to the Cloud Connexa Python Client! This guide will help you get up and running quickly.

## Quick Setup

For first-time users, we've made setup easy. Just run:

```bash
./start.sh
```

This script will:
1. Check prerequisites
2. Set up your development environment
3. Run tests to verify everything is working
4. Provide guidance on next steps

## Manual Setup

If you prefer to run the commands manually:

```bash
# Install dependencies and set up virtual environment
make setup

# Run tests to verify installation
make test
```

## Troubleshooting Common Issues

### Import Errors During Tests

If you see import errors like:
```
AttributeError: module 'src' has no attribute 'cloudconnexa'
```
or 
```
ImportError: cannot import name 'CloudConnexaClient'
```

This typically indicates an issue with the Python module structure. Check that:

1. The `src/cloudconnexa/__init__.py` file correctly imports the `CloudConnexaClient` class
2. The `CloudConnexaClient` class is defined in the expected location
3. Your environment was set up correctly with `make setup`

### Environment Setup Issues

If you encounter problems during `make setup`:

1. Ensure you have Python 3.6+ installed: `python3 --version`
2. On Debian/Ubuntu systems, you might need to install Python dev packages:
   ```bash
   sudo apt-get install python3-dev python3-venv
   ```
3. Check that you have pip installed and updated:
   ```bash
   python3 -m pip --version
   python3 -m pip install --upgrade pip
   ```

## Next Steps

After setting up:

1. **Read the documentation**: The `README.md` file contains comprehensive documentation and examples.
2. **Explore examples**: Check out the example code in `docs/examples/`.
3. **Set up API credentials**: Get your API credentials from the CloudConnexa Administration portal:
   - Log in to your Administration portal (e.g., `https://your-company.openvpn.com`)
   - Navigate to **API & Logs > API**
   - Click **Create Credentials**
   - Copy and securely store your Client ID and Client Secret
   - Enable the API using the toggle button

## Basic Usage

Here's a simple example to get you started:

```python
from cloudconnexa import CloudConnexaClient

# Initialize the client with your credentials
client = CloudConnexaClient(
    api_url="https://your-cloud-id.api.openvpn.com",
    client_id="your-client-id",
    client_secret="your-client-secret"
)

# List all networks
networks = client.networks.list()
print(f"Found {len(networks)} networks")

# Get user information
users = client.users.list()
print(f"Found {len(users)} users")
```

## Need Help?

- Check the **[Examples](docs/examples/README.md)** for guidance on common scenarios
- Refer to the **[API Documentation](docs/api/README.md)** for detailed API information
- Review the **[Architecture](docs/architecture/README.md)** for design decisions and patterns

Happy coding! 