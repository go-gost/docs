---
comments: true
---

# SOCKS4，SOCKS5

## SOCKS4

Standard SOCKS4 proxy service, also compatible with SOCKS4A protocol.

=== "CLI"

    ```bash
    gost -L socks4://:1080
    ```

=== "CLI"

    ```yaml
    services:
    - name: service-0
      addr: :1080
      handler:
        type: socks4
      listener:
        type: tcp
    ```

!!! note "BIND Method"
    SOCKS4(A) currently only supports the CONNECT method.


## SOCKS5

GOST fully implements all the functions of the SOCKS5 protocol, including three commands (CONNECT, BIND and UDP ASSOCIATE) in [RFC1928](https://www.rfc-editor.org/rfc/rfc1928) 
and the username/password authentication in [RFC1929](https://www.rfc-editor.org/rfc/rfc1929).

### Standard SOCKS5 Proxy Service

=== "CLI"

    ```bash
    gost -L socks5://user:pass@:1080
    ```

=== "File (YAML)"

    ```yaml
    services:
    - name: service-0
      addr: :1080
      handler:
        type: socks5
        auth:
          username: user
          password: pass
      listener:
        type: tcp
    ```

### BIND

The BIND function is disabled by default on the server, but can be enabled through `bind` option.

=== "CLI"

    ```bash
    gost -L socks5://user:pass@:1080?bind=true
    ```

=== "File (YAML)"

    ```yaml
    services:
    - name: service-0
      addr: :1080
      handler:
        type: socks5
        auth:
          username: user
          password: pass
        metadata:
          bind: true
      listener:
        type: tcp
    ```

### UDP ASSOCIATE

The UDP relay feature is disabled by default on the server side, and can be enabled through `udp` option.

**Server**

=== "CLI"

    ```bash
    gost -L "socks5://:1080?udp=true&udpBufferSize=4096"
    ```

=== "File (YAML)"

    ```yaml
    services:
    - name: service-0
      addr: :1080
      handler:
        type: socks5
        metadata:
          udp: true
          udpBufferSize: 4096
      listener:
        type: tcp
    ```

`udp` (bool, default=false)
:    Enable UDP relay function, which is disabled by default.

`udpBufferSize` (int, default=4096)
:    UDP buffer size. The minimum value is: maximum UDP packet size + 10, otherwise data transfer will fail.

**Client**

=== "CLI"

    ```bash
    gost -L udp://:1053/:53 -F "socks5://:1080?relay=udp&udpBufferSize=4096"
    ```

=== "File (YAML)"

    ```yaml
    services:
    - name: service-0
      addr: :1053
      handler:
        type: udp
        chain: chain-0
      listener:
        type: udp
      forwarder:
        nodes:
        - name: target-0
          addr: :53
    chains:
    - name: chain-0
      hops:
      - name: hop-0
        nodes:
        - name: node-0
          addr: :1080
          connector:
            type: socks5
            metadata:
              relay: udp
              udpBufferSize: 4096
          dialer:
            type: tcp
    ```

`relay` (bool, default=false)
:    Use standard UDP relay method to transmit data, UDP-TUN (UDP-Over-TCP tunnel) method is used by default.

`udpBufferSize` (int, default=4096)
:    UDP buffer size. The minimum value is: maximum UDP packet size + 10, otherwise data transfer will fail.

#### iperf Test

You can use iperf3 to test the UDP relay function.

Start iperf3 service:

```bash
iperf3 -s
```

Start the standard SOCKS5 service (you can also use other SOCKS5 services that support UDP relay):

```bash
gost -L "socks5://:1080?notls=true&udp=true&udpBufferSize=65535"
```

Start port forwarding:

```bash
gost -L "tcp://:15201/:5201" -L "udp://:15201/:5201?keepalive=true&readBufferSize=65535" -F "socks5://:1080?relay=udp&udpBufferSize=65535"
```

Execute perf3 UDP test:

```bash
iperf3 -c 127.0.0.1 -p 15201 -u
```

### Extended functions

GOST adds some extended functions based on the standard SOCKS5 protocol.

#### Negotiated Encryption

GOST supports the 0x00 (NO AUTHENTICATION REQUIRED) and 0x02 (USERNAME/PASSWORD) methods of the standard SOCKS5 protocol, and expands two methods on this basis: TLS (0x80) and TLS-AUTH (0x82) for data encryption.

If both the client and the server use GOST, data transmission will be encrypted by default (negotiation method 0x80 or 0x82), otherwise standard SOCKS5 communication is used (0x00 or 0x02 method). The encryption negotiation function can be turned off on either side through `notls` option.

=== "CLI"

    ```bash
    gost -L socks5://user:pass@:1080?notls=true
    ```

=== "File (YAML)"

    ```yaml
    services:
    - name: service-0
      addr: :1080
      handler:
        type: socks5
        auth:
          username: user
          password: pass
        metadata:
          notls: true
      listener:
        type: tcp
    ```

#### MBIND (Multiplex BIND)

GOST extends the BIND method and adds a Multiplex-BIND method (0xF2) that supports multiplexing. Multiplexing is based on the [xtaci/smux](https://github.com/xtaci/smux). This extension is mainly used for TCP remote port forwarding.

**Server**

=== "CLI"

    ```bash
    gost -L socks5://:1080?bind=true
    ```

=== "File (YAML)"

    ```yaml
    services:
    - name: service-0
      addr: :1080
      handler:
        type: socks5
        metadata:
          bind: true
      listener:
        type: tcp
    ```

**Client**

=== "CLI"

    ```bash
    gost -L rtcp://:2222/:22 -F socks5://:1080
    ```

=== "File (YAML)"

    ```yaml
    services:
    - name: service-0
      addr: :2222
      handler:
        type: rtcp
      listener:
        type: rtcp
        chain: chain-0
      forwarder:
        nodes:
        - name: target-0
          addr: :22
    chains:
    - name: chain-0
      hops:
      - name: hop-0
        nodes:
        - name: node-0
          addr: :1080
          connector:
            type: socks5
          dialer:
            type: tcp
    ```

#### UDP-TUN (UDP-Over-TCP Tunnel)

GOST extends the UDP relay method and adds the UDP-Over-TCP method (0xF3). This extension is mainly used for UDP port forwarding.

**Server**

=== "CLI"

    ```bash
    gost -L socks5://:1080?udp=true
    ```

=== "File (YAML)"

    ```yaml
    services:
    - name: service-0
      addr: :1080
      handler:
        type: socks5
        metadata:
          udp: true
      listener:
        type: tcp
    ```

**Client**

=== "CLI"

    ```bash
    gost -L udp://:10053/:53 -F socks5://:1080
    ```

=== "File (YAML)"

    ```yaml
    services:
    - name: service-0
      addr: :10053
      handler:
        type: udp
      listener:
        type: udp
        chain: chain-0
      forwarder:
        nodes:
        - name: target-0
          addr: :53
    chains:
    - name: chain-0
      hops:
      - name: hop-0
        nodes:
        - name: node-0
          addr: :1080
          connector:
            type: socks5
          dialer:
            type: tcp
    ```

## Data Channel

SOCKS proxy can be used in combination with various data channels.

### SOCKS Over TLS

=== "CLI"

    ```bash
    gost -L socks4+tls://:8443
    ```

    ```bash
    gost -L socks5+tls://:8443?notls=true
    ```

=== "File (YAML)"

    ```yaml
    services:
    - name: service-0
      addr: :8443
      handler:
        type: socks5
        # type: socks4
        metadata:
          notls: true
      listener:
        type: tls
    ```

!!! tip "Double Encryption"
    In order to avoid double encryption, the encryption negotiation function of SOCKS5 is turned off (notls=true).

### SOCKS Over Websocket

=== "CLI"

    ```bash
    gost -L socks5+ws://:8080
    ```

    ```bash
    gost -L socks5+wss://:8080
    ```

=== "File (YAML)"

    ```yaml
    services:
    - name: service-0
      addr: :8080
      handler:
        type: socks5
        # type: socks4
      listener:
        type: ws
        # type: wss
    ```

### SOCKS Over KCP

=== "CLI"

    ```bash
    gost -L socks5+kcp://:8080
    ```

=== "File (YAML)"

    ```yaml
    services:
    - name: service-0
      addr: :8080
      handler:
        type: socks5
        # type: socks4
      listener:
        type: kcp
    ```


