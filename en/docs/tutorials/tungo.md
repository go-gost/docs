---
comments: true
---

#  TUN2SOCKS 

:material-tag: 3.2.0

GOST support for tun2socks depends on the [xjasonlyu/tun2socks](https://github.com/xjasonlyu/tun2socks) library.

In the previous TUN related tutorials([TUN/TAP Device](tuntap.md) and [Routing Tunnel](routing-tunnel.md)), TUN is used to establish a point-to-point tunnel. The network layer IP packets are received through the TUN device, then the packets are not processed again and are directly transmitted to the other end through the tunnel.

Tun2socks fully implements the network protocol stack on top of the TUN device, so that the received IP packets are processed through the protocol stack and finally the transport layer TCP/UDP data are parsed, so that more control can be exercised over the data. From the perspective of usage, tun2socks has similar functions to [transparent proxy](redirect.md), but it is much more versatile and easier to use than the latter.

!!! note "Limitation"
    TUNGO currently supports Linux, Windows, and MacOS systems.

!!! note "Windows"
    You need to download a platform-specific `wintun.dll` file from [wintun](https://www.wintun.net/), and put it side-by-side with gost.

## TUNGO - TUN2SOCKS for GOST

The tun2socks module in GOST is called TUNGO. Based on the original tun2socks, it uses the existing functional modules of GOST, such as chain, traffic sniffing, and bypass, to control the traffic more accurately.

Here it is assumed that the system's primary network interface is `eth0` and the default gateway is 192.168.1.1.

### Linux

=== "CLI"

    ```sh
    gost -L "tungo://:0?name=tungo&net=192.168.123.1/24&mtu=1420&dns=1.1.1.1" -F "relay+wss://SERVER_IP:443?interface=eth0"
    ```
    
    Update routing table:

    ```sh
    # Delete the default route
    ip route delete default
    # Set eth0 as the backup gateway
    ip route add default via 192.168.1.1 dev eth0 metric 10
    # Set tungo as the primary gateway. If the metric of eht0 is greater than 1, the above two commands can be ignored.
    ip route add default dev tungo metric 1
    # IPv6
    # ip -6 route add default dev tungo metric 1
    ```

=== "File (YAML)"

    ```yaml
    services:
    - name: service-0
      addr: :0
      handler:
        type: tungo
        chain: chain-0
        metadata:
          udpTimeout: 30s   # UDP session timeout
      listener:
        type: tungo
        metadata:
          name: tungo    # default name is tungo
          net: 192.168.123.1/24
          mtu: 1420      # default mtu is 1420
          dns: 1.1.1.1   # dns server
      metadata:
        postUp:   # Automatically update the routing table through service postUp
        - ip route delete default
        - ip route add default via 192.168.1.1 dev eth0 metric 10
        - ip route add default dev tungo metric 1
        # - ip -6 route add default dev tungo metric 1

    chains:
    - name: chain-0
      hops:
      - name: hop-0
        metadata:
          interface: eth0
        nodes:
        - name: node-0
          addr: SERVER_IP:443
          connector:
            type: relay
          dialer:
            type: wss
    ```

### Windows

=== "CLI"

    ```sh
    gost -L "tungo://:0?name=tungo&net=192.168.123.1/24&mtu=1420&dns=1.1.1.1" -F "relay+wss://SERVER_IP:443?interface=eth0"
    ```
    
    Update routing table:

    ```sh
    netsh interface ipv4 add route 0.0.0.0/0 tungo 192.168.123.1 metric=1
    ```

=== "File (YAML)"

    ```yaml
    services:
    - name: service-0
      addr: :0
      handler:
        type: tungo
        chain: chain-0
        metadata:
          udpTimeout: 30s   # UDP session timeout
      listener:
        type: tungo
        metadata:
          name: tungo    # default name is tungo
          net: 192.168.123.1/24
          mtu: 1420      # default mtu is 1420
          dns: 1.1.1.1   # dns server
      metadata:
        postUp:   # Automatically update the routing table through service postUp
        - netsh interface ipv4 add route 0.0.0.0/0 tungo 192.168.123.1 metric=1

    chains:
    - name: chain-0
      hops:
      - name: hop-0
        metadata:
          interface: eth0
        nodes:
        - name: node-0
          addr: SERVER_IP:443
          connector:
            type: relay
          dialer:
            type: wss
    ```

### MacOS

=== "CLI"

    ```sh
    gost -L "tungo://:0?name=tungo&net=192.168.123.1/24&mtu=1420&route=1.0.0.0/8,2.0.0.0/8" -F "relay+wss://SERVER_IP:443?interface=eth0"
    ```

=== "File (YAML)"

    ```yaml
    services:
    - name: service-0
      addr: :0
      handler:
        type: tungo
        chain: chain-0
        metadata:
          udpTimeout: 30s   # UDP session timeout
      listener:
        type: tungo
        metadata:
          name: tungo    # default name is tungo
          net: 192.168.123.1/24
          mtu: 1420      # default mtu is 1420
          dns: 1.1.1.1   # dns server
      metadata:
        postUp:   # Automatically update the routing table through service postUp
        - route add -net 1.0.0.0/8 192.168.123.1
        - route add -net 2.0.0.0/8 192.168.123.1

    chains:
    - name: chain-0
      hops:
      - name: hop-0
        metadata:
          interface: eth0
        nodes:
        - name: node-0
          addr: SERVER_IP:443
          connector:
            type: relay
          dialer:
            type: wss
    ```

## Traffic Sniffing and Bypass

Similar to [transparent proxy](redirect.md), tungo processes raw TCP/UDP data. By combining [traffic sniffing](sniffing.md) and [bypass](../concepts/bypass.md) functions, you can process the traffic more conveniently.

=== "CLI"

    ```sh
    gost -L "tungo://:0?name=tungo&net=192.168.123.1/24&mtu=1420&dns=1.1.1.1&interface=eth0&sniffing=true" -F "relay+wss://SERVER_IP:443?interface=eth0&bypass=example.com"
    ```

=== "File (YAML)"

    ```yaml hl_lines="8-11 20 26 28"
    services:
    - name: service-0
      addr: :0
      handler:
        type: tungo
        chain: chain-0
        metadata:
          sniffing: true
          sniffing.udp: true
          sniffing.timeout: 1s
          sniffing.fallback: true
      listener:
        type: tungo
        metadata:
          name: tungo    # default name is tungo
          net: 192.168.123.1/24
          mtu: 1420      # default mtu is 1420
          dns: 1.1.1.1   # dns server
      metadata:
        interface: eth0

    chains:
    - name: chain-0
      hops:
      - name: hop-0
        bypass: bypass-0
        metadata:
          interface: eth0
        nodes:
        - name: node-0
          addr: SERVER_IP:443
          connector:
            type: relay
          dialer:
            type: wss

    bypasses:
    - name: bypass-0
      matchers:
      - example.com
    ```

Traffic sniffing is enabled through `sniffing` option. Currently, it supports sniffing of HTTP, TLS, and DNS (sniffing.udp=true) traffic. By setting bypass, requests to example.com will be sent directly through the interface `eth0` specified by the service option `metadata.interface`, and other traffic will be forwarded using the forwarding chain.