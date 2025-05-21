"""
Version detector for the Cloud Connexa API.

This module provides functionality to detect which API version is available
on the server and handles fallback to older versions when necessary.
"""
import logging
from typing import Optional, Union

import requests
from requests.exceptions import RequestException

logger = logging.getLogger(__name__)


class VersionDetector:
    """Detects and manages API version compatibility.
    
    This class handles detection of the available API version and provides
    methods to check compatibility for specific features.
    """
    
    def __init__(self, api_url: str, request_session: Optional[requests.Session] = None):
        """Initialize the version detector.
        
        Args:
            api_url: Base URL for the API
            request_session: Optional requests session for API calls
        """
        self.api_url = api_url
        self.session = request_session or requests.Session()
        
    def detect_version(self, preferred_version: Optional[str] = None) -> str:
        """Detect the available API version.
        
        Args:
            preferred_version: Optional version to use, bypassing detection
            
        Returns:
            str: Detected API version ("1.0" or "1.1.0")
        """
        # If a specific version is requested, use that
        if preferred_version in ["1.0", "1.1.0"]:
            logger.info(f"Using explicitly requested API version: {preferred_version}")
            return preferred_version
            
        # Try to use v1.1.0 first
        try:
            response = self._request("GET", "/api/v1.1.0/version")
            if response.status_code == 200:
                logger.info("Detected API version 1.1.0")
                return "1.1.0"
        except RequestException as e:
            logger.debug(f"Error detecting v1.1.0: {e}")
            
        # Fall back to v1.0
        logger.info("Falling back to API version 1.0")
        return "1.0"
    
    def _request(self, method: str, path: str, **kwargs) -> requests.Response:
        """Make a request to the API.
        
        Args:
            method: HTTP method
            path: API path
            **kwargs: Additional arguments for requests
            
        Returns:
            Response: HTTP response
        """
        url = f"{self.api_url.rstrip('/')}{path}"
        return self.session.request(method, url, **kwargs)
        
    def supports_feature(self, feature_name: str, current_version: str) -> bool:
        """Check if the current API version supports a specific feature.
        
        Args:
            feature_name: Name of the feature to check
            current_version: Current API version
            
        Returns:
            bool: True if the feature is supported
        """
        # Define feature compatibility matrix
        feature_matrix = {
            "dns_single_record": ["1.1.0"],
            "user_group_single": ["1.1.0"],
            "ip_service_without_routing": ["1.1.0"],
            "dns_list": ["1.0", "1.1.0"],
            "user_group_list": ["1.0", "1.1.0"],
            "ip_service_list": ["1.0", "1.1.0"],
        }
        
        # Check if feature exists and is supported
        if feature_name in feature_matrix:
            return current_version in feature_matrix[feature_name]
        
        # Unknown features are assumed not supported
        logger.warning(f"Unknown feature: {feature_name}")
        return False


def get_api_version(
    api_url: str, 
    explicit_version: Optional[str] = None,
    session: Optional[requests.Session] = None
) -> str:
    """Convenience function to detect API version.
    
    Args:
        api_url: Base URL for the API
        explicit_version: Optional explicit version to use
        session: Optional requests session
        
    Returns:
        str: Detected API version
    """
    detector = VersionDetector(api_url, session)
    return detector.detect_version(explicit_version)
