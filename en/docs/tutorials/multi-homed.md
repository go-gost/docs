---
comments: true
---

# Multi-homed Hosts

Hosts that have more than one network interface usually have one Internet Protocol (IP) address for each interface. Such hosts are called multi-homed hosts.

When a host is multi-homed host, different network exits can be specified for routes of different services as required.

!!! note "Limitation"
	Multiple network interface configurations are only supported on Linux/Windows/Darwin systems.

## `interface` Option

Use the `interface` option to specify the network exit to use. The value of the `interface` option can be the name of a network interface (`eth0`), the IP address (IPv4 or IPv6) of a network interface, or the IP address list separated by `,`.

=== "CLI"

    ```bash
    gost -L :8080?interface=eth0
    ```

=== "File (YAML)"

    ```yaml
    services:
    - name: service-0
      addr: ":8080"
      metadata:
        interface: eth0
        # or use IP address
        # interface: 192.168.0.123
        # or IP address list
        # interface: fd::1,192.168.0.123
      handler:
        type: auto
      listener:
        type: tcp
    ```

!!! note "Strict Mode"
    When specifying a list of interfaces, you can append `!`to each entry to mark as strict mode: `interface=192.168.0.100,192.168.0.101!,192.168.0.102`,
    If the connection fails to be established through 192.168.0.101, it will not continue to try 192.168.0.102.

## Forwarding Chain

If a forwarding chain is used, a network exit needs to be set up at the first level hop of the forwarding chain or on a node within it.
If the `interface` option is not set on the node, the option on the hop is used.
The `interface` option on the command line corresponds to the option on the hop.

=== "CLI"

    ```bash
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

If the service does not need to use an upper-stream proxy, you can use [Virtual Node](../concepts/chain.md) to allow the service to use multiple network interfaces for load balancing.

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
            type: virtual
          dialer:
            type: virtual
        - name: node-1
          addr: :0
		  interface: eth1
          connector:
            type: virtual
          dialer:
            type: virtual
	```