# Multi-homed Hosts

Hosts that have more than one network interface usually have one Internet Protocol (IP) address for each interface. Such hosts are called multi-homed hosts.

When a host is multi-homed host, different network exits can be specified for routes of different services as required.

!!! note "Limitation"
	Multiple network interface configurations are only supported on Linux systems.

## `interface` Option

Use the `interface` option to specify the network exit to use. The value of the `interface` option can be either a network interface name (such as `eth0`) or the IP address (IPv4 or IPv6) of a network interface.

=== "CLI"
    ```
	gost -L :8080?interface=eth0
	```

=== "File (YAML)"

    ```yaml
	services:
	- name: service-0
	  addr: ":8080"
	  interface: eth0
	  # or use IP address
	  # interface: 192.168.0.123
	  handler:
		type: auto
	  listener:
		type: tcp
	```

## Forwarding Chain

If a forwarding chain is used, a network exit needs to be set up at the first level hop of the forwarding chain or on a node within it.
If the `interface` option is not set on the node, the option on the hop is used.
The `interface` option on the command line corresponds to the option on the hop.

=== "CLI"
    ```
	gost -L :8080 -F :8000?interface=192.168.0.1 
	```

=== "File (YAML)"

    ```yaml
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
	    # hop level interface
        interface: 192.168.0.1
        nodes:
        - name: node-0
          addr: :8000
		  # node level interface
		  interface: eth0
          connector:
            type: http
          dialer:
            type: tcp
	```

## Direct Connection Mode

If the service does not need to use an upper-stream proxy, you can use [direct connection node] (/en/concepts/chain/) to allow the service to use multiple network interfaces for load balancing.

=== "File (YAML)"

    ```yaml
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
          addr: :0
		  interface: eth0
          connector:
            type: direct
          dialer:
            type: direct
        - name: node-1
          addr: :0
		  interface: eth1
          connector:
            type: direct
          dialer:
            type: direct
	```