---
comments: true
---

# TLS

TLS is a data channel type in GOST.

!!! tip "TLS Certificate Configuration"
    For TLS configuration, please refer to [TLS configuration](/en/tutorials/tls/)。

## Standard TLS Service

=== "CLI"

    ```bash
    gost -L tls://:8443
    ```

=== "File (YAML)"

    ```yaml
    services:
    - name: service-0
      addr: :
      handler:
        type: auto
      listener:
        type: tls
    ```

## Multiplexing

GOST extends TLS with multiplexing feature (mtls). Multiplexing is based on [xtaci/smux](https://github.com/xtaci/smux) library.

=== "CLI"

    ```bash
    gost -L mtls://:8443
    ```

=== "File (YAML)"

    ```yaml
    services:
    - name: service-0
      addr: :
      handler:
        type: auto
      listener:
        type: mtls
        metadata:
          mux.version: 1
    ```

## Options 

### Multiplexing Related Options

`mux.version` (int, default=1)
:    SMUX protocol version.

`mux.keepaliveDisabled` (bool, default=false)
:    Whether to disable heartbeat.

`mux.keepaliveInterval` (duration, default=10s)
:    Heartbeat interval.

`mux.keepaliveTimeout` (duration, default=30s)
:    Heartbeat timeout.

`mux.maxFrameSize` (int, default=32768)
:    Maximum frame length.

`mux.maxReceiveBuffer` (int, default=4194304)
:    Receive buffer size.

`mux.maxStreamBuffer` (int, default=65536)
:    Steam Buffer Size.

## Proxy

TLS data channel can be used in combination with various proxy protocols.

### HTTP Over TLS

=== "CLI"

    ```bash
    gost -L http+tls://:8443
    ```

=== "File (YAML)"

    ```yaml
    services:
    - name: service-0
      addr: :8443
      handler:
        type: http
      listener:
        type: tls
        # type: mtls
    ```

### SOCKS5 Over TLS

=== "CLI"

    ```bash
    gost -L socks5+tls://:8443
    ```

=== "File (YAML)"

    ```yaml
    services:
    - name: service-0
      addr: :8443
      handler:
        type: socks5
      listener:
        type: tls
        # type: mtls
    ```

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
        # type: mtls
    ```

## Port Forwarding

TLS tunnel can also be used for port forwarding, which is equivalent to adding TLS encryption on top of TCP port forwarding services.

**Server**

=== "CLI"

    ```bash
    gost -L tls://:8443/:8080 -L http://:8080
    ```

    is equivalent to

    ```bash
    gost -L forward+tls://:8443/:8080 -L http://:8080
    ```

=== "File (YAML)"

    ```yaml
    services:
    - name: service-0
      addr: :8443
      handler:
        type: forward
      listener:
        type: tls
      forwarder:
        nodes:
        - name: target-0
          addr: :8080
    - name: service-1
      addr: :8080
      handler:
        type: http
      listener:
        type: tcp
    ```

By using port forwarding of the TLS data channel, a TLS encrypted data channel is added to the HTTP proxy service on port 8080.

At this time, port 8443 is equivalent to:

```bash
gost -L http+tls://:8443
```