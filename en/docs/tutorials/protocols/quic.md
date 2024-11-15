---
comments: true
---

# QUIC

QUIC is a data channel type in GOST. The implementation of QUIC depends on the [quic-go/quic-go](https://github.com/quic-go/quic-go) library.

!!! tip "TLS Certificate Configuration"
    For TLS configuration, please refer to [TLS configuration](../tls.md).

## Usage

=== "CLI"

    ```bash
    gost -L http+quic://:8443
    ```

=== "File (YAML)"

    ```yaml
    services:
    - name: service-0
      addr: ":8443"
      handler:
        type: http
      listener:
        type: quic
    ```

## Options

### Keep-Alive

The client or server can enable keep-alive through `keepalive` option, and set the interval for sending heartbeat packets through `ttl` option.

=== "CLI"

    ```bash
    gost -L http://:8080 -F "quic://:8443?keepalive=true&ttl=10s"
    ```

=== "File (YAML)"

    ```yaml
    services:
    - name: service-0
      addr: :8080
      handler:
        type: http
        chain: chain-0
      listener:
        type: tcp
    chains:
    - name: chain-0
      hops:
      - name: hop-0
        nodes:
        - name: node-0
          addr: :8443
          connector:
            type: http
          dialer:
            type: quic
            metadata:
              keepalive: true
              ttl: 10s
    ```

## Proxy

QUIC tunnel can be used in combination with various proxy protocols.

### HTTP Over QUIC

=== "CLI"

    ```bash
    gost -L http+quic://:8443
    ```

=== "File (YAML)"

    ```yaml
    services:
    - name: service-0
      addr: :8443
      handler:
        type: http
      listener:
        type: quic
    ```

!!! note "QUIC and HTTP3"
    HTTP-over-QUIC is not HTTP3, so you cannot use an HTTP-over-QUIC service as an HTTP3 service.

### SOCKS5 Over QUIC

=== "CLI"

    ```bash
    gost -L socks5+quic://:8443
    ```

=== "File (YAML)"

    ```yaml
    services:
    - name: service-0
      addr: :8443
      handler:
        type: socks5
      listener:
        type: quic
    ```

### Relay Over QUIC

=== "CLI"

    ```bash
    gost -L relay+quic://:8443
    ```

=== "File (YAML)"

    ```yaml
    services:
    - name: service-0
      addr: :8443
      handler:
        type: relay
      listener:
        type: quic
    ```

## Port Forwarding

QUIC tunnel can also be used as port forwarding.

**Server**

=== "CLI"

    ```bash
    gost -L quic://:8443/:1080 -L socks5://:1080
    ```

    is equivalent to

    ```bash
    gost -L forward+quic://:8443/:1080 -L socks5://:1080
    ```

=== "File (YAML)"

    ```yaml
    services:
    - name: service-0
      addr: :8443
      handler:
        type: forward
      listener:
        type: quic
      forwarder:
        nodes:
        - name: target-0
          addr: :1080
    - name: service-1
      addr: :1080
      handler:
        type: socks5
      listener:
        type: tcp
    ```

By using port forwarding of the QUIC tunnel, a QUIC data channel is added to the SOCKS5 proxy service on port 1080.

At this time, port 8443 is equivalent to:


```bash
gost -L socks5+quic://:8443
```
