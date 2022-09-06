# Selector

In GOST, the selection of nodes in a node group is done through node selector. The selector is responsible for selecting zero or one nodes in a node group using the node selection strategy. Selector can be applied to forwarding chains, hops, and forwarders. Node selectors are used in GOST for load balancing.

`strategy` (string, default=round)
:    Node selection strategy:
    
     * `round` - round robin
     * `rand` - random
     * `fifo` - top-down 

`maxFails` (int, default=1)
:    The maximum number of failed connections for a specified node, When the number of failed connections with a node exceeds this set value, the node will be marked as a dead node, dead node will not be selected to use.

`failTimeout` (duration, default=30s)
:    Specify the dead node's timeout period. When a node is marked as a dead node, it will not be selected within this set time interval. After this set time interval, it will participate in node selection again.

## Forwarding Chain

Selector can be set on the forwarding chain itself and each hop level in it. If no selector is set on the hop, the selector on the forwarding chain is used. The default selector uses the `round` strategy for node selection.

=== "CLI"
	```
	gost -L http://:8080 -F socks5://192.168.1.1:1080,192.168.1.2:1080?strategy=rand&maxFails=3&failTimeout=60s
	```

=== "File (YAML)"

    ```yaml
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
	  # chain level selector
      selector:
        strategy: round
        maxFails: 1
        failTimeout: 30s
      hops:
      - name: hop-0
	    # hop level selector
        selector:
          strategy: rand
          maxFails: 3
          failTimeout: 60s
        nodes:
        - name: node-0
          addr: 192.168.1.1:1080
          connector:
            type: socks5
          dialer:
            type: tcp
        - name: node-1
          addr: 192.168.1.2:1080
          connector:
            type: socks5
          dialer:
            type: tcp
	```

## Forwarder

Forwarder is used for port forwarding, it consists of a node group and a node selector. When forwarding is performed, zero or one node is selected from the node group for the forwarding destination address through the selector. The forwarder is now similar to a single-hop forwarding chain.

=== "CLI"
    ```
	gost -L "tcp://:8080/:8081,:8082?strategy=round&maxFails=1&failTimeout=30s
	```
=== "File (YAML)"

    ```yaml linenums="1" hl_lines="14 15 16 17"
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
          addr: :8081
        - name: target-1
          addr: :8082
        selector:
          strategy: round
          maxFails: 1
          failTimeout: 30s
    ```

## Chain Group

```yaml linenums="1" hl_lines="10 11 12 13"
services:
- name: service-0
  addr: ":8080"
  handler:
    type: http
    chainGroup:
      chains:
      - chain-0
      - chain-1
      selector:
        strategy: round
        maxFails: 1
        failTimeout: 10s
  listener:
    type: tcp
chains:
- name: chain-0
  hops:
  - name: hop-0
    nodes:
    - name: node-0
      addr: :8081
      connector:
        type: http
      dialer:
        type: tcp
- name: chain-1
  hops:
  - name: hop-0
    nodes:
    - name: node-0
      addr: :8082
      connector:
        type: http
      dialer:
        type: tcp
```

## Backup Node and Chain

By marking one or more nodes or chains as backup, all backup nodes or chains will only participate in selection when all non-backup nodes or chains are marked as failed.

### Backup Nodes

```yaml linenums="1" hl_lines="20 21 22 35 36 43 44"
services:
- name: service-0
  addr: :8080
  handler:
    type: http
    chain: chain-0
  listener:
    type: tcp
chains:
- name: chain-0
  selector:
    strategy: round
    maxFails: 1
    failTimeout: 10s
  hops:
  - name: hop-0
    nodes:
    - name: node-0
      addr: :8081
      metadata:
        maxFails: 3
        failTimeout: 30s
      connector:
        type: http
      dialer:
        type: tcp
    - name: node-1
      addr: :8082
      connector:
        type: http
      dialer:
        type: tcp
    - name: node-2
      addr: :8083
      metadata:
        backup: true
      connector:
        type: http
      dialer:
        type: tcp
    - name: node-3
      addr: :8084
      metadata:
        backup: true
      connector:
        type: http
      dialer:
        type: tcp
```

Mark nodes as backup via the `metadata.backup` option.

Under normal circumstances, only two non-backup nodes node-0 and node-1 participate in node selection. When both node-0 and node-1 are marked as failed, node-2 and node-3 will participate in node selection. When any one of node-0 and node-1 is recovered, node-2 and node-3 exit node selection.

!!! tip "Node-level Failure State Control"
    Pay attention to the node-0 node here, through the `metadata.maxFails` and `metadata.failTimeout` options, you can control the failure status of this node separately, and the corresponding parameters in the selector are used by default.

### Backup Chains

```yaml linenums="1" hl_lines="40 41 52 53"
services:
- name: service-0
  addr: :8080
  handler:
    type: http
    chainGroup:
      chains:
      - chain-0
      - chain-1
      - chain-2
      - chain-3
      selector:
        strategy: round
        maxFails: 1
        failTimeout: 10s
  listener:
    type: tcp
chains:
- name: chain-0
  hops:
  - name: hop-0
    nodes:
    - name: node-0
      addr: :8081
      connector:
        type: http
      dialer:
        type: tcp
- name: chain-1
  hops:
  - name: hop-0
    nodes:
    - name: node-0
      addr: :8082
      connector:
        type: http
      dialer:
        type: tcp
- name: chain-2
  metadata:
    backup: true
  hops:
  - name: hop-0
    nodes:
    - name: node-0
      addr: :8083
      connector:
        type: http
      dialer:
        type: tcp
- name: chain-3
  metadata:
    backup: true
  hops:
  - name: hop-0
    nodes:
    - name: node-0
      addr: :8084
      connector:
        type: http
      dialer:
        type: tcp
```

Similar to backup nodes, chains chain-2 and chain-3 are marked as backup via the `metadata.backup` option.

## Weighted Random Selection Strategy

The selector supports setting weights for nodes and chains based on the random selection strategy. The default weight is 1.

```yaml linenums="1" hl_lines="20 21 28 29"
services:
- name: service-0
  addr: :8080
  handler:
    type: auto
    chain: chain-0
  listener:
    type: tcp
chains:
- name: chain-0
  selector:
    strategy: rand
    maxFails: 1
    failTimeout: 10s
  hops:
  - name: hop-0
    nodes:
    - name: node-0
      addr: :8081
      metadata:
        weight: 20 
      connector:
        type: http
      dialer:
        type: tcp
    - name: node-1
      addr: :8082
      metadata: 
        weight: 10
      connector:
        type: http
      dialer:
        type: tcp
```

Set weights on nodes (or chains) via the `metadata.weight` option. The weight ratio of node-0 to node-1 is 2:1, so node-0 is twice as likely to be selected as node-1.
