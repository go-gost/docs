---
authors:
  - ginuerzh
categories:
  - TUN
  - VPN
readtime: 30
date: 2022-10-21
comments: true
---

# VPN Networking with TUN Devices

GOST first introduced TUN (and TAP) device support in v2.9. In v3 (beta.4), the implementation was changed from the [songgao/water](https://github.com/songgao/water) library to [wireguard-go](https://git.zx2c4.com/wireguard-go), with added heartbeat and authentication mechanisms.

The design philosophy for TUN devices in GOST is simplicity and lightness — no overly complex configuration, minimal data processing. If it meets specific use cases, that's sufficient. For more complex applications, WireGuard itself can be used directly.

TUN devices have many uses, most commonly for building VPNs. This post covers GOST-based TUN VPN networking.

<!-- more -->

## VPN Networking

This is the most common VPN use case: connecting multiple LANs so they can reach each other. For example, accessing the company network from home, or accessing both home and company networks while traveling.

GOST's TUN uses a client-server model — a public server is required as a relay to connect and route clients.

Assume the following:
- Machine C1 on the company network (`192.168.100.0/24`)
- Machine C2 on the home network (`192.168.101.0/24`)
- Machine C3 on an external network (`192.168.102.0/24`)
- Server S on a public network (`192.168.1.0/24`, public IP `1.2.3.4`)

First, run the TUN server on S (ensure UDP port 8421 is open):

```yaml hl_lines="10 11 12"
services:
- name: tun
  addr: :8421
  handler:
    type: tun
  listener:
    type: tun
    metadata:
      net: 192.168.123.1/24
      routes:
      - "192.168.100.0/24 192.168.123.2"
      - "192.168.101.0/24 192.168.123.3"
```

The TUN device on server S has IP `192.168.123.1`, with routing rules:
- Traffic to `192.168.100.0/24` → forward to `192.168.123.2`
- Traffic to `192.168.101.0/24` → forward to `192.168.123.3`

Then run clients on C1, C2, and C3.

### Client C1 - 192.168.123.2

=== "CLI"
    ```
    gost -L "tun://:0/1.2.3.4:8421?net=192.168.123.2/24&keepAlive=true&route=192.168.101.0/24"
    ```
=== "Config File"
    ```yaml
    services:
    - name: tun
      addr: :0
      handler:
        type: tun
        metadata:
          keepAlive: true
          ttl: 10s
      listener:
        type: tun
        metadata:
          net: 192.168.123.2/24
          route: 192.168.101.0/24
      forwarder:
        nodes:
        - name: target-0
          addr: 1.2.3.4:8421
    ```

### Client C2 - 192.168.123.3

=== "CLI"
    ```
    gost -L "tun://:0/1.2.3.4:8421?net=192.168.123.3/24&keepAlive=true&route=192.168.100.0/24"
    ```
=== "Config File"
    ```yaml
    services:
    - name: tun
      addr: :0
      handler:
        type: tun
        metadata:
          keepAlive: true
          ttl: 10s
      listener:
        type: tun
        metadata:
          net: 192.168.123.3/24
          route: 192.168.100.0/24
      forwarder:
        nodes:
        - name: target-0
          addr: 1.2.3.4:8421
    ```

### Client C3 - 192.168.123.4

=== "CLI"
    ```
    gost -L "tun://:0/1.2.3.4:8421?net=192.168.123.4/24&keepAlive=true&route=192.168.100.0/24,192.168.101.0/24"
    ```
=== "Config File"
    ```yaml
    services:
    - name: tun
      addr: :0
      handler:
        type: tun
        metadata:
          keepAlive: true
          ttl: 10s
      listener:
        type: tun
        metadata:
          net: 192.168.123.4/24
          route: 192.168.100.0/24,192.168.101.0/24
      forwarder:
        nodes:
        - name: target-0
          addr: 1.2.3.4:8421
    ```

The critical part is the client route configuration:
- C1's route to `192.168.101.0/24` allows C1 to reach C2's network
- C2's route to `192.168.100.0/24` allows C2 to reach C1's network
- C3's routes to both networks allow C3 to reach both C1 and C2

### iptables Configuration

TUN devices can communicate with each other, but accessing their respective LANs requires IP forwarding via iptables:

```
iptables -t nat -A POSTROUTING -s 192.168.123.0/24 ! -o tun0 -j MASQUERADE
```

## Heartbeat

The `keepAlive` parameter enables heartbeats, which serve two purposes:

1. **Connection health**: GOST's TUN uses UDP. Heartbeats let the client detect network connectivity. After timeout (3 heartbeat periods), the client reinitializes the connection.
2. **Dynamic routing**: The server maintains a dynamic client mapping table (client TUN IP ↔ client UDP connection IP:PORT). Heartbeats update this mapping. If the server restarts, client heartbeats repopulate the table.

## Authentication

The above configuration works, but clients can set arbitrary TUN IPs, potentially causing conflicts. Enable server-side authentication for better control:

```yaml hl_lines="6"
services:
- name: tun
  addr: :8421
  handler:
    type: tun
    auther: tun
  listener:
    type: tun
    metadata:
      net: 192.168.123.1/24

authers:
- name: tun
  auths:
  - username: 192.168.123.2
    password: userpass1
  - username: 192.168.123.3
    password: userpass2
  - username: 192.168.123.4
    password: userpass3
```

The server assigns each client a TUN IP and credentials. Clients must use the assigned IP (`net`) and passphrase to join the network.

=== "CLI"
    ```
    gost -L "tun://:0/1.2.3.4:8421?net=192.168.123.2/24&keepAlive=true&route=192.168.101.0/24&passphrase=userpass1"
    ```
=== "Config File"
    ```yaml
    services:
    - name: tun
      addr: :0
      handler:
        type: tun
        metadata:
          keepAlive: true
          ttl: 10s
          passphrase: userpass1
      listener:
        type: tun
        metadata:
          net: 192.168.123.2/24
          route: 192.168.101.0/24
      forwarder:
        nodes:
        - name: target-0
          addr: 1.2.3.4:8421
    ```

## Secure Transport

GOST's TUN data is transmitted in plaintext. For encryption, use a forwarding chain with an encrypted tunnel — TCP-based (TLS, WSS, gRPC) or UDP-based (KCP, QUIC).

=== "CLI"
    ```
    gost -L "tun://:0/:8421?net=192.168.123.2/24&keepAlive=true&route=192.168.101.0/24" -F relay+wss://1.2.3.4:443
    ```
=== "Config File"
    ```yaml
    services:
    - name: tun
      addr: :0
      handler:
        type: tun
        chain: chain-0
        metadata:
          keepAlive: true
          ttl: 10s
      listener:
        type: tun
        metadata:
          net: 192.168.123.2/24
          route: 192.168.101.0/24
      forwarder:
        nodes:
        - name: target-0
          addr: :8421
    chains:
    - name: chain-0
      hops:
      - name: hop-0
        nodes:
        - name: node-0
          addr: 1.2.3.4:443
          connector:
            type: relay
          dialer:
            type: wss
    ```

Using a forwarding chain also allows the server to hide the TUN service port (8421), exposing only the tunnel port (443) for better VPN stealth.
