---
comments: true
---

# HTTP响应缓存

:material-tag: 3.3.0

HTTP响应缓存允许GOST代理缓存上游服务器的响应，在后续相同请求时直接返回缓存内容，减少上游负载并降低响应延迟。

## 使用方式

通过引用一个已定义的[缓存](../concepts/cache.md)对象来启用缓存，并通过handler元数据配置缓存策略。

### 缓存静态站点

以下配置示例通过反向代理缓存任意静态站点的响应：

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

!!! tip "验证缓存"
    第一次请求时，日志中会显示`<-> upstream`表示向上游发起请求。第二次相同的请求将会从缓存直接返回，日志中显示`cache hit`，不会再有上游连接。

### 缓存失效

缓存的失效时间通过`cache.ttl`或`cache.status.<code>`控制：

```yaml
metadata:
  cache.ttl: 60m
  cache.status.200: 30m
  cache.status.301: 10m
  cache.status.404: 1m
  cache.status.500: 0s
```

- 200响应缓存30分钟。
- 301重定向缓存10分钟。
- 404响应仅缓存1分钟。
- 500响应不缓存（TTL为0）。

### 上游故障时使用过期缓存

```yaml
metadata:
  cache.ttl: 60m
  cache.serveStale: true
```

当`cache.serveStale`设置为`true`，且上游服务不可用时，即使缓存条目已过期也会返回给客户端。这提高了服务的可用性，允许在短暂的上游故障期间继续提供服务。

### 自定义缓存方法

默认只缓存GET和HEAD请求。如需缓存其他HTTP方法：

```yaml
metadata:
  cache.methods:
  - GET
  - HEAD
  - POST
```

### 限制缓存响应体大小

```yaml
metadata:
  cache.maxBodyBytes: 1048576
```

超过此大小的响应体不会被缓存。默认值为1MB。

## 示例：缓存反向代理

结合[反向代理](reverse-proxy.md)功能，缓存多个后端站点：

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