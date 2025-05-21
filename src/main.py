#!/usr/bin/env python3
"""
Cloud Connexa Client Application Entry Point

This module serves as the main entry point for the Cloud Connexa client application.
It demonstrates basic usage of the CloudConnexaClient.
"""

import os
import argparse
import logging
from cloudconnexa import CloudConnexaClient

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s"
)
logger = logging.getLogger(__name__)


def parse_args():
    """Parse command-line arguments."""
    parser = argparse.ArgumentParser(description="Cloud Connexa Client")
    parser.add_argument(
        "--api-url",
        default=os.getenv("CLOUDCONNEXA_API_URL"),
        help="Cloud Connexa API URL (default: environment variable CLOUDCONNEXA_API_URL)"
    )
    parser.add_argument(
        "--client-id",
        default=os.getenv("CLOUDCONNEXA_CLIENT_ID"),
        help="Client ID (default: environment variable CLOUDCONNEXA_CLIENT_ID)"
    )
    parser.add_argument(
        "--client-secret",
        default=os.getenv("CLOUDCONNEXA_CLIENT_SECRET"),
        help="Client Secret (default: environment variable CLOUDCONNEXA_CLIENT_SECRET)"
    )
    parser.add_argument(
        "--verbose", "-v",
        action="store_true",
        help="Enable verbose output"
    )
    return parser.parse_args()


def main():
    """Main entry point for the application."""
    args = parse_args()
    
    # Set log level based on verbosity
    if args.verbose:
        logging.getLogger().setLevel(logging.DEBUG)
    
    # Validate required arguments
    if not all([args.api_url, args.client_id, args.client_secret]):
        logger.error("Missing required arguments. Please provide --api-url, --client-id, and --client-secret")
        logger.error("Alternatively, set the environment variables CLOUDCONNEXA_API_URL, CLOUDCONNEXA_CLIENT_ID, and CLOUDCONNEXA_CLIENT_SECRET")
        return 1
    
    # Initialize the client
    logger.info("Initializing Cloud Connexa client")
    client = CloudConnexaClient(
        api_url=args.api_url,
        client_id=args.client_id,
        client_secret=args.client_secret
    )
    
    # Authenticate
    logger.info("Authenticating with the Cloud Connexa API")
    if not client.authenticate():
        logger.error("Authentication failed")
        return 1
    
    logger.info("Authentication successful")
    logger.info(f"Using API version: {client.api_version}")
    
    # Example: List networks
    try:
        logger.info("Listing networks")
        networks = client.networks.list()
        logger.info(f"Found {len(networks)} networks")
        for network in networks:
            logger.info(f"Network: {network.name} (ID: {network.id})")
    except Exception as e:
        logger.error(f"Failed to list networks: {e}")
        return 1
    
    return 0


if __name__ == "__main__":
    exit(main()) 