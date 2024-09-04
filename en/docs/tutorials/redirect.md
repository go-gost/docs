---
comments: true
---

# Transparent Proxy

Transparent proxy supports two modes: REDIRECT and TPROXY. The REDIRECT mode only supports TCP.

!!! note "Limitation"
    Transparent proxy is only available on Linux.

!!! tip "Traffic Sniffing"
    The TCP transparent proxy supports the detection of HTTP and TLS traffic. The HTTP `Host` header information or the `SNI` extension information of TLS is used as the target access address.

    Traffic sniffing is enabled through the `sniffing` option, which is not enabled by default.

     If the SNI information is not sniffed for HTTPS traffic, you can enable the `sniffing.fallback` option and try to connect again using the original target address.

## REDIRECT

Transparent proxy using REDIRECT can choose to mark packets. Using Mark requires administrator privileges to run.

### Without Mark

=== "CLI"

    ```bash
    gost -L red://:12345?sniffing=true -F 192.168.1.1:1080
    ```

=== "File (YAML)"

    ```yaml
    services:
    - name: service-0
      addr: :12345
      handler:
        type: red
        chain: chain-0
        metadata:
          sniffing: true
          sniffing.timeout: 5s
          sniffing.fallback: true
      listener:
        type: red
    chains:
    - name: chain-0
      hops:
      - name: hop-0
        nodes:
        - name: node-0
          addr: 192.168.1.1:1080
          connector:
            type: http
          dialer:
            type: tcp
    ```


!!! example "iptables-Local Global TCP Proxy"

    ```bash
    iptables -t nat -A OUTPUT -p tcp --match multiport ! --dports 12345,1080 -j DNAT --to-destination 127.0.0.1:12345
    ```

### With Mark

Using Mark can avoid an infinite loop caused by secondary interception of egress traffic.

=== "CLI"

    ```bash
    gost -L "red://:12345?sniffing=true&so_mark=100"
    ```

=== "File (YAML)"

    ```yaml
    services:
    - name: service-0
      addr: :12345
      sockopts:
        mark: 100
      handler:
        type: red
        metadata:
          sniffing: true
      listener:
        type: red
    ```

### Forwarding Chain

=== "CLI"

    ```bash
    gost -L red://:12345?sniffing=true -F "http://192.168.1.1:1080?so_mark=100"
    ```

=== "File (YAML)"

    ```yaml
    services:
    - name: service-0
      addr: :12345
      handler:
        type: red
        chain: chain-0
        metadata:
          sniffing: true
      listener:
        type: red
    chains:
    - name: chain-0
      hops:
      - name: hop-0
        sockopts:
          mark: 100  
        nodes:
        - name: node-0
          addr: 192.168.1.1:1080
          # node level sockopts, will override hop level value.
          # sockopts:
          #   mark: 100  
          connector:
            type: http
          dialer:
            type: tcp
    ```

Set the mark value via the `so_mark` (command line) or `sockopts` (config file) parameter.

!!! example "iptables Rules"

    ```bash
    iptables -t nat -N GOST
    # Ignore LAN traffic, please adjust it according to the actual network environment
    iptables -t nat -A GOST -d 192.168.0.0/16 -j RETURN
    # Ignore egress traffic
    iptables -t nat -A GOST -p tcp -m mark --mark 100 -j RETURN
    # Redirect TCP traffic to port 12345
    iptables -t nat -A GOST -p tcp -j REDIRECT --to-ports 12345
    # Intercept LAN traffic
    iptables -t nat -A PREROUTING -p tcp -j GOST
    iptables -t nat -A OUTPUT -p tcp -j GOST
    ```

## TPROXY

### TCP

=== "CLI"

    ```bash
    gost -L "red://:12345?sniffing=true&tproxy=true&so_mark=100"
    ```

=== "File (YAML)"

    ```yaml
    services:
    - name: service-0
      addr: :12345
      sockopts:
        mark: 100  
      handler:
        type: red
        metadata:
          tproxy: true
          sniffing: true
          sniffing.timeout: 5s
          sniffing.fallback: true
      listener:
        type: red
        metadata:
          tproxy: true
    ```

#### Forwarding Chain

=== "CLI"

    ```bash
    gost -L "red://:12345?sniffing=true&tproxy=true" -F http://192.168.1.1:8080?so_mark=100
    ```

=== "File (YAML)"

    ```yaml
    services:
    - name: service-0
      addr: :12345
      handler:
        type: red
        chain: chain-0
        metadata:
          sniffing: true
          tproxy: true
      listener:
        type: red
        metadata:
          tproxy: true
    chains:
    - name: chain-0
      hops:
      - name: hop-0
        sockopts:
          mark: 100  
        nodes:
        - name: node-0
          addr: 192.168.1.1:8080
          connector:
            type: http
          dialer:
            type: tcp
    ```

!!! example "Routing and iptables Rules"

    ```bash
    # ipv4
    ip rule add fwmark 1 lookup 100
    ip route add local default dev lo table 100

    iptables -t mangle -N DIVERT
    iptables -t mangle -A DIVERT -j MARK --set-mark 1
    iptables -t mangle -A DIVERT -j ACCEPT
    iptables -t mangle -A PREROUTING -p tcp -m socket -j DIVERT

    iptables -t mangle -N GOST
    iptables -t mangle -A GOST -p tcp -d 127.0.0.0/8 -j RETURN
    iptables -t mangle -A GOST -p tcp -d 192.168.0.0/16 -j RETURN
    iptables -t mangle -A GOST -p tcp -m mark --mark 100 -j RETURN 
    iptables -t mangle -A GOST -p tcp -j TPROXY --tproxy-mark 0x1/0x1 --on-port 12345 
    iptables -t mangle -A PREROUTING -p tcp -j GOST

    # Only for local mode
    iptables -t mangle -N GOST_LOCAL
    iptables -t mangle -A GOST_LOCAL -p tcp -d 127.0.0.0/8 -j RETURN
    iptables -t mangle -A GOST_LOCAL -p tcp -d 255.255.255.255/32 -j RETURN
    iptables -t mangle -A GOST_LOCAL -p tcp -d 192.168.0.0/16 -j RETURN
    iptables -t mangle -A GOST_LOCAL -p tcp -m mark --mark 100 -j RETURN 
    iptables -t mangle -A GOST_LOCAL -p tcp -j MARK --set-mark 1
    iptables -t mangle -A OUTPUT -p tcp -j GOST_LOCAL

    # ipv6
    ip -6 rule add fwmark 1 lookup 100
    ip -6 route add local default dev lo table 100
    ip6tables -t mangle -N DIVERT
    ip6tables -t mangle -A DIVERT -j MARK --set-mark 1
    ip6tables -t mangle -A DIVERT -j ACCEPT
    ip6tables -t mangle -A PREROUTING -p tcp -m socket -j DIVERT

    ip6tables -t mangle -N GOST
    ip6tables -t mangle -A GOST -p tcp -d ::/128 -j RETURN
    ip6tables -t mangle -A GOST -p tcp -d ::1/128 -j RETURN
    ip6tables -t mangle -A GOST -p tcp -d fe80::/10 -j RETURN
    ip6tables -t mangle -A GOST -p tcp -d ff00::/8 -j RETURN
    ip6tables -t mangle -A GOST -p tcp -m mark --mark 100 -j RETURN 
    ip6tables -t mangle -A GOST -p tcp -j TPROXY --tproxy-mark 0x1/0x1 --on-port 12345 
    ip6tables -t mangle -A PREROUTING -p tcp -j GOST

    # Only for local mode
    ip6tables -t mangle -N GOST_LOCAL
    ip6tables -t mangle -A GOST_LOCAL -p tcp -d ::/128 -j RETURN
    ip6tables -t mangle -A GOST_LOCAL -p tcp -d ::1/128 -j RETURN
    ip6tables -t mangle -A GOST_LOCAL -p tcp -d fe80::/10 -j RETURN
    ip6tables -t mangle -A GOST_LOCAL -p tcp -d ff00::/8 -j RETURN
    ip6tables -t mangle -A GOST_LOCAL -p tcp -m mark --mark 100 -j RETURN 
    ip6tables -t mangle -A GOST_LOCAL -p tcp -j MARK --set-mark 1
    ip6tables -t mangle -A OUTPUT -p tcp -j GOST_LOCAL
    ```

### UDP

=== "CLI"

    ```bash
    gost -L "redu://:12345?ttl=30s&so_mark=100"
    ```

=== "File (YAML)"

    ```yaml
    services:
    - name: service-0
      addr: :12345
      sockopts:
        mark: 100  
      handler:
        type: redu
      listener:
        type: redu
        metadata:
          ttl: 30s
    ```

#### Forwarding Chain

=== "CLI"

    ```bash
    gost -L redu://:12345?ttl=30s -F relay://192.168.1.1:8421?so_mark=100
    ```

=== "File (YAML)"

    ```yaml
    services:
    - name: service-0
      addr: :12345
      handler:
        type: redu
        chain: chain-0
      listener:
        type: redu
        metadata:
          ttl: 30s
    chains:
    - name: chain-0
      hops:
      - name: hop-0
        sockopts:
          mark: 100  
        nodes:
        - name: node-0
          addr: 192.168.1.1:8421
          connector:
            type: relay
          dialer:
            type: tcp
    ```

`ttl` (duration, default=30s)
:    UDP tunnel timeout period.

`readBufferSize` (int, default=4096)
:    UDP read buffer size


!!! example "Routing and iptables Rules"

    ```bash
    # ipv4
    ip rule add fwmark 1 lookup 100
    ip route add local default dev lo table 100

    iptables -t mangle -N GOST
    iptables -t mangle -A GOST -p udp -d 127.0.0.0/8 -j RETURN
    iptables -t mangle -A GOST -p udp -d 255.255.255.255/32 -j RETURN
    iptables -t mangle -A GOST -p udp -d 192.168.0.0/16 -j RETURN
    iptables -t mangle -A GOST -p udp -m mark --mark 100 -j RETURN 
    iptables -t mangle -A GOST -p udp -j TPROXY --tproxy-mark 0x1/0x1 --on-port 12345 
    iptables -t mangle -A PREROUTING -p udp -j GOST

    # Only for local mode
    iptables -t mangle -N GOST_LOCAL
    iptables -t mangle -A GOST_LOCAL -p udp -d 127.0.0.0/8 -j RETURN
    iptables -t mangle -A GOST_LOCAL -p udp -d 255.255.255.255/32 -j RETURN
    iptables -t mangle -A GOST_LOCAL -p udp -d 192.168.0.0/16 -j RETURN
    iptables -t mangle -A GOST_LOCAL -p udp -m mark --mark 100 -j RETURN 
    iptables -t mangle -A GOST_LOCAL -p udp -j MARK --set-mark 1
    iptables -t mangle -A OUTPUT -p udp -j GOST_LOCAL

    # ipv6
    ip -6 rule add fwmark 1 lookup 100
    ip -6 route add local default dev lo table 100

    ip6tables -t mangle -N GOST
    ip6tables -t mangle -A GOST -p udp -d ::/128 -j RETURN
    ip6tables -t mangle -A GOST -p udp -d ::1/128 -j RETURN
    ip6tables -t mangle -A GOST -p udp -d fe80::/10 -j RETURN
    ip6tables -t mangle -A GOST -p udp -d ff00::/8 -j RETURN
    ip6tables -t mangle -A GOST -p udp -m mark --mark 100 -j RETURN 
    ip6tables -t mangle -A GOST -p udp -j TPROXY --tproxy-mark 0x1/0x1 --on-port 12345 
    ip6tables -t mangle -A PREROUTING -p udp -j GOST

    # Only for local mode
    ip6tables -t mangle -N GOST_LOCAL
    ip6tables -t mangle -A GOST_LOCAL -p udp -d ::/128 -j RETURN
    ip6tables -t mangle -A GOST_LOCAL -p udp -d ::1/128 -j RETURN
    ip6tables -t mangle -A GOST_LOCAL -p udp -d fe80::/10 -j RETURN
    ip6tables -t mangle -A GOST_LOCAL -p udp -d ff00::/8 -j RETURN
    ip6tables -t mangle -A GOST_LOCAL -p udp -m mark --mark 100 -j RETURN 
    ip6tables -t mangle -A GOST_LOCAL -p udp -j MARK --set-mark 1
    ip6tables -t mangle -A OUTPUT -p udp -j GOST_LOCAL
    ```

## Playground

The network namespace allows you to build a test environment on a single machine without affecting the normal network settings. Here, ns1 is used to simulate the gateway, ns2 is used to simulate the client, and the default namespace is used to simulate the target host.

Create a new network namespace ns1, and interconnect it with the default namespace through veth0 (10.0.10.1/24) and veth1 (10.0.10.2/24) pair.

```bash
ip netns add ns1
ip link add dev veth0 type veth peer name veth1 netns ns1
ip addr add 10.0.10.1/24 dev veth0
ip link set dev veth0 up
ip -n ns1 addr add 10.0.10.2/24 dev veth1
ip -n ns1 link set dev lo up
ip -n ns1 link set dev veth1 up
```

Create a new network namespace ns2, and interconnect namespace ns2 with ns1 through veth2 (10.0.20.1/24) and veth3 (10.0.20.2/24) pair. Namespace ns2 uses ns1 as the gateway.

```bash
ip netns add ns2
ip netns exec ns1 ip link add veth2 type veth peer name veth3 netns ns2
ip netns exec ns1 ip addr add 10.0.20.1/24 dev veth2
ip netns exec ns1 ip link set veth2 up
ip netns exec ns2 ip addr add 10.0.20.2/24 dev veth3
ip netns exec ns2 ip link set veth3 up
ip netns exec ns2 ip link set lo up
ip netns exec ns2 ip route add default via 10.0.20.1 dev veth3
```

Configure routing and iptables rules in namespace ns1.

```bash
ip netns exec ns1 ip rule add fwmark 1 lookup 100
ip netns exec ns1 ip route add local default dev lo table 100

# TCP
ip netns exec ns1 iptables -t mangle -N DIVERT
ip netns exec ns1 iptables -t mangle -A DIVERT -j MARK --set-mark 1
ip netns exec ns1 iptables -t mangle -A DIVERT -j ACCEPT
ip netns exec ns1 iptables -t mangle -A PREROUTING -p tcp -m socket -j DIVERT

ip netns exec ns1 iptables -t mangle -N GOST
ip netns exec ns1 iptables -t mangle -A GOST -p tcp -d 127.0.0.0/8 -j RETURN
ip netns exec ns1 iptables -t mangle -A GOST -p tcp -d 255.255.255.255/32 -j RETURN
ip netns exec ns1 iptables -t mangle -A GOST -p tcp -m mark --mark 100 -j RETURN 
ip netns exec ns1 iptables -t mangle -A GOST -p tcp -j TPROXY --tproxy-mark 0x1/0x1 --on-port 12345 
ip netns exec ns1 iptables -t mangle -A PREROUTING -p tcp -j GOST

# UDP
ip netns exec ns1 iptables -t mangle -A GOST -p udp -d 127.0.0.0/8 -j RETURN
ip netns exec ns1 iptables -t mangle -A GOST -p udp -d 255.255.255.255/32 -j RETURN
ip netns exec ns1 iptables -t mangle -A GOST -p udp -m mark --mark 100 -j RETURN 
ip netns exec ns1 iptables -t mangle -A GOST -p udp -j TPROXY --tproxy-mark 0x1/0x1 --on-port 12345 
ip netns exec ns1 iptables -t mangle -A PREROUTING -p udp -j GOST
```

Start relay service in default namespace.

```bash
gost -L relay://:8420
```

Run GOST transparent proxy (TCP/UDP) in namespace ns1 and forward through the relay proxy service of the default namespace.

```bash
ip netns exec ns1 gost -L "red://:12345?tproxy=true" -L "redu://:12345?ttl=30s" -F "relay://10.0.10.1:8420?so_mark=100"
```

Run the iperf3 service in the default namespace.

```bash
iperf3 -s
```

Execute iperf test in namespace ns2.

```bash
# TCP
ip netns exec ns2 iperf3 -c 10.0.10.1

# UDP
ip netns exec ns2 iperf3 -c 10.0.10.1 -u
```

Cleaning

```bash
ip netns delete ns1
ip netns delete ns2
```

