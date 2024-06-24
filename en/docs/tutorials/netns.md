---
comments: true
---

# Network Namespace

!!! note "Limitation"
    Network namespaces are only supported on Linux system.

In Linux, system resources can be divided and isolated through [namespaces](https://en.wikipedia.org/wiki/Linux_namespaces), among which [network namespaces](https://lwn.net/Articles/580893/) is an important tool to achieve network virtualization. GOST can set different network namespaces for services and forwarding nodes, thereby providing the function of data intercommunication in different virtual networks.

## Namespace Creation and Configuration

The network namespace can be managed through the `ip` command:

```sh
# Create a network namespace ns1
ip netns add ns1
# Create veth pair veth0 and veth1 and move veth1 to ns1
ip link add dev veth0 type veth peer name veth1 netns ns1
# Configure the IP address of the veth0 interface to 10.0.0.11
ip addr add 10.0.0.11/24 dev veth0
# Enable veth0 interface
ip link set dev veth0 up
# Configure the IP address of the veth1 interface to 10.0.0.1 in namespace ns1
ip -n ns1 addr add 10.0.0.1/24 dev veth1
# Enalbe lo interface in namespace ns1
ip -n ns1 link set dev lo up
# Enable veth1 interface in namespace ns1
ip -n ns1 link set dev veth1 up
```

The above command creates a network namespace `ns1` and configures a veth type network interface `veth1` for it, connecting it to `veth0` in the current default network namespace.

You can view the network status of `ns1` through `ip -n ns1 addr`:

```
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host 
       valid_lft forever preferred_lft forever
2: veth1@if33: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group default qlen 1000
    link/ether b2:fd:33:f4:51:80 brd ff:ff:ff:ff:ff:ff link-netnsid 0
    inet 10.0.0.1/24 scope global veth1
       valid_lft forever preferred_lft forever
    inet6 fe80::b0fd:33ff:fef4:5180/64 scope link 
       valid_lft forever preferred_lft forever
```

Use the same method to create a network namespace `ns2`:

```sh
# Create a network namespace ns2.
ip netns add ns2
# Create veth pair veth2 and veth3 and move veth3 to ns2.
ip link add dev veth2 type veth peer name veth3 netns ns2
# Configure the IP address of the veth2 interface to 10.0.1.11
ip addr add 10.0.1.11/24 dev veth2
# Enable veth2 interface
ip link set dev veth2 up
# Configure the IP address of the veth3 interface to 10.0.1.1 in namespace ns2
ip -n ns2 addr add 10.0.1.1/24 dev veth3
# Enalbe lo interface in namespace ns2
ip -n ns2 link set dev lo up
# Enable veth3 interface in namespace ns2
ip -n ns2 link set dev veth3 up
```

You can view the network status of `ns2` through `ip -n ns2 addr`:

```
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host 
       valid_lft forever preferred_lft forever
2: veth3@if34: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group default qlen 1000
    link/ether 32:18:f0:6e:57:b3 brd ff:ff:ff:ff:ff:ff link-netnsid 0
    inet 10.0.1.1/24 scope global veth3
       valid_lft forever preferred_lft forever
    inet6 fe80::3018:f0ff:fe6e:57b3/64 scope link 
       valid_lft forever preferred_lft forever
```

## Using Network Namespaces

The network namespace in GOST has the following usages:

### Listening And Forwarding In Different Namespaces

=== "CLI"

    ```bash
    gost -L tcp://10.0.0.1:8000/:8000?netns=ns1
    ```

=== "File (YAML)"

    ```yaml hl_lines="13"
    services:
    - name: service-0
      addr: 10.0.0.1:8000
      handler:
        type: tcp
      listener:
        type: tcp
      forwarder:
        nodes:
        - name: target-0
          addr: :8080
      metadata:
        netns: ns1
    ```

The 8000 port of the service `service-0` listens in the network namespace `ns1`. When a connection is established with the :8000 node, it is in the default network namespace, which is equivalent to accessing the 8000 port service of the default namespace through the 8000 port in the network namespace `ns1`.

You can also specify the namespace where the forwarding is located through the `netns.out` option:

=== "CLI"

    ```bash
    gost -L "tcp://10.0.0.1:8000/10.0.1.1:8000?netns=ns1&netns.out=ns2"
    ```

=== "File (YAML)"

    ```yaml hl_lines="13"
    services:
    - name: service-0
      addr: 10.0.0.1:8000
      handler:
        type: tcp
      listener:
        type: tcp
      forwarder:
        nodes:
        - name: target-0
          addr: 10.0.1.1:8000
      metadata:
        netns: ns1
        netns.out: ns2
    ```

Mapping port 8000 in `ns1` to port 8000 in `ns2`.

### Using Chain

=== "CLI"

    ```bash
    gost -L tcp://10.0.0.1:8000/10.0.1.11:8000?netns=ns1 -F http://10.0.1.1:8080?netns=ns2
    ```

=== "File (YAML)"

    ```yaml hl_lines="14 20"
    services:
    - name: service-0
      addr: "10.0.0.1:8000"
      handler:
        type: tcp
        chain: chain-0
      listener:
        type: tcp
      forwarder:
        nodes:
        - name: target-0
          addr: 10.0.1.11:8000
      metadata:
        netns: ns1
    chains:
    - name: chain-0
      hops:
      - name: hop-0
        metadata:
          netns: ns2
        nodes:
        - name: node-0
          addr: 10.0.1.1:8080
          connector:
            type: http
          dialer:
            type: tcp
    ```

Listening on port 10.0.0.1:8000 in the `ns1` namespace, forwarded to the 10.0.1.11:8000 service in the default namespace through the 10.0.1.1:8080 proxy service in the `ns2` namespace.