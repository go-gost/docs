---
comments: true
---

# Cache

:material-tag: 3.3.0

!!! tip "Dynamic configuration"
    Cache supports dynamic configuration via [Web API](../tutorials/api/overview.md).

The cache component provides a generic key-value store for caching hot data and reducing duplicate requests to upstream services. It is primarily used for HTTP response caching and will later be extended to DNS responses and other scenarios.

```yaml hl_lines="2 11 15 16"
caches:
- name: cache-0
  memory:
    ttl: 60m
    maxSize: 10000
    maxBytes: 256MB
    eviction: lru
services:
- name: service-0
  addr: ":8080"
  cache: cache-0
  handler:
    type: http
    metadata:
      cache.ttl: 60m
      cache.serveStale: true
```

## Backends

Currently supported backend types:

### Memory

In-memory cache stores data in the process heap, suitable for single-instance deployments.

```yaml
caches:
- name: cache-0
  memory:
    ttl: 60m
    maxSize: 10000
    maxBytes: "268435456"
    cleanupInterval: 5m
    eviction: lru
```

`ttl` (duration, default=0)
:    Default time-to-live for cache entries. When unset, entries never expire.

`maxSize` (int, default=0)
:    Maximum number of entries. When exceeded, old entries are evicted per the eviction policy. 0 means unlimited.

`maxBytes` (int, default=0)
:    Maximum cache data size in bytes. When exceeded, old entries are evicted. 0 means unlimited.

`cleanupInterval` (duration)
:    Interval for the background expired-entry cleanup goroutine. When unset, background cleanup is disabled.

`eviction` (string, default=`oldest`)
:    Eviction policy. Options:
    - `oldest` — evict the entry with the earliest creation time first.
    - `lru` — evict the least recently accessed entry first.

### Redis

Redis cache stores data in a remote Redis server, suitable for multi-instance deployments and shared caching scenarios.

```yaml
caches:
- name: cache-0
  redis:
    addr: 127.0.0.1:6379
    db: 0
    ttl: 60m
```

`addr` (string, required)
:    Redis server address (`host:port`).

`db` (int, default=0)
:    Redis database number.

`username` (string)
:    Redis ACL username (Redis 6.0+).

`password` (string)
:    Redis authentication password.

`ttl` (duration, default=0)
:    Default time-to-live for cache entries. When unset, entries never expire.

`key` (string, default=`gost:cache:`)
:    Key prefix for namespacing cache entries.

!!! warning
    Redis cache does not support `serveStale` semantics. Once a key has expired in Redis, it is treated as a cache miss. Use the memory backend if stale-serving is required.

## Using in a Service

Reference a named cache via the service-level `cache` property.

```yaml
services:
- name: web
  addr: ":8080"
  cache: cache-0
  handler:
    type: http
    metadata:
      cache.ttl: 60m
      cache.status.404: 1m
      cache.serveStale: true
      cache.methods:
      - GET
      - HEAD
      cache.maxBodyBytes: 1048576
```

`cache` (string)
:    Name of the cache instance to use.

### Handler Metadata

When a service references a cache, the HTTP cache policy is configured through handler metadata:

`cache.ttl` (duration)
:    Default TTL for cached responses. Examples: `60m`, `1h`.

`cache.status.<code>` (duration)
:    Per-status TTL override, takes precedence over `cache.ttl`. Example: `cache.status.200: 60m`, `cache.status.404: 1m`.

`cache.serveStale` (bool, default=false)
:    Whether to serve expired cache entries when the upstream is unreachable.

`cache.methods` ([]string, default=`[GET, HEAD]`)
:    HTTP methods eligible for caching.

`cache.maxBodyBytes` (int, default=1048576)
:    Maximum serialized response body size in bytes. Responses exceeding this are not cached.

## How It Works

When a service has caching configured, the HTTP request flow is:

1. **Before dialing upstream**, the cache is checked for a matching entry.
2. **Fresh hit**: the cached response is returned directly — no upstream request is made.
3. **Stale hit**: the expired entry is retained as a fallback; the upstream request proceeds. If the upstream fails and `serveStale` is enabled, the stale entry is served.
4. **Miss**: the request is forwarded upstream. When the response is written back to the client, a copy is captured and stored in the cache.

## Notes

- Cache keys are formed from `method + host + URI` (e.g. `GET www.example.com /api`).
- Only `2xx` and `3xx` responses are cached.
- All handlers referencing the same named cache share a single backend store.
