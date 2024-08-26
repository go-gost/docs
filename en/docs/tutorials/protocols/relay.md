# Relay Protocol

The Relay protocol is a GOST-specific protocol that has both proxy and forwarding functions. It can process TCP and UDP data at the same time and supports user authentication.

!!! note "No Encryption"
    The Relay protocol itself does not have encryption capabilities. If data needs to be transmitted encrypted, it can be used in conjunction with a data channel with encryption capabilities (such as tls, wss, quic, etc.).

## Proxy

The Relay protocol can be used as a proxy protocol just like HTTP/SOCKS5.

**Server**

```bash
gost -L relay://username:password@:12345
```

**Client**

```bash
gost -L :8080 -F relay://username:password@:12345?nodelay=false
```

!!! tip "Delay Sending"
    By default, the relay protocol will wait for request data, and when it receives the request data, it will send the protocol header information to the server together with the request data. When the client option `nodelay` is set to `true`, the protocol header will be sent to the server immediately without waiting for the user's request data. When the server connected through the proxy actively sends data to the client (such as FTP, VNC, MySQL), this option needs to be turned on to avoid abnormal connection.

It can also support forwarding TCP and UDP data at the same time with port forwarding

**Server**

=== "CLI"

    ```bash
    gost -L relay://:8420
    ```

=== "File (YAML)"

    ```yaml
    services:
    - name: service-0
      addr: :8420
      handler:
        type: relay
      listener:
        type: tcp
    ```

**Client**

=== "CLI"

    ```bash
    gost -L tcp://:2222/:22 -L udp://:1053/:53 -F relay://:8420
    ```

=== "File (YAML)"

    ```yaml
    services:
    - name: service-0
      addr: :2222
      handler:
        type: tcp
        chain: chain-0
      listener:
        type: tcp
      forwarder:
        nodes:
        - name: target-0
          addr: :22
    - name: service-1
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
          addr: :8420
          connector:
            type: relay
          dialer:
            type: tcp
    ```

## Port Forwarding

The Relay service itself can also be used as a port forwarding service.

**Server**

=== "CLI"

    ```bash
    gost -L relay://:8420/:53
    ```

=== "File (YAML)"

    ```yaml
    services:
    - name: service-0
      addr: :8420
      handler:
        type: relay
      listener:
        type: tcp
      forwarder:
        nodes:
        - name: target-0
          addr: :53
    ```

**Client**

=== "CLI"

    ```bash
    gost -L udp://:1053 -L tcp://:2222 -F relay://:8420
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
    - name: service-1
      addr: :2222
      handler:
        type: tcp
        chain: chain-0
      listener:
        type: tcp
    chains:
    - name: chain-0
      hops:
      - name: hop-0
        nodes:
        - name: node-0
          addr: :8420
          connector:
            type: relay
          dialer:
            type: tcp
    ```

## Remote Port Forwarding

The Relay protocol implements a BIND function similar to SOCKS5 and can be used in conjunction with remote port forwarding services.

The BIND function is not enabled by default and needs to be enabled by setting the `bind` option to `true`.

**Server**

=== "CLI"

    ```bash
    gost -L relay://:8420?bind=true
    ```

=== "File (YAML)"

    ```yaml
    services:
    - name: service-0
      addr: :8420
      handler:
        type: relay
        metadata:
          bind: true
      listener:
        type: tcp
    ```

**Client**

=== "CLI"

    ```bash
    gost -L rtcp://:2222/:22 -L rudp://:10053/:53 -F relay://:8420
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
    - name: service-1
      addr: :10053
      handler:
        type: rudp
      listener:
        type: rudp
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
          addr: :8420
          connector:
            type: relay
          dialer:
            type: tcp
    ```

## Data Channel

The Relay protocol can be used in combination with various data channels.

### Relay Over TLS

=== "CLI"

    ```bash
    gost -L relay+tls://:8443
    ```

=== "File (YAML)"

    ```yaml
    services:
    - name: service-0
      addr: :8443
      handler:
        type: relay
      listener:
        type: tls
    ```

### Relay Over Websocket

=== "CLI"

    ```bash
    gost -L relay+ws://:8080
    ```

    ```bash
    gost -L relay+wss://:8080
    ```

=== "File (YAML)"

    ```yaml
    services:
    - name: service-0
      addr: :8080
      handler:
        type: relay
      listener:
        type: ws
        # type: wss
    ```

### Relay Over KCP

=== "CLI"

    ```bash
    gost -L relay+kcp://:8080
    ```

=== "File (YAML)"

    ```yaml
    services:
    - name: service-0
      addr: :8080
      handler:
        type: relay
      listener:
        type: kcp
    ```
