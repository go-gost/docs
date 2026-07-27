---
comments: true
---

# 转发器

一个转发器包含一个或多个节点(节点组)，和一个节点[选择器](selector.md)。转发器主要用于[端口转发](../tutorials/port-forwarding.md)和[反向代理](../tutorials/reverse-proxy.md)中定义目标节点和转发策略。

## 使用

与跳跃点类似，转发器也有两种使用方式：内联模式和引用模式。

### 内链模式

在转发器中可以直接定义节点组和选择器。

```yaml
services:
- name: service-0
  addr: :8080
  handler:
    type: tcp
  listener:
    type: tcp
  forwarder:
    nodes:
    - name: target-0
      addr: 192.168.1.1:80
    - name: target-1
      addr: 192.168.1.2:80
    - name: target-2
      addr: 192.168.1.3:8080
    selector:
      strategy: round
      maxFails: 1
      failTimeout: 30s
```

### 引用模式

转发器也可以通过`forwarder.hop`来引用跳跃点。引用模式下可以借助于跳跃点的外部数据源和插件实现目标节点的动态更新。

```yaml hl_lines="9"
services:
- name: service-0
  addr: ":8080"
  handler:
    type: tcp 
  listener:
    type: tcp
  forwarder:
    hop: hop-0

hops:
- name: hop-0
  nodes:
  - name: target-0
    addr: 192.168.1.1:8080
  - name: target-1
    addr: 192.168.1.2:8080
```

## 跳跃点组

:material-tag: 3.3.0

`hopGroup` 扩展了转发器，支持从多个命名跳跃点中基于匹配规则路由DSL进行选择。每个跳跃点条目可以有自己的探活和匹配规则 — 只有匹配规则命中当前请求的条目才能被选中。

```yaml hl_lines="9 10 11 12 13 14 15"
services:
- name: service-0
  addr: ":8080"
  handler:
    type: tcp
  listener:
    type: tcp
  forwarder:
    hopGroup:
      hops:
      - hop: hop-api
        matcher: PathPrefix("/api/") && Host("*.example.com")
        probe: http
      - hop: hop-internal
        matcher: Bypass("10.0.0.0/8", "*.internal")
      - hop: hop-web
      selector:
        strategy: roundRobin
```

| 字段 | 类型 | 说明 |
|-------|------|------|
| `hops` | list | 跳跃点条目列表。每条引用 `hops` 注册表中的命名跳跃点。 |
| `selector` | object | 组级别选择器（strategy, maxFails, failTimeout）。 |

### 跳跃点条目

| 字段 | 类型 | 说明 |
|-------|------|------|
| `hop` | string | 引用的跳跃点名称，对应 `hops.name`。 |
| `matcher` | object | 可选路由规则。DSL参考参见 [节点匹配器](../reference/configuration/file.md#node-matcher)。nil = 无条件通过（catch-all）。 |
| `probe` | object | 可选跳跃点级别的健康检查。独立于节点级别的 `failCodes` 检查网络可达性 — probe 标记跳跃点条目，不影响节点。 |

!!! note "Probe 与 failCodes 的区别"
    `probe` 和 `failCodes` 在不同层级操作并使用独立的标记器：
    
    - **probe**（跳跃点级）：通过 TCP/HTTP/ICMP 检查跳跃点的网络健康状况，写入跳跃点条目标记器。
    - **failCodes**（节点级）：在节点上标记特定的 HTTP 响应状态码，写入节点标记器。
    
    探活不会撤销 `failCodes` 的排除标记 — 两者完全独立。

### 选择流程

1. **匹配器过滤**：根据匹配规则构建符合条件的条目池（Host、Path、Method、客户端IP等）。nil matcher = 始终符合条件。
2. **选择器管道**：应用 `FailFilter`（排除被probe标记的条目）→ `BackupFilter`（降级备用条目）→ 策略（round-robin、random等）→ 选出一个跳跃点条目。
3. **委托**：对选中条目的底层 hop 执行 `Select()`。hop 自身的选择器（含节点级 failCodes）选出最终节点。
```

