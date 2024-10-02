---
comments: true
---

# MTCP

TCP data channel with multiplexing function. Multiplexing is based on [xtaci/smux](https://github.com/xtaci/smux) library.

## Usage

=== "CLI"

    ```bash
    gost -L mtcp://:8000
    ```

=== "File (YAML)"

    ```yaml
    services:
    - name: service-0
      addr: :
      handler:
        type: auto
      listener:
        type: mtcp
        metadata:
          mux.version: 2
          mux.keepaliveDisabled: false
          mux.keepaliveInterval: 10s
          mux.keepaliveTimeout: 30s
          mux.maxFrameSize: 32768
          mux.maxReceiveBuffer: 4194304
          mux.maxStreamBuffer: 65536
    ```


## Options

`mux.version` (int, default=2)
:    SMUX protocol version.

`mux.keepaliveDisabled` (bool, default=false)
:    Whether to disable keep-alive.

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

MTCP tunnel can be used in combination with various proxy protocols.

### HTTP Over MTCP

=== "CLI"

    ```bash
    gost -L http+mtcp://:8443
    ```

=== "File (YAML)"

    ```yaml
    services:
    - name: service-0
      addr: :8443
      handler:
        type: http
      listener:
        type: mtcp
    ```

### SOCKS5 Over MTCP

=== "CLI"

    ```bash
    gost -L socks5+mtcp://:8443
    ```

=== "File (YAML)"

    ```yaml
    services:
    - name: service-0
      addr: :8443
      handler:
        type: socks5
      listener:
        type: mtcp
    ```

### Relay Over MTCP

=== "CLI"

    ```bash
    gost -L relay+mtcp://:8443
    ```

=== "File (YAML)"

    ```yaml
    services:
    - name: service-0
      addr: :8443
      handler:
        type: relay
      listener:
        type: mtcp
    ```

## Port Forwarding

MTCP tunnel can also be used as port forwarding.

**Server**

=== "CLI"

    ```bash
    gost -L mtcp://:8443/:8080 -L http://:8080
    ```

    is equivalent to

    ```bash
    gost -L forward+mtcp://:8443/:8080 -L http://:8080
    ```

=== "File (YAML)"

    ```yaml
    services:
    - name: service-0
      addr: :8443
      handler:
        type: forward
      listener:
        type: mtcp
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
