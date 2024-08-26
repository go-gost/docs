# Websocket

Websocket is a data channel type in GOST.

!!! tip "TLS Certificate Configuration"
    For TLS configuration, please refer to [TLS configuration](/en/tutorials/tls/)。

## Websocket

Unencrypted Websocket data channel.

=== "CLI"

    ```bash
    gost -L ws://:8080
    ```

=== "File (YAML)"

    ```yaml
    services:
    - name: service-0
      addr: :
      handler:
        type: auto
      listener:
        type: ws
    ```

## Websocket Secure

Websocket data channel based on TLS encryption.

=== "CLI"

    ```bash
    gost -L wss://:8080
    ```

=== "File (YAML)"

    ```yaml
    services:
    - name: service-0
      addr: :
      handler:
        type: auto
      listener:
        type: wss
    ```

## Multiplexing

GOST extends Websocket with multiplexing feature (mws, mwss), multiplexing is based on the [xtaci/smux](https://github.com/xtaci/smux) library.

=== "CLI"

    ```bash
    gost -L mws://:8443
    ```

    ```bash
    gost -L mwss://:8443
    ```

=== "File (YAML)"

    ```yaml
    services:
    - name: service-0
      addr: :
      handler:
        type: auto
      listener:
        type: mws
        # type: mwss
        metadata:
          mux.version: 1
    ```

## Options

### Multiplexing Related Options

`mux.version` (int, default=1)
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

### Custom Request Path

The request path can be customized via `path` option, the default value is `/ws`.

!!! note "Path Matching Verification"
    The connection can be successfully established only when the `path` option set by the client and the server are the same.

**Server**

=== "CLI"

    ```bash
    gost -L wss://:8443?path=/ws
    ```

=== "File (YAML)"

    ```yaml
    services:
    - name: service-0
      addr: :8443
      handler:
        type: auto
      listener:
        type: wss
		metadata:
		  path: /ws
    ```

**Client**

=== "CLI"

    ```bash
    gost -L http://:8080 -F wss://:8443?path=/ws
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
            type: wss
            metadata:
              path: /ws
    ```

### Custom Request Hostname

By default, the client uses the node address (-F parameter or the address specified in nodes.addr) as the request hostname (HTTP `Host` header). The request hostname can be customized through `host` option.

=== "CLI"

    ```bash
    gost -L http://:8080 -F wss://:8443?host=example.com
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
            type: wss
            metadata:
              host: example.com
    ```

### Custom HTTP Request Headers

You can customize the request header information through `header` option.

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
        type: wss
        metadata:
          header:
            User-Agent: "gost/3.0"
            foo: bar
```

### Keep-Alive

The client can enable keep-alive through `keepalive` option and set the interval for sending heartbeat packets through `ttl` option.

=== "CLI"

    ```bash
    gost -L http://:8080 -F "wss://:8443?keepalive=true&ttl=15s"
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
            type: wss
            metadata:
              keepalive: true
              ttl: 15s
    ```

## Proxy

Websocket tunnel can be used in combination with various proxy protocols.

### HTTP Over Websocket

=== "CLI"

    ```bash
    gost -L http+wss://:8443
    ```

=== "File (YAML)"

    ```yaml
    services:
    - name: service-0
      addr: :8443
      handler:
        type: http
      listener:
        type: wss
        # type: mwss
    ```

### SOCKS5 Over Websocket

=== "CLI"

    ```bash
    gost -L socks5+wss://:8443
    ```

=== "File (YAML)"

    ```yaml
    services:
    - name: service-0
      addr: :8443
      handler:
        type: socks5
      listener:
        type: wss
        # type: mwss
    ```

### Relay Over Websocket

=== "CLI"

    ```bash
    gost -L relay+wss://:8443
    ```

=== "File (YAML)"

    ```yaml
    services:
    - name: service-0
      addr: :8443
      handler:
        type: relay
      listener:
        type: wss
        # type: mwss
    ```

## Port Forwarding

Websocket tunnel can also be used as port forwarding.

**Server**

=== "CLI"

    ```bash
    gost -L wss://:8443/:1080 -L socks5://:1080
    ```

    is equivalent to

    ```bash
    gost -L forward+wss://:8443/:1080 -L socks5://:1080
    ```

=== "File (YAML)"

    ```yaml
    services:
    - name: service-0
      addr: :8443
      handler:
        type: forward
      listener:
        type: wss
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

By using port forwarding of the websocket tunnel, a websocket data channel is added to the SOCKS5 proxy service on port 1080.

At this time, port 8443 is equivalent to:

```bash
gost -L socks5+wss://:8443
```
