---
comments: true
---

# Shadowsocks

GOST's support for shadowsocks is based on the [shadowsocks/shadowsocks-go](https://github.com/shadowsocks/shadowsocks-go) and [shadowsocks/go-shadowsocks2](https://github.com/shadowsocks/go-shadowsocks2) libraries.

!!! note
    Starting from version 3.1.0, the [shadowsocks/shadowsocks-go](https://github.com/shadowsocks/shadowsocks-go) library has been removed, and the encryption algorithms it supports have also been removed.

## Standard Proxy

=== "CLI"

    ```bash
    gost -L ss://chacha20-ietf-poly1305:pass@:8338
    ```

=== "File (YAML)"

    ```yaml
    services:
    - name: service-0
      addr: :8338
      handler:
        type: ss
        auth:
          username: chacha20-ietf-poly1305
          password: pass
      listener:
        type: tcp
    ```

!!! caution "Shadowsocks Handler" The Shadowsocks handler cannot use authenticator, and only supports setting single authentication information as encryption parameter.

!!! tip "Delay Sending"
    By default, the shadowsocks protocol will wait for request data, and when it receives the request data, it will send the protocol header information to the server together with the request data. When the client option `nodelay` is set to `true`, the protocol header information will be sent to the server immediately without waiting for the user's request data. When the server connected through the proxy actively sends data to the client (such as FTP, VNC, MySQL), this option needs to be turned on to avoid abnormal connection.

## UDP

The TCP and UDP services of shadowsocks in GOST are two independent services.

=== "CLI"

    ```bash
    gost -L ssu://chacha20-ietf-poly1305:pass@:8338
    ```

	  is equivalent to

    ```bash
    gost -L ssu+udp://chacha20-ietf-poly1305:pass@:8338
    ```

=== "File (YAML)"

    ```yaml
    services:
    - name: service-0
      addr: :8338
      handler:
        type: ssu
        auth:
          username: chacha20-ietf-poly1305
          password: pass
      listener:
        type: udp
    ```

### Port Forwarding

Shadowsocks UDP relay can be used with UDP port forwarding:

=== "CLI"

    ```bash
    gost -L udp://:10053/1.1.1.1:53 -F ssu://chacha20-ietf-poly1305:123456@:8338
    ```

=== "File (YAML)"

    ```yaml
    services:
    - name: service-0
      addr: :10053
      handler:
        type: udp
        chain: chain-0
      listener:
        type: udp
      forwarder:
        nodes:
        - name: target-0
          addr: 1.1.1.1:53
    chains:
    - name: chain-0
      hops:
      - name: hop-0
        nodes:
        - name: node-0
          addr: :8338
          connector:
            type: ssu
            auth:
              username: chacha20-ietf-poly1305
              password: "123456"
          dialer:
            type: udp
    ```

## Data Channel

Shadowsocks proxy can be used in combination with various data channels.

### SS Over TLS

=== "CLI"

    ```bash
    gost -L ss+tls://:8443
    ```

=== "File (YAML)"

    ```yaml
    services:
    - name: service-0
      addr: :8443
      handler:
        type: ss
      listener:
        type: tls
    ```

!!! tip "Double Encryption"
    In order to avoid double encryption, Shadowsocks does not use any encryption method and adopts plain text transmission.

### SS Over Websocket

=== "CLI"

    ```bash
    gost -L ss+ws://:8080
    ```

    ```bash
    gost -L ss+wss://:8080
    ```

=== "File (YAML)"

    ```yaml
    services:
    - name: service-0
      addr: :8080
      handler:
        type: ss
      listener:
        type: ws
        # type: wss
    ```

### SS Over KCP

=== "CLI"

    ```bash
    gost -L ss+kcp://:8080
    ```

=== "File (YAML)"

    ```yaml
    services:
    - name: service-0
      addr: :8080
      handler:
        type: ss
      listener:
        type: kcp
    ```
