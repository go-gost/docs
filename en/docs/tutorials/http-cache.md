---
comments: true
---

# HTTP Response Caching

:material-tag: 3.3.0

HTTP response caching allows GOST to store upstream server responses and serve them directly on subsequent identical requests, reducing upstream load and lowering response latency.

## Usage

Reference a named [cache](../concepts/cache.md) instance and configure the policy through handler metadata.

### Caching a Static Site

The following example caches responses from any static site through reverse proxy:

```yaml
caches:
- name: web-cache
  memory:
    ttl: 60m
    maxSize: 10000
    maxBytes: "268435456"
    eviction: lru

services:
- name: mirror
  addr: :8080
  cache: web-cache
  handler:
    type: tcp
    metadata:
      sniffing: true
      cache.ttl: 60m
      cache.status.404: 1m
      cache.serveStale: true
  listener:
    type: tcp
  forwarder:
    nodes:
    - name: upstream
      addr: my-site.example.com:80
      matcher:
        rule: Host(`my-site.example.com`)
```

!!! tip "Verifying the cache"
    On the first request, the log shows `<-> upstream` indicating an upstream connection. The same request a second time is served from cache — the log shows `cache hit` and no upstream connection is made.

### Cache Expiration

Control TTL per status code with `cache.ttl` and `cache.status.<code>`:

```yaml
metadata:
  cache.ttl: 60m
  cache.status.200: 30m
  cache.status.301: 10m
  cache.status.404: 1m
  cache.status.500: 0s
```

- 200 responses are cached for 30 minutes.
- 301 redirects are cached for 10 minutes.
- 404 responses are cached for 1 minute.
- 500 responses are not cached (TTL is 0).

### Serving Stale on Upstream Failure

```yaml
metadata:
  cache.ttl: 60m
  cache.serveStale: true
```

When `cache.serveStale` is `true` and the upstream is unreachable, expired cache entries are still returned to the client. This improves availability during transient upstream outages.

### Custom Cacheable Methods

By default only GET and HEAD are cached. To cache other methods:

```yaml
metadata:
  cache.methods:
  - GET
  - HEAD
  - POST
```

### Limiting Response Body Size

```yaml
metadata:
  cache.maxBodyBytes: 1048576
```

Responses larger than this are not cached. Default is 1 MB.

## Example: Caching Reverse Proxy

Combine with [reverse proxy](reverse-proxy.md) to cache multiple backend sites:

```yaml
caches:
- name: proxy-cache
  memory:
    ttl: 30m
    cleanupInterval: 5m
    eviction: lru

services:
- name: web
  addr: :80
  cache: proxy-cache
  handler:
    type: tcp
    metadata:
      sniffing: true
      cache.ttl: 30m
      cache.status.404: 30s
  listener:
    type: tcp
  forwarder:
    nodes:
    - name: blog
      addr: blog.example.com:80
      matcher:
        rule: Host(`blog.example.com`)
    - name: docs
      addr: docs.example.com:80
      matcher:
        rule: Host(`docs.example.com`)
    - name: static
      addr: static.example.com:80
      matcher:
        rule: Host(`static.example.com`)
```
