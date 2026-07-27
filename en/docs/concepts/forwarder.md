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

## Hop Group

:material-tag: 3.3.0

`hopGroup` extends the forwarder to select from multiple named hops using a matcher-based routing DSL. Each hop entry can have its own probe and matcher rule — only entries whose matcher matches the current request are eligible for selection.

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
        probe:
          type: http
      - hop: hop-internal
        matcher: Bypass("10.0.0.0/8", "*.internal")
      - hop: hop-web
      selector:
        strategy: rr
```

| Field | Type | Description |
|-------|------|-------------|
| `hops` | list | Hop entries. Each entry references a named hop from `hops` registry. |
| `selector` | object | Group-level selector (strategy, maxFails, failTimeout). |

### Hop Entry

| Field | Type | Description |
|-------|------|-------------|
| `hop` | string | Named hop reference from `hops` registry. |
| `matcher` | object | Optional routing rule. See [Node Matcher](../reference/configuration/file.md#node-matcher) for DSL reference. Nil = catch-all (always eligible). |
| `probe` | object | Optional hop-level health check. Validates network reachability independently from node-level `failCodes` — probe marks the hop entry, not the node. |

!!! note "Probe vs failCodes"
    `probe` and `failCodes` operate at different levels and use separate markers:
    
    - **probe** (hop-level): checks network health of the hop via TCP/HTTP/ICMP. Writes to the hop entry marker.
    - **failCodes** (node-level): marks individual HTTP response status codes on nodes. Writes to the node marker.
    
    Probes cannot undo a `failCodes` exclusion — they are independent.

### Selection Flow

1. **Matcher filter**: build eligible pool from entries whose matcher matches the routing context (Host, Path, Method, client IP, etc.). Nil matcher = always eligible.
2. **Selector pipeline**: apply `FailFilter` (exclude probe-marked entries) → `BackupFilter` (deprioritize backup entries) → strategy (round-robin, random, etc.) → pick one hop entry.
3. **Delegate**: `Select()` on the winning entry's underlying hop. The hop's own selector (with node-level failCodes) picks the final node.
```

