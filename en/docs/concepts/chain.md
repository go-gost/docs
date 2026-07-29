---
comments: true
---

# Forwarding Chain

!!! tip "Dynamic configuration"
    Forwarding chain supports dynamic configuration via [Web API](../tutorials/api/overview.md).

Forwarding chain is a list of node groups formed by several nodes grouped according to a specific level. Each level of node group is a hop, and data is forwarded through each hop in turn. Forwarding chain is an important module in GOST, it is the link for establishing connections between services.

The nodes in the forwarding chain are independent of each other, and each node can use different data channels and data processing protocols independently.

=== "CLI"

	```bash
	gost -L http://:8080 -F https://192.168.1.1:8080 -F socks5+ws://192.168.1.2:1080
	```

	All `-F` parameters on the command line form a forwarding chain, and all services use this forwarding chain.

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
	Listeners or handlers of a service use the specified forwarding chain by referring to the forwarding chain's name via the `chain` property.

## Node Group

Each hop level can add multiple nodes to form a node group.

=== "CLI"

	```bash
	gost -L http://:8080 -F https://192.168.1.1:8080,192.168.1.1:8081,192.168.1.2:8082 -F socks5+ws://192.168.0.1:1080,192.168.0.1:1081,192.168.0.2:1082
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
	  hops:
	  - name: hop-0
		nodes:
		- name: node-0
		  addr: 192.168.1.1:8080
		  connector:
			type: http
		  dialer:
		    type: tls
		- name: node-1
		  addr: 192.168.1.1:8081
		  connector:
			type: http
		  dialer:
		    type: tls
		- name: node-2
		  addr: 192.168.1.2:8082
		  connector:
			type: http
		  dialer:
		    type: tls
	  - name: hop-1
		nodes:
		- name: node-0
		  addr: 192.168.0.1:1080
		  connector:
			type: socks5
		  dialer:
		    type: ws
		- name: node-1
		  addr: 192.168.0.1:1081
		  connector:
			type: socks5
		  dialer:
		    type: ws
		- name: node-2
		  addr: 192.168.0.2:1082
		  connector:
			type: socks5
		  dialer:
		    type: ws
	```

There are three nodes in the first hop level (hop-0): 192.168.1.1:8080(node-0), 192.168.1.1:8081(node-1), 192.168.1.2:8082(node-2). They use the same node configuration.

There are three nodes in the second hop level (hop-1): 192.168.0.1:1080(node-0)，192.168.0.1:1081(node-1)，192.168.0.2:1082(node-2). They use the same node configuration.

If you need to configure each node freely, you can use the configuration file.

!!! example "Multiple types"

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
	  hops:
	  - name: hop-0
		nodes:
		- name: node-0
		  addr: 192.168.1.1:8080
		  connector:
			type: http
		  dialer:
		    type: tls
		- name: node-1
		  addr: 192.168.1.1:8081
		  connector:
			type: socks5
		  dialer:
		    type: ws
		- name: node-2
		  addr: 192.168.1.2:8082
		  connector:
			type: relay
		  dialer:
		    type: tls
	  - name: hop-1
		nodes:
		- name: node-0
		  addr: 192.168.0.1:1080
		  connector:
			type: socks5
		  dialer:
		    type: ws
		- name: node-1
		  addr: 192.168.0.1:1081
		  connector:
			type: relay
		  dialer:
		    type: tls
		- name: node-2
		  addr: 192.168.0.2:1082
		  connector:
			type: http
		  dialer:
		    type: h2
	```

## Multiple Forwarding Chains

Multiple forwarding chains can be set in the configuration file, and different services can use different forwarding chains according to the chain names.

!!! example

    ```yaml
	services:
	- name: service-0
	  addr: ":8080"
	  handler:
		type: http
		chain: chain-0
	  listener:
		type: tcp
	- name: service-1
	  addr: ":1080"
	  handler:
		type: socks5
		chain: chain-1
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
	- name: chain-1
	  hops:
	  - name: hop-0
		nodes:
		- name: node-0
		  addr: 192.168.1.2:8082
		  connector:
			type: relay
		  dialer:
		    type: tls
	  - name: hop-1
		nodes:
		- name: node-0
		  addr: 192.168.0.1:1080
		  connector:
			type: socks5
		  dialer:
		    type: ws
		- name: node-1
		  addr: 192.168.0.1:1081
		  connector:
			type: relay
		  dialer:
		    type: tls
	```

The service `service-0` uses the forwarding chain `chain-0`, and the service `service-1` uses the forwarding chain `chain-1`.

## Chain Group

Listener or handler of a service can also use the `chainGroup` parameter to specify a chain group to use multiple chains. You can also set a [Selector](selector.md) to specify the usage of the chains, the default selector strategy is round-robin.

!!! example "Chain Group"

    ```yaml
	services:
	- name: service-0
	  addr: ":8080"
	  handler:
		type: http
		chainGroup:
		  chains:
		  - chain: chain-0
		  - chain: chain-1
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

The service service-0 uses two chains chain-0 and chain-1 in a round-robin manner.

### Matcher

:material-tag: 3.3.0

Each chain entry can carry a `matcher` rule. Only entries whose matcher matches the
current request are eligible for selection — see [Matcher](matcher.md) for the full
DSL reference.

At the chain-group level, the matcher sees the target hostname from the request
(via `Host()` matcher).

```yaml hl_lines="7 8 9"
services:
- name: service-0
  addr: ":8080"
  handler:
    type: http
    chainGroup:
      chains:
      - chain: chain-api
        matcher:
          rule: Host(`api.example.com`)
      - chain: chain-web
        matcher:
          rule: Host(`*.example.com`)
      - chain: chain-default
      selector:
        strategy: round
  listener:
    type: tcp
```

!!! note "Backward compatibility"
    Chain entries accept either a plain string (old format: `chains: [chain-0, chain-1]`)
    or a structured object with `chain`, `matcher`, and `probe` fields.

### Probe

:material-tag: 3.3.0

A chain entry can have a `probe` that health-checks the entire chain end-to-end. The
probe dials through the chain's route to a target address on a periodic interval. If
the probe fails, the chain entry's marker is set — `FailFilter` in the group selector
excludes it from selection until it recovers.

Supported probe types: `tcp`, `http`, `cmd`. The probe uses the chain's full
`Route.Dial()` path, testing every hop.

```yaml hl_lines="7 8 9 10 11"
services:
- name: service-0
  addr: ":8080"
  handler:
    type: http
    chainGroup:
      chains:
      - chain: chain-primary
        probe:
          type: tcp
          addr: 127.0.0.1:8081
          interval: 10s
      - chain: chain-fallback
        probe:
          type: http
          addr: 127.0.0.1:8082
          httpPath: /health
          interval: 5s
      selector:
        strategy: round
        maxFails: 1
        failTimeout: 30s
  listener:
    type: tcp
```

!!! note "Probe marker independence"
    The probe marks the chain entry's own marker — it is independent of any
    node-level markers inside the chain. Node-level `failCodes` and chain-level
    probes do not interfere.

### Selection Flow

1. **Matcher filter** — build eligible pool from entries whose matcher matches the
   request context (hostname, client IP, etc.). Nil matcher = always eligible.
2. **Selector pipeline** — apply `FailFilter` (exclude probe-marked entries) →
   `BackupFilter` → strategy (round-robin, random, etc.) → pick one chain entry.
3. **Route** — delegate to the winning entry's `Route()` method, which selects
   nodes from each hop of the chain.

## Virtual Node

If the service does not need to use an upper-stream proxy, a special virtual node (`connector.type` and `dialer.type` are both `virtual`) can be used to directly connect to the target address, and the node does not require a corresponding server, so the `addr` parameter of the node is ignored.

=== "CLI"

    ```bash
    gost -L :8080 -F direct://:0?interface=eth0
    ```

=== "File (YAML)"

    ```yaml hl_lines="17 18 19 20"
    services:
    - name: service-0
      addr: ":8080"
      handler:
        type: auto
        chain: chain-0
      listener:
        type: tcp
      chains:
      - name: chain-0
        hops:
        - name: hop-0
          nodes:
          - name: node-0
            interface: eth0
            connector:
              type: virtual
            dialer:
              type: virtual
          - name: node-1
            interface: eth1
            connector:
              type: virtual
              # metadata:
              #   action: reject
            dialer:
              type: virtual
	```

Here node-0 and node-1 are virtual nodes. When the host is [multi-homed] (../tutorials/multi-homed.md), you can specify different interfaces for each node through the `interface` parameter, so that achieve load balancing at the network egress level.

You can also reject all connections by setting `connector.metadata.action` to `reject`.

!!! caution "Limitation"
	If the data channel of the node uses the UDP protocol, such as QUIC, KCP, etc., this node can only be used for the first level of the forwarding chain.