# Transparent Proxy

Transparent proxy supports two modes: REDIRECT and TPROXY. The REDIRECT mode only supports TCP.

!!! note "Limitation"
    Transparent proxy is only available on Linux.

!!! tip "Traffic Sniffing"
    The TCP transparent proxy supports the detection of HTTP and TLS traffic. The HTTP `Host` header information or the `SNI` extension information of TLS is used as the target access address.

    Traffic sniffing is enabled through the `sniffing` option, which is not enabled by default.

## REDIRECT

Transparent proxy using REDIRECT can choose to mark packets. Using Mark requires administrator privileges to run.

### Without Mark

=== "CLI"
    ```
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
    ```
    iptables -t nat -A OUTPUT -p tcp --match multiport ! --dports 12345,1080 -j DNAT --to-destination 127.0.0.1:12345
    ```

### With Mark

Using Mark can avoid an infinite loop caused by secondary interception of egress traffic.

=== "CLI"
    ```
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

#### Forwarding Chain

=== "CLI"
    ```
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
    ```
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
    ```
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
          sniffing: true
          tproxy: true
      listener:
        type: red
        metadata:
          tproxy: true
    ```

#### Forwarding Chain

=== "CLI"
    ```
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
    ```
    ip rule add fwmark 1 lookup 100
    ip route add local 0.0.0.0/0 dev lo table 100

    iptables -t mangle -N DIVERT
    iptables -t mangle -A DIVERT -j MARK --set-mark 1
    iptables -t mangle -A DIVERT -j ACCEPT
    iptables -t mangle -A PREROUTING -p tcp -m socket -j DIVERT

    iptables -t mangle -N GOST
    iptables -t mangle -A GOST -p tcp -d 127.0.0.0/8 -j RETURN
    iptables -t mangle -A GOST -p tcp -d 192.168.0.0/16 -j RETURN
    iptables -t mangle -A GOST -p tcp -m mark --mark 100 -j RETURN 
    iptables -t mangle -A GOST -p tcp -j TPROXY --tproxy-mark 0x1/0x1 --on-ip 127.0.0.1 --on-port 12345 
    iptables -t mangle -A PREROUTING -p tcp -j GOST

    iptables -t mangle -N GOST_LOCAL
    iptables -t mangle -A GOST_LOCAL -p tcp -d 127.0.0.0/8 -j RETURN
    iptables -t mangle -A GOST_LOCAL -p tcp -d 255.255.255.255/32 -j RETURN
    iptables -t mangle -A GOST_LOCAL -p tcp -d 192.168.0.0/16 -j RETURN
    iptables -t mangle -A GOST_LOCAL -p tcp -m mark --mark 100 -j RETURN 
    iptables -t mangle -A GOST_LOCAL -p tcp -j MARK --set-mark 1
    iptables -t mangle -A OUTPUT -p tcp -j GOST_LOCAL
    ```

### UDP

=== "CLI"
    ```
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
    ```
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

!!! example "Routing and iptables Rules"
    ```
    ip rule add fwmark 1 lookup 100
    ip route add local 0.0.0.0/0 dev lo table 100

    iptables -t mangle -N GOST
    iptables -t mangle -A GOST -p udp -d 127.0.0.0/8 -j RETURN
    iptables -t mangle -A GOST -p udp -d 255.255.255.255/32 -j RETURN
    iptables -t mangle -A GOST -p udp -d 192.168.0.0/16 -j RETURN
    iptables -t mangle -A GOST -p udp -m mark --mark 100 -j RETURN 
    iptables -t mangle -A GOST -p udp -j TPROXY --tproxy-mark 0x1/0x1 --on-ip 127.0.0.1 --on-port 12345 
    iptables -t mangle -A PREROUTING -p udp -j GOST

    iptables -t mangle -N GOST_LOCAL
    iptables -t mangle -A GOST_LOCAL -p udp -d 127.0.0.0/8 -j RETURN
    iptables -t mangle -A GOST_LOCAL -p udp -d 255.255.255.255/32 -j RETURN
    iptables -t mangle -A GOST_LOCAL -p udp -d 192.168.0.0/16 -j RETURN
    iptables -t mangle -A GOST_LOCAL -p udp -m mark --mark 100 -j RETURN 
    iptables -t mangle -A GOST_LOCAL -p udp -j MARK --set-mark 1
    iptables -t mangle -A OUTPUT -p udp -j GOST_LOCAL
    ```