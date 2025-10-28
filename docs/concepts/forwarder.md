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

