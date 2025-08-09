---
comments: true
---

# Forwarder

A forwarder consists of one or more nodes (node group) and a node [selector](selector.md). Forwarders are mainly used to define target nodes and forwarding policies in [port forwarding](../tutorials/port-forwarding.md) and [reverse proxy](../tutorials/reverse-proxy.md).

## Usage

Similar to hop, forwarders can be used in two ways: inline mode and reference mode.

### Inline Mode

Node group and selector can be defined directly in the forwarder.

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

### Reference Mode

The forwarder can also reference hop through the `forwarder.hop` option. In reference mode, the target nodes can be dynamically updated with the help of the hop's external data source and plugin.

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

