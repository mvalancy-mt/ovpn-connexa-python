# Connection Pooling and Performance Optimization

This example demonstrates how to implement efficient connection pooling and resource management when using the Cloud Connexa client in high-throughput microservices architectures.

## Understanding Connection Management

The CloudConnexaClient handles HTTP connections via the underlying requests library. In high-volume microservices environments, proper connection management is critical to:

1. Reduce latency by reusing connections
2. Prevent connection exhaustion
3. Optimize resource usage across services
4. Avoid rate limiting issues
5. Maintain service stability under load

## Basic Connection Pooling Setup

```python
import os
import logging
from urllib3.util import Retry
from requests.adapters import HTTPAdapter
from requests.packages.urllib3.poolmanager import PoolManager
from cloudconnexa import CloudConnexaClient, RetryPolicy, CircuitBreaker

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger('cloudconnexa')

# Custom connection pool configuration
class ConnectionPoolManager:
    """Manager for connection pools across service instances."""
    
    def __init__(
        self,
        pool_connections=10,     # Connections to keep in pool
        pool_maxsize=20,         # Maximum connections in pool
        max_retries=3,           # Default retries for connection errors
        backoff_factor=0.5,      # Backoff factor between retries
        pool_block=False         # Whether to block when pool is full
    ):
        self.pool_connections = pool_connections
        self.pool_maxsize = pool_maxsize
        self.max_retries = max_retries
        self.backoff_factor = backoff_factor
        self.pool_block = pool_block
    
    def configure_client(self, client):
        """Configure a client with connection pooling."""
        # Create retry strategy for connection-level retries
        retry_strategy = Retry(
            total=self.max_retries,
            backoff_factor=self.backoff_factor,
            status_forcelist=[429, 500, 502, 503, 504],
            allowed_methods=["HEAD", "GET", "PUT", "DELETE", "OPTIONS", "TRACE", "POST"]
        )
        
        # Create adapter with connection pooling
        adapter = HTTPAdapter(
            max_retries=retry_strategy,
            pool_connections=self.pool_connections,
            pool_maxsize=self.pool_maxsize,
            pool_block=self.pool_block
        )
        
        # Apply adapter to client's session
        client._session.mount("http://", adapter)
        client._session.mount("https://", adapter)
        
        return client

# Create pool manager
pool_manager = ConnectionPoolManager(
    pool_connections=20,
    pool_maxsize=50,
    max_retries=3,
    backoff_factor=0.5
)

# Initialize client with connection pooling
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
    ),
    timeout=(5, 30),  # Connect timeout, read timeout
)

# Apply connection pooling configuration
pool_manager.configure_client(client)
```

## Microservices Connection Management

In microservices architectures, multiple service instances may need to communicate with Cloud Connexa simultaneously. Here's how to implement an efficient client factory:

```python
import threading
from typing import Dict, Any, Optional

# Client factory for microservices
class CloudConnexaClientFactory:
    """Factory for creating and managing CloudConnexaClient instances."""
    
    # Singleton pattern
    _instance = None
    _lock = threading.RLock()
    
    def __new__(cls):
        with cls._lock:
            if cls._instance is None:
                cls._instance = super(CloudConnexaClientFactory, cls).__new__(cls)
                cls._instance._initialized = False
        return cls._instance
    
    def __init__(self):
        if self._initialized:
            return
            
        self.clients = {}
        self.pool_manager = ConnectionPoolManager(
            pool_connections=20,
            pool_maxsize=50
        )
        self._initialized = True
    
    def get_client(
        self, 
        service_name: str, 
        api_version: Optional[str] = None,
        **kwargs
    ) -> CloudConnexaClient:
        """Get or create a client for a specific service."""
        with self._lock:
            key = f"{service_name}:{api_version or 'default'}"
            
            if key in self.clients:
                return self.clients[key]
            
            # Create new client with specific configuration if needed
            client = CloudConnexaClient(
                api_url=os.getenv("CLOUDCONNEXA_API_URL"),
                client_id=os.getenv("CLOUDCONNEXA_CLIENT_ID"),
                client_secret=os.getenv("CLOUDCONNEXA_CLIENT_SECRET"),
                api_version=api_version,
                retry_policy=RetryPolicy(
                    max_retries=kwargs.get('max_retries', 5),
                    retry_codes=kwargs.get('retry_codes', [408, 429, 500, 502, 503, 504]),
                    backoff_factor=kwargs.get('backoff_factor', 0.5),
                    backoff_max=kwargs.get('backoff_max', 120),
                    backoff_jitter=kwargs.get('backoff_jitter', True),
                ),
                circuit_breaker=CircuitBreaker(
                    failure_threshold=kwargs.get('failure_threshold', 10),
                    recovery_timeout=kwargs.get('recovery_timeout', 300),
                ),
                timeout=kwargs.get('timeout', (5, 30)),
            )
            
            # Apply connection pooling
            self.pool_manager.configure_client(client)
            
            # Store client for reuse
            self.clients[key] = client
            return client

# Usage in microservices
factory = CloudConnexaClientFactory()

# In Service A
client_a = factory.get_client("service-a")

# In Service B (with different configuration needs)
client_b = factory.get_client(
    "service-b",
    max_retries=10,
    timeout=(10, 60)
)

# In Service C (with specific API version)
client_c = factory.get_client(
    "service-c",
    api_version="1.0"
)
```

## Distributed Rate Limit Management

When multiple services share the same Cloud Connexa account, coordinated rate limit management is essential:

```python
import time
import redis
from datetime import datetime

class DistributedRateLimiter:
    """Distributed rate limiter using Redis."""
    
    def __init__(
        self,
        redis_client,
        key_prefix="cloudconnexa_rate_limit:",
        window_size=60,  # Window size in seconds
        max_requests=100  # Maximum requests per window
    ):
        self.redis = redis_client
        self.key_prefix = key_prefix
        self.window_size = window_size
        self.max_requests = max_requests
    
    def _get_window_key(self, endpoint):
        """Get the current time window key for an endpoint."""
        timestamp = int(time.time() / self.window_size) * self.window_size
        return f"{self.key_prefix}{endpoint}:{timestamp}"
    
    def check_rate_limit(self, endpoint, increment=True):
        """
        Check if the rate limit has been reached for an endpoint.
        
        Returns:
            tuple: (allowed, current_count, reset_time)
        """
        key = self._get_window_key(endpoint)
        pipe = self.redis.pipeline()
        
        # Get current count and increment if requested
        if increment:
            current_count = pipe.incr(key).get(key).execute()
            # Set expiration if this is a new key
            if current_count[0] == 1:
                self.redis.expire(key, self.window_size * 2)  # 2x window for safety
            current_count = current_count[1]
        else:
            current_count = int(self.redis.get(key) or 0)
        
        # Calculate time until reset
        next_window = (int(time.time() / self.window_size) + 1) * self.window_size
        reset_time = next_window - time.time()
        
        # Check if allowed
        allowed = current_count <= self.max_requests
        
        return (allowed, current_count, reset_time)

# Usage with client factory
redis_client = redis.Redis(host='localhost', port=6379, db=0)
rate_limiter = DistributedRateLimiter(
    redis_client,
    max_requests=1000,  # Adjust based on API limits
    window_size=60
)

class RateLimitedClientFactory(CloudConnexaClientFactory):
    """Client factory with distributed rate limiting."""
    
    def __init__(self, rate_limiter):
        super().__init__()
        self.rate_limiter = rate_limiter
    
    def execute_request(self, client, method, endpoint, **kwargs):
        """Execute request with rate limit check."""
        # Check rate limit before making request
        allowed, count, reset_time = self.rate_limiter.check_rate_limit(
            endpoint, increment=False
        )
        
        if not allowed:
            logger.warning(
                f"Rate limit pre-check would exceed limit for {endpoint}. "
                f"Current count: {count}, reset in {reset_time:.2f}s"
            )
            time.sleep(min(reset_time, 10))  # Wait up to 10 seconds
        
        # Actually increment counter and check again
        allowed, count, reset_time = self.rate_limiter.check_rate_limit(endpoint)
        
        if not allowed:
            logger.warning(
                f"Rate limit exceeded for {endpoint}. "
                f"Current count: {count}, reset in {reset_time:.2f}s"
            )
            # Add jitter to prevent thundering herd
            jitter = random.uniform(0.1, 0.5)
            time.sleep(min(reset_time + jitter, 30))  # Wait up to 30 seconds
        
        # Execute request through client
        return client.execute_request(method, endpoint, **kwargs)

# Create factory with rate limiting
factory = RateLimitedClientFactory(rate_limiter)

# Get client for a service
client = factory.get_client("my-service")

# Example usage with rate limiting
networks = client.networks.list()
```

## Advanced Connection Options for High-Volume Applications

For applications with very high throughput requirements, consider these advanced options:

```python
import requests.packages.urllib3.util.connection as urllib3_connection
import socket
import ssl

# Original DNS resolver
original_resolver = urllib3_connection.create_connection

# Custom DNS resolver with caching
def patched_create_connection(address, *args, **kwargs):
    """Custom connection creation with DNS caching and IPv4 preference."""
    host, port = address
    
    # Use cached or resolved DNS for host
    if host in dns_cache and dns_cache[host]['expires'] > time.time():
        resolved_ip = dns_cache[host]['ip']
        logger.debug(f"Using cached DNS for {host}: {resolved_ip}")
    else:
        # Resolve DNS and cache for future use
        try:
            resolved_ip = socket.gethostbyname(host)
            dns_cache[host] = {
                'ip': resolved_ip,
                'expires': time.time() + DNS_CACHE_TTL
            }
            logger.debug(f"Resolved and cached DNS for {host}: {resolved_ip}")
        except socket.gaierror:
            logger.error(f"Failed to resolve DNS for {host}")
            resolved_ip = host
    
    return original_resolver((resolved_ip, port), *args, **kwargs)

# Custom connection pool class
class CustomConnectionPool(PoolManager):
    """Custom connection pool with advanced options."""
    
    def __init__(self, *args, **kwargs):
        # Extract custom options
        self.dns_cache_ttl = kwargs.pop('dns_cache_ttl', 300)
        self.connection_timeout = kwargs.pop('connection_timeout', 5)
        self.tcp_keepalive = kwargs.pop('tcp_keepalive', True)
        
        super().__init__(*args, **kwargs)
    
    def _new_connection(self, *args, **kwargs):
        # Apply advanced socket options to connection
        conn = super()._new_connection(*args, **kwargs)
        
        # Set socket options if applicable
        if hasattr(conn, 'sock') and conn.sock:
            # Configure TCP keepalive
            if self.tcp_keepalive:
                conn.sock.setsockopt(socket.SOL_SOCKET, socket.SO_KEEPALIVE, 1)
                # Set keepalive parameters if supported by platform
                if hasattr(socket, 'TCP_KEEPIDLE'):
                    conn.sock.setsockopt(socket.IPPROTO_TCP, socket.TCP_KEEPIDLE, 60)
                if hasattr(socket, 'TCP_KEEPINTVL'):
                    conn.sock.setsockopt(socket.IPPROTO_TCP, socket.TCP_KEEPINTVL, 10)
                if hasattr(socket, 'TCP_KEEPCNT'):
                    conn.sock.setsockopt(socket.IPPROTO_TCP, socket.TCP_KEEPCNT, 6)
            
        return conn

# Initialize with advanced options
DNS_CACHE_TTL = 300  # 5 minutes
dns_cache = {}

# Patch connection creation
urllib3_connection.create_connection = patched_create_connection

# Create adapter with custom connection pool
adapter = HTTPAdapter(
    pool_connections=50,
    pool_maxsize=100,
    pool_block=False,
    max_retries=Retry(
        total=5,
        backoff_factor=0.5,
        status_forcelist=[429, 500, 502, 503, 504]
    )
)

# Apply adapter to client session
client = factory.get_client("high-throughput-service")
client._session.mount("https://", adapter)
```

## Performance Testing and Optimization

When deploying in a microservices architecture, it's important to test and monitor connection usage:

```python
import threading
import time
import statistics
from concurrent.futures import ThreadPoolExecutor
import matplotlib.pyplot as plt

def performance_test(client_factory, num_threads=10, requests_per_thread=100):
    """Test client performance under load."""
    results = []
    errors = []
    
    def worker():
        client = client_factory.get_client(f"test-{threading.get_ident()}")
        latencies = []
        
        for i in range(requests_per_thread):
            try:
                start = time.time()
                client.networks.list(limit=10)  # Use a lightweight endpoint
                latency = time.time() - start
                latencies.append(latency)
            except Exception as e:
                errors.append(str(e))
        
        return latencies
    
    with ThreadPoolExecutor(max_workers=num_threads) as executor:
        all_latencies = list(executor.map(worker, range(num_threads)))
    
    # Flatten latencies list
    latencies = [item for sublist in all_latencies for item in sublist]
    
    # Calculate statistics
    if latencies:
        stats = {
            'min': min(latencies),
            'max': max(latencies),
            'avg': statistics.mean(latencies),
            'median': statistics.median(latencies),
            'p95': sorted(latencies)[int(len(latencies) * 0.95)],
            'p99': sorted(latencies)[int(len(latencies) * 0.99)],
            'total_requests': len(latencies),
            'errors': len(errors),
            'error_rate': len(errors) / (len(latencies) + len(errors))
        }
    else:
        stats = {'error': 'No successful requests'}
    
    return stats, latencies, errors

# Run performance test
stats, latencies, errors = performance_test(factory, num_threads=20, requests_per_thread=50)

# Print results
print(f"Performance Results:")
print(f"Total Requests: {stats['total_requests']}")
print(f"Error Rate: {stats['error_rate']:.2%}")
print(f"Avg Latency: {stats['avg'] * 1000:.2f}ms")
print(f"Median Latency: {stats['median'] * 1000:.2f}ms")
print(f"95th Percentile: {stats['p95'] * 1000:.2f}ms")
print(f"99th Percentile: {stats['p99'] * 1000:.2f}ms")
```

## Best Practices for Microservices

1. **Use a client factory pattern**
   - Create clients through a factory to control instantiation
   - Share connection pools across related services
   - Configure clients appropriate to each service's needs

2. **Implement distributed rate limiting**
   - Use Redis or a similar distributed cache to track API usage
   - Pre-emptively wait when approaching limits
   - Apply backoff strategies when limits are hit

3. **Optimize connection management**
   - Tune connection pool sizes based on service needs
   - Set appropriate timeouts to prevent connection hangs
   - Enable TCP keepalive for connection stability

4. **Monitor and track performance**
   - Log request latencies and success rates
   - Set up alerts for spikes in error rates
   - Periodically run performance tests to verify optimizations

5. **Implement proper service degradation**
   - Cache frequently accessed data locally
   - Provide fallbacks for non-critical operations
   - Circuit breaker pattern (already provided by the client)

6. **Scale horizontally with care**
   - Be aware of total connection count across all instances
   - Coordinate rate limiting across instances
   - Consider designating specific services for API access

7. **Advanced metrics and observability**
   - Implement distributed tracing (with libraries like OpenTelemetry)
   - Monitor connection pool usage and saturation
   - Track token refresh operations and authentication status

## Advanced Retry and Request Coalescing

For microservices that perform similar operations, request coalescing can reduce API load:

```python
import asyncio
import functools
from typing import Any, Dict, List, Set, Tuple, Optional, Callable

class RequestCoalescer:
    """Coalesce similar requests to reduce API load."""
    
    def __init__(self, window_ms=50, max_batch=100):
        self.window_ms = window_ms
        self.max_batch = max_batch
        self.pending_requests = {}
        self.lock = threading.RLock()
    
    def coalesce(self, key_func):
        """Decorator to coalesce similar requests."""
        def decorator(func):
            @functools.wraps(func)
            async def wrapper(*args, **kwargs):
                # Generate key for this request
                key = key_func(*args, **kwargs)
                
                # Check if there's already a pending request for this key
                with self.lock:
                    if key in self.pending_requests:
                        # There's a pending request, add our future to waiters
                        future = asyncio.Future()
                        self.pending_requests[key]['waiters'].append(future)
                        return await future
                    
                    # No pending request, create one
                    future = asyncio.Future()
                    self.pending_requests[key] = {
                        'primary': future,
                        'waiters': [],
                        'args': args,
                        'kwargs': kwargs
                    }
                
                try:
                    # Actually execute the request
                    result = await func(*args, **kwargs)
                    
                    # Resolve the primary future
                    future.set_result(result)
                    
                    # Resolve all waiting futures
                    with self.lock:
                        for waiter in self.pending_requests[key]['waiters']:
                            waiter.set_result(result)
                        del self.pending_requests[key]
                    
                    return result
                except Exception as e:
                    # Propagate exception to all waiters
                    with self.lock:
                        future.set_exception(e)
                        for waiter in self.pending_requests[key]['waiters']:
                            waiter.set_exception(e)
                        del self.pending_requests[key]
                    raise
            
            return wrapper
        return decorator

# Example usage with CloudConnexa client
coalescer = RequestCoalescer(window_ms=50, max_batch=25)

# Key function for identifying similar network list requests
def network_list_key(client, **kwargs):
    # Generate a key based on list parameters
    key_parts = ['networks.list']
    for k in sorted(kwargs.keys()):
        key_parts.append(f"{k}={kwargs[k]}")
    return ":".join(key_parts)

# Apply coalescing to network list operations
@coalescer.coalesce(network_list_key)
async def get_networks(client, **kwargs):
    """Get networks with request coalescing."""
    return client.networks.list(**kwargs)

# Example usage in an async application
async def main():
    # Create multiple concurrent requests that will be coalesced
    client = factory.get_client("api-consumer")
    
    # These will be coalesced into a single API call
    tasks = [
        get_networks(client, limit=10, offset=0)
        for _ in range(20)  # 20 concurrent requests for the same data
    ]
    
    # Wait for all tasks to complete
    results = await asyncio.gather(*tasks)
    
    # All tasks received the same result from a single API call
    print(f"Received {len(results)} identical results")

# Run the async application
loop = asyncio.get_event_loop()
loop.run_until_complete(main())
```

## Conclusion

Implementing proper connection pooling and resource management is essential for high-throughput microservices architectures using the Cloud Connexa API. By following these patterns and practices, you can optimize performance, reduce rate limiting issues, and ensure stable operation even under significant load. 