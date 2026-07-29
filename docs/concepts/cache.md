---
comments: true
---

# 缓存

:material-tag: 3.3.0

!!! tip "动态配置"
    缓存组件支持通过[Web API](../tutorials/api/overview.md)进行动态配置。

缓存组件提供通用的键值存储能力，用于缓存热点数据以减少对上游服务的重复请求。目前主要用于HTTP响应的缓存，未来将扩展到DNS响应等场景。

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

## 缓存后端

目前支持的后端类型：

### 内存

内存缓存将数据存储在进程内存中，适合单实例部署场景。

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
:    默认的缓存有效期。如果不设置，条目默认永不过期。

`maxSize` (int, default=0)
:    最大缓存条目数。达到上限后会根据淘汰策略驱逐旧条目。0表示不限制。

`maxBytes` (int, default=0)
:    最大缓存数据量（字节）。达到上限后会根据淘汰策略驱逐旧条目。0表示不限制。

`cleanupInterval` (duration)
:    后台清理过期条目的时间间隔。如果不设置则不启动后台清理。

`eviction` (string, default=`oldest`)
:    淘汰策略。可选值：
    - `oldest` — 优先淘汰创建时间最早的条目。
    - `lru` — 优先淘汰最近最少访问的条目。

### Redis

Redis缓存将数据存储在远程Redis服务器中，适合多实例部署和需要缓存共享的场景。

```yaml
caches:
- name: cache-0
  redis:
    addr: 127.0.0.1:6379
    db: 0
    ttl: 60m
```

`addr` (string, required)
:    Redis服务器地址（`host:port`）。

`db` (int, default=0)
:    Redis数据库编号。

`username` (string)
:    Redis认证用户名（仅Redis 6.0+支持ACL时使用）。

`password` (string)
:    Redis认证密码。

`ttl` (duration, default=0)
:    默认的缓存有效期。如果不设置，条目默认永不过期。

`key` (string, default=`gost:cache:`)
:    键前缀，用于区分不同应用的缓存键。

!!! warning "注意"
    Redis缓存不支持`serveStale`（返回过期条目）语义。如果Redis中的键已过期，视为缓存未命中。需要使用此特性请使用内存后端。

## 服务中使用

在服务级别通过`cache`属性引用已定义的缓存名称。

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
:    引用的缓存实例名称。

### Handler元数据

当服务引用缓存后，可以通过handler的元数据来配置HTTP缓存策略：

`cache.ttl` (duration)
:    缓存条目的默认有效期。例如：`60m`，`1h`。

`cache.status.<code>` (duration)
:    按HTTP状态码分别设置缓存有效期，覆盖默认TTL。例如`cache.status.200: 60m`，`cache.status.404: 1m`。

`cache.serveStale` (bool, default=false)
:    当上游服务不可用时，是否使用已过期的缓存条目作为响应。

`cache.methods` ([]string, default=`[GET, HEAD]`)
:    允许缓存的HTTP请求方法列表。

`cache.maxBodyBytes` (int, default=1048576)
:    可缓存的HTTP响应体最大字节数。超过此大小的响应不会被缓存。

## 工作原理

当服务配置了缓存后，处理HTTP请求时的流程如下：

1. 收到客户端请求后，**在向上游发起连接之前**，先检查缓存中是否存在对应的条目。
2. **缓存命中（未过期）**：直接返回缓存的响应，无需向上游发起请求。
3. **缓存命中（已过期）**：记录过期条目，继续向上游发起请求。如果上游请求失败且启用了`serveStale`，则返回过期条目。
4. **缓存未命中**：向上游发起请求，在响应返回给客户端的同时，符合条件的响应会被异步缓存。

## 注意事项

- 缓存键由`请求方法 + 主机 + URI`组成（例如：`GET www.example.com /api`）。
- 只有HTTP `2xx`和`3xx`状态的响应会被缓存。
- 所有handler的缓存指向的是同一个后端存储，不同服务引用同一缓存名称时会共享数据。
