import logging
from typing import Any, Dict, List, Optional
from cloudconnexa.utils.errors import APIError, ResourceNotFoundError, ValidationError, RateLimitError
from datetime import datetime

logger = logging.getLogger(__name__)

def parse_datetime(value):
    if isinstance(value, str):
        try:
            # Handle Zulu time
            if value.endswith('Z'):
                value = value[:-1] + '+00:00'
            return datetime.fromisoformat(value)
        except Exception:
            return value
    return value

class Network:
    def __init__(self, **kwargs):
        for k, v in kwargs.items():
            if k in ("created_at", "updated_at"):
                setattr(self, k, parse_datetime(v))
            else:
                setattr(self, k, v)

class NetworkService:
    def __init__(self, client):
        self.client = client

    def _default_pagination(self, total: int = 0, per_page: int = 0) -> Dict[str, Any]:
        return {"total": total, "page": 1, "per_page": per_page, "has_more": False}

    def list(self, **kwargs) -> Dict[str, Any]:
        try:
            response = self.client._session.get(f"{self.client.api_url}/api/v{self.client.api_version}/networks", params=kwargs)
            if response.status_code == 429:
                error_data = response.json()
                raise RateLimitError(
                    "Rate limit exceeded",
                    retry_after=error_data.get("error", {}).get("retry_after", response.headers.get("Retry-After")),
                    response=response
                )
            if response.status_code != 200:
                error_data = response.json() if response.content else {}
                error_message = error_data.get("error", {}).get("message", f"Failed to list networks: {response.status_code}")
                raise APIError(error_message, response=response)
            data = response.json()
            # Always return a dict with 'data' and 'pagination' keys
            if isinstance(data, list):
                total = len(data)
                return {"data": [Network(**item) for item in data], "pagination": self._default_pagination(total, total)}
            if isinstance(data, dict):
                networks = [Network(**item) for item in data.get("data", [])]
                pagination = data.get("pagination", {})
                # Fill in missing pagination keys with defaults
                default_pagination = self._default_pagination(len(networks), len(networks))
                for key, value in default_pagination.items():
                    pagination.setdefault(key, value)
                return {"data": networks, "pagination": pagination}
            return {"data": [], "pagination": self._default_pagination(0, 0)}
        except Exception as e:
            logger.error(f"Error listing networks: {e}")
            raise

    def create(self, **kwargs) -> Network:
        if not kwargs.get("name"):
            raise ValidationError("Validation failed", details={"name": ["Name cannot be empty"]})
        response = self.client._session.post(f"{self.client.api_url}/api/v{self.client.api_version}/networks", json=kwargs)
        if response.status_code == 400:
            error_data = response.json()
            raise ValidationError(
                error_data.get("error", {}).get("message", "Validation failed"),
                details=error_data.get("error", {}).get("details", {}),
                response=response
            )
        if response.status_code != 201:
            error_data = response.json() if response.content else {}
            error_message = error_data.get("error", {}).get("message", f"Failed to create network: {response.status_code}")
            raise APIError(error_message, response=response)
        return Network(**response.json())

    def get(self, network_id: str) -> Network:
        response = self.client._session.get(f"{self.client.api_url}/api/v{self.client.api_version}/networks/{network_id}")
        if response.status_code == 404:
            raise ResourceNotFoundError(
                "Network not found",
                resource_id=network_id,
                response=response
            )
        if response.status_code != 200:
            error_data = response.json() if response.content else {}
            error_message = error_data.get("error", {}).get("message", f"Failed to get network: {response.status_code}")
            raise APIError(error_message, response=response)
        return Network(**response.json())

    def update(self, network_id: str, **kwargs) -> Network:
        response = self.client._session.patch(f"{self.client.api_url}/api/v{self.client.api_version}/networks/{network_id}", json=kwargs)
        if response.status_code == 404:
            raise ResourceNotFoundError("Network not found", resource_id=network_id, response=response)
        if response.status_code == 400:
            raise ValidationError("Validation failed", response=response)
        if response.status_code != 200:
            raise APIError(f"Failed to update network: {response.status_code}", response=response)
        return Network(**response.json())

    def delete(self, network_id: str) -> bool:
        response = self.client._session.delete(f"{self.client.api_url}/api/v{self.client.api_version}/networks/{network_id}")
        if response.status_code == 404:
            raise ResourceNotFoundError(
                "Network not found",
                resource_id=network_id,
                response=response
            )
        if response.status_code == 204:
            return True
        if response.status_code == 429:
            error_data = response.json()
            raise RateLimitError(
                "Rate limit exceeded",
                retry_after=error_data.get("error", {}).get("retry_after", response.headers.get("Retry-After")),
                response=response
            )
        if response.status_code >= 400:
            error_data = response.json() if response.content else {}
            error_message = error_data.get("error", {}).get("message", f"Failed to delete network: {response.status_code}")
            raise APIError(error_message, response=response)
        return False 