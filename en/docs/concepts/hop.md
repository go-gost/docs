# Hop

!!! tip "Dynamic configuration"
    Hop supports dynamic configuration via [Web API](/en/tutorials/api/overview/) when using reference mode.

Hop is an abstraction of the forwarding chain level and is the basic component of the forwarding chain. A hop contains one or more nodes, and a node [selector] (/concepts/selector/), each time a forwarding request is performed, by using the selector on each hop, the selector selects a node in the node group, and finally forms a route to process the request.

Hops are used in two ways: inline mode and reference mode.

## Inline Mode

Hops can be defined directly in the chain.

=== "CLI"

    ```
    gost -L http://:8080 -F https://192.168.1.1:8080 -F socks5+ws://192.168.1.2:1080
    ```

=== "File (YAML)"

    ```yaml hl_lines="12 20"
    services:
    - name: service-0
      addr: ":8080"
      handler:
        type: http
        chain: chain-0
      listener:
        type: tcp
    chains:
    - name: chain-0
      hops:
      - name: hop-0
        nodes:
        - name: node-0
          addr: 192.168.1.1:8080
          connector:
            type: http
          dialer:
            type: tls
      - name: hop-1
        nodes:
        - name: node-0
          addr: 192.168.1.2:1080
          connector:
            type: socks5
          dialer:
            type: ws
    ```

The above configuration has a chain (chain-0) with two hops (hop-0, hop-1) and one node in each hop.

## Reference Mode

It is also possible to define hops individually and then use a specific hop by referencing the name of it.

```yaml hl_lines="13 14 17 25"
services:
- name: service-0
  addr: ":8080"
  handler:
    type: http
    chain: chain-0
  listener:
    type: tcp

chains:
- name: chain-0
  hops:
  - name: hop-0
  - name: hop-1

hops:
- name: hop-0
  nodes:
  - name: node-0
    addr: 192.168.1.1:8080
    connector:
      type: http
	dialer:
      type: tls
- name: hop-1
  nodes:
  - name: node-0
    addr: 192.168.1.2:1080
    connector:
      type: socks5
    dialer:
      type: ws
```

The hops defined in `hops` are referenced by `name` in the chain.

### Forwarder

Hops can also be used in forwarder through reference mode.

```yaml hl_lines="9"
services:
- name: service-0
  addr: ":8080"
  handler:
    type: tcp 
  listener:
    type: tcp
  forwarder:
    name: hop-0

hops:
- name: hop-0
  nodes:
  - name: target-0
    addr: 192.168.1.1:8080
  - name: target-1
    addr: 192.168.1.2:8080
```

## Priority

When using inline mode, if no node is defined in the hop, it will automatically switch to reference mode.