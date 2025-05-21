"""
Functional tests against the real Cloud Connexa API.

These tests verify the client library works with the actual API
and are intended to be run with valid credentials.
"""

import pytest
import os
from cloudconnexa import CloudConnexaClient

# TODO: Implement functional tests that connect to the real API:
# - test_authentication_flow
# - test_network_operations
# - test_user_operations
# - test_user_group_operations 
# - test_dns_operations
# - test_ip_service_operations

# Skip all tests if credentials are not available
pytestmark = pytest.mark.skipif(
    not os.environ.get("CLOUDCONNEXA_API_URL") or 
    not os.environ.get("CLOUDCONNEXA_CLIENT_ID") or 
    not os.environ.get("CLOUDCONNEXA_CLIENT_SECRET"),
    reason="API credentials not available"
)
