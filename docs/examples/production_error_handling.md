# Production-Grade Error Handling

This example demonstrates how to implement robust error handling with the Cloud Connexa client for production applications with critical uptime requirements.

## Basic Setup with Enhanced Error Handling

```python
import os
import logging
import time
from datetime import datetime, timedelta
from functools import wraps
import threading
from typing import Dict, Any, Optional, Callable, List, Tuple

from cloudconnexa import (
    CloudConnexaClient, 
    RetryPolicy, 
    CircuitBreaker,
    CloudConnexaError,
    AuthenticationError,
    RateLimitError,
    ResourceNotFoundError,
    ValidationError,
    ServerError,
    NetworkError,
    ServiceUnavailableError
)

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s [%(levelname)s] %(name)s: %(message)s',
    handlers=[
        logging.StreamHandler(),
        logging.FileHandler('cloudconnexa.log')
    ]
)
logger = logging.getLogger('cloudconnexa')

# Simple in-memory cache
class SimpleCache:
    def __init__(self, default_ttl: int = 300):
        self.cache: Dict[str, Tuple[Any, datetime]] = {}
        self.default_ttl = default_ttl
        self.lock = threading.RLock()
        
    def get(self, key: str, default: Any = None) -> Any:
        with self.lock:
            if key in self.cache:
                value, expiry = self.cache[key]
                if expiry > datetime.now():
                    return value
                else:
                    del self.cache[key]
            return default
            
    def set(self, key: str, value: Any, ttl: Optional[int] = None) -> None:
        ttl = ttl if ttl is not None else self.default_ttl
        with self.lock:
            self.cache[key] = (value, datetime.now() + timedelta(seconds=ttl))
            
    def delete(self, key: str) -> None:
        with self.lock:
            if key in self.cache:
                del self.cache[key]

# Create cache instance
cache = SimpleCache()

# Initialize client with production-grade settings
client = CloudConnexaClient(
    api_url=os.getenv("CLOUDCONNEXA_API_URL"),
    client_id=os.getenv("CLOUDCONNEXA_CLIENT_ID"),
    client_secret=os.getenv("CLOUDCONNEXA_CLIENT_SECRET"),
    retry_policy=RetryPolicy(
        max_retries=5,
        retry_codes=[408, 429, 500, 502, 503, 504],
        backoff_factor=0.5,
        backoff_max=120,
        backoff_jitter=True,
    ),
    circuit_breaker=CircuitBreaker(
        failure_threshold=10,
        recovery_timeout=300,
        expected_exceptions=(ServerError, NetworkError),
    ),
    timeout=(5, 30),  # Connect timeout, read timeout
)
```

## Implementing Fallbacks and Caching

```python
def with_cache(cache_key: str, ttl: int = 300):
    """Decorator to add caching to operations with fallback to cached value on error."""
    def decorator(func):
        @wraps(func)
        def wrapper(*args, **kwargs):
            # Try to get from cache first for read operations
            if func.__name__.startswith(('get', 'list')):
                cached_value = cache.get(cache_key)
                if cached_value is not None:
                    logger.debug(f"Cache hit for {cache_key}")
                    return cached_value
            
            try:
                # Execute the actual operation
                result = func(*args, **kwargs)
                
                # Cache the result for read operations
                if func.__name__.startswith(('get', 'list')):
                    cache.set(cache_key, result, ttl)
                    logger.debug(f"Cached result for {cache_key}")
                elif func.__name__.startswith(('create', 'update', 'delete')):
                    # Invalidate cache for write operations
                    cache.delete(cache_key)
                    logger.debug(f"Invalidated cache for {cache_key}")
                
                return result
            except (ServerError, NetworkError, RateLimitError) as e:
                # On error, try to fall back to cache
                cached_value = cache.get(cache_key)
                if cached_value is not None:
                    logger.warning(
                        f"API error: {type(e).__name__}, using cached value for {cache_key}",
                        exc_info=e
                    )
                    return cached_value
                else:
                    # No cache available, re-raise the exception
                    logger.error(f"API error and no cache available for {cache_key}", exc_info=e)
                    raise
        return wrapper
    return decorator
```

## Service Implementation with Error Handling

```python
class NetworkManager:
    """Wrapper for network operations with enhanced error handling."""
    
    def __init__(self, client: CloudConnexaClient):
        self.client = client
        self.logger = logging.getLogger('cloudconnexa.network')
    
    @with_cache("networks", ttl=600)
    def list_networks(self) -> List[Dict[str, Any]]:
        """List networks with caching and error handling."""
        try:
            networks = self.client.networks.list()
            return networks
        except AuthenticationError as e:
            self.logger.error("Authentication failed while listing networks", exc_info=e)
            # Could trigger re-authentication here
            raise
        except RateLimitError as e:
            self.logger.warning(
                f"Rate limited while listing networks, retry after {e.retry_after}s", 
                exc_info=e
            )
            raise
        except ResourceNotFoundError:
            self.logger.warning("No networks found")
            return []
        except ValidationError as e:
            self.logger.error("Validation error while listing networks", exc_info=e)
            raise
        except (ServerError, NetworkError) as e:
            self.logger.error(f"API error while listing networks: {e.code}", exc_info=e)
            raise
        except CloudConnexaError as e:
            self.logger.error(f"Unexpected error while listing networks: {e}", exc_info=e)
            raise
    
    def get_network(self, network_id: str) -> Optional[Dict[str, Any]]:
        """Get a single network with fallback mechanisms."""
        cache_key = f"network_{network_id}"
        
        try:
            # Try to get from API
            network = self.client.networks.get(network_id)
            
            # Cache successful response
            cache.set(cache_key, network, ttl=600)
            
            return network
        except ResourceNotFoundError:
            self.logger.warning(f"Network {network_id} not found")
            return None
        except (ServerError, NetworkError, RateLimitError) as e:
            self.logger.warning(f"API error: {type(e).__name__}, trying cache", exc_info=e)
            
            # Try to get from cache
            cached_network = cache.get(cache_key)
            if cached_network:
                self.logger.info(f"Using cached data for network {network_id}")
                return cached_network
            
            # No cache, re-raise
            raise
        except CloudConnexaError as e:
            self.logger.error(f"Error getting network {network_id}: {e}", exc_info=e)
            raise
    
    def create_network(
        self, name: str, description: str = None, **kwargs
    ) -> Dict[str, Any]:
        """Create a network with retry logic."""
        retry_count = 0
        max_retries = 3
        
        while True:
            try:
                network = self.client.networks.create(
                    name=name,
                    description=description,
                    **kwargs
                )
                
                # Invalidate list cache on successful creation
                cache.delete("networks")
                
                return network
            except ValidationError as e:
                self.logger.error(f"Validation error creating network: {e}", exc_info=e)
                raise
            except (ServerError, NetworkError) as e:
                retry_count += 1
                if retry_count >= max_retries:
                    self.logger.error(
                        f"Failed to create network after {max_retries} attempts", 
                        exc_info=e
                    )
                    raise
                
                wait_time = 2 ** retry_count  # Simple exponential backoff
                self.logger.warning(
                    f"Error creating network, retrying in {wait_time}s (attempt {retry_count}/{max_retries})",
                    exc_info=e
                )
                time.sleep(wait_time)
            except CloudConnexaError as e:
                self.logger.error(f"Unexpected error creating network: {e}", exc_info=e)
                raise
```

## Batch Operations with Error Handling

```python
def batch_update_networks(
    network_manager: NetworkManager, 
    updates: List[Dict[str, Any]]
) -> Tuple[List[Dict[str, Any]], List[Dict[str, Any]]]:
    """
    Update multiple networks with per-item error handling.
    
    Returns a tuple of (successful_updates, failed_updates).
    """
    successful = []
    failed = []
    
    for update in updates:
        network_id = update.get("id")
        if not network_id:
            failed.append({
                "update": update,
                "error": "Missing network ID",
                "error_type": "ValidationError"
            })
            continue
        
        try:
            network = network_manager.client.networks.update(
                network_id, 
                {k: v for k, v in update.items() if k != "id"}
            )
            successful.append(network)
            
            # Invalidate specific cache
            cache.delete(f"network_{network_id}")
        except CloudConnexaError as e:
            failed.append({
                "update": update,
                "error": str(e),
                "error_type": type(e).__name__,
                "error_code": getattr(e, "code", None)
            })
    
    # Invalidate list cache if any updates were successful
    if successful:
        cache.delete("networks")
    
    return successful, failed
```

## Background Job for Automatic Retry

```python
class RetryQueue:
    """Simple queue for operations that need to be retried."""
    
    def __init__(self):
        self.queue = []
        self.lock = threading.RLock()
        self.should_stop = False
        self.worker_thread = None
    
    def add(self, operation: Callable, args=None, kwargs=None, retry_after: int = 0):
        """Add an operation to the retry queue."""
        with self.lock:
            self.queue.append({
                "operation": operation,
                "args": args or (),
                "kwargs": kwargs or {},
                "retry_at": time.time() + retry_after,
                "retries": 0
            })
    
    def start_worker(self, max_retries: int = 5):
        """Start the worker thread to process the queue."""
        if self.worker_thread and self.worker_thread.is_alive():
            return
        
        def worker():
            while not self.should_stop:
                now = time.time()
                operations_to_retry = []
                
                # Get operations that are ready to retry
                with self.lock:
                    remaining = []
                    for op in self.queue:
                        if op["retry_at"] <= now:
                            operations_to_retry.append(op)
                        else:
                            remaining.append(op)
                    self.queue = remaining
                
                # Process operations
                for op in operations_to_retry:
                    try:
                        op["operation"](*op["args"], **op["kwargs"])
                        logger.info(f"Successfully retried operation: {op['operation'].__name__}")
                    except (ServerError, NetworkError, RateLimitError) as e:
                        op["retries"] += 1
                        
                        if op["retries"] >= max_retries:
                            logger.error(
                                f"Operation {op['operation'].__name__} failed after {max_retries} retries",
                                exc_info=e
                            )
                            continue
                        
                        # Calculate backoff time
                        if isinstance(e, RateLimitError) and getattr(e, "retry_after", None):
                            retry_after = e.retry_after
                        else:
                            retry_after = min(120, 2 ** op["retries"])
                        
                        logger.info(
                            f"Scheduling retry for {op['operation'].__name__} in {retry_after}s " 
                            f"(attempt {op['retries'] + 1}/{max_retries})"
                        )
                        
                        # Add back to queue with updated retry time
                        with self.lock:
                            op["retry_at"] = time.time() + retry_after
                            self.queue.append(op)
                    except Exception as e:
                        logger.error(
                            f"Unexpected error in retry operation {op['operation'].__name__}",
                            exc_info=e
                        )
                
                # Sleep to avoid busy waiting
                time.sleep(1)
        
        self.worker_thread = threading.Thread(target=worker, daemon=True)
        self.worker_thread.start()
    
    def stop_worker(self):
        """Stop the worker thread."""
        self.should_stop = True
        if self.worker_thread:
            self.worker_thread.join(timeout=5)

# Create retry queue
retry_queue = RetryQueue()
retry_queue.start_worker()
```

## Main Application with Comprehensive Error Handling

```python
def main():
    """Main application demonstrating comprehensive error handling."""
    try:
        # Initialize network manager
        network_manager = NetworkManager(client)
        
        # List networks with built-in fallback to cache
        try:
            networks = network_manager.list_networks()
            logger.info(f"Found {len(networks)} networks")
        except (ServerError, NetworkError, RateLimitError) as e:
            logger.error("Failed to list networks", exc_info=e)
            # Use empty list as fallback
            networks = []
        
        # Create a new network with automatic retry in case of failure
        try:
            new_network = network_manager.create_network(
                name=f"Test Network {int(time.time())}",
                description="Created with automated retry",
                egress=False
            )
            logger.info(f"Created network: {new_network['id']}")
        except (ServerError, NetworkError, RateLimitError) as e:
            logger.error("Failed to create network immediately", exc_info=e)
            
            # Add to retry queue for background processing
            retry_queue.add(
                network_manager.create_network,
                kwargs={
                    "name": f"Test Network {int(time.time())}",
                    "description": "Retried network creation",
                    "egress": False
                },
                retry_after=10  # Retry after 10 seconds
            )
        
        # Batch update networks with individual error handling
        updates = [
            {"id": network["id"], "description": f"Updated at {datetime.now()}"} 
            for network in networks[:5]
        ]
        
        if updates:
            successful, failed = batch_update_networks(network_manager, updates)
            logger.info(f"Batch update: {len(successful)} successful, {len(failed)} failed")
            
            # Retry failed updates
            for failed_update in failed:
                if failed_update["error_type"] in ("ServerError", "NetworkError", "RateLimitError"):
                    logger.info(f"Scheduling retry for failed update: {failed_update['update']['id']}")
                    retry_queue.add(
                        network_manager.client.networks.update,
                        args=(failed_update["update"]["id"],),
                        kwargs={
                            k: v for k, v in failed_update["update"].items() if k != "id"
                        },
                        retry_after=30
                    )
        
    except AuthenticationError as e:
        logger.critical("Authentication failed, application cannot proceed", exc_info=e)
        # Could implement auto re-authentication here or exit with error
        raise SystemExit("Authentication failed") from e
    except Exception as e:
        logger.critical("Unexpected error in main application", exc_info=e)
        raise
    finally:
        # Clean up resources
        retry_queue.stop_worker()

if __name__ == "__main__":
    main()
```

## Best Practices for Production Applications

1. **Layer your error handling**
   - Client-level error handling: retries, circuit breakers
   - Service-level error handling: caching, fallbacks
   - Application-level error handling: business logic, user feedback

2. **Use meaningful error logs**
   - Include context for easier debugging
   - Structured logging for better searchability
   - Different log levels for different error severities

3. **Implement graceful degradation**
   - Provide fallbacks for critical operations
   - Use caching to handle temporary API outages
   - Implement offline capabilities when possible

4. **Monitor and alert**
   - Track error rates and patterns
   - Set up alerts for critical failures
   - Log correlation IDs for request tracing

5. **Plan for recovery**
   - Automatic retry mechanisms for transient errors
   - Circuit breakers to prevent cascading failures
   - Background processing for failed operations

6. **Manage resource cleanup**
   - Ensure connections are closed properly
   - Clean up temporary resources on failure
   - Use context managers and finally blocks

7. **Test error scenarios**
   - Create unit tests for error handling paths
   - Simulate API failures in integration tests
   - Conduct chaos testing in staging environments 