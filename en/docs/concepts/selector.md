# Node Selection

## Selector

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
	gost -L "tcp://:8080/192.168.1.1:8081,192.168.1.2:8082?strategy=round&maxFails=1&failTimeout=30s
	```
=== "File (YAML)"

    ```yaml
	services:
	- name: service-0
	  addr: :8080
	  handler:
		type: tcp
	  listener:
		type: tcp
	  forwarder:
		targets:
		- 192.168.1.1:8081
		- 192.168.1.2:8082
		selector:
		  strategy: round
		  maxFails: 1
		  failTimeout: 30s
	```

## Load Balancing

Through the combination of node groups and selectors, we can achieve the function of load balancing in data forwarding.