# gRPC

gRPC is a data channel type in GOST.

!!! tip "TLS Certificate Configuration"
    For TLS configuration, please refer to [TLS configuration](/en/tutorials/tls/)。

## With TLS

gRPC tunnel use TLS encryption by default.

=== "CLI"

    ```bash
    gost -L http+grpc://:8443
    ```

=== "File (YAML)"

    ```yaml
    services:
    - name: service-0
      addr: ":8443"
      handler:
        type: http
      listener:
        type: grpc
    ```

## Without TLS

Enable plaintext gRPC tunnel via `grpc.insecure` option.

=== "CLI"

    ```bash
    gost -L http+grpc://:8443?grpc.insecure=true
    ```

=== "File (YAML)"

    ```yaml hl_lines="9"
    services:
    - name: service-0
      addr: ":8443"
      handler:
        type: http
      listener:
        type: grpc
        metadata:
          grpc.insecure: true
    ```

## Options

### Custom Request Hostname

By default, the client uses the node address (-F parameter or the address specified in nodes.addr) as the request hostname (`:authority` header). The request hostname can be customized through `host` option.

=== "CLI"

    ```bash
    gost -L http://:8080 -F grpc://:8443?host=example.com
    ```

=== "File (YAML)"

    ```yaml hl_lines="21"
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
            type: grpc
            metadata:
              host: example.com
    ```

### Custom Request Path

The request path can be customized via `path` option, the default value is `/GostTunel/Tunnel`.

!!! note "Path Matching Verification"
    The connection can be successfully established only when the `path` option set by the client and the server are the same.

**Server**

=== "CLI"

    ```bash
    gost -L grpc://:8443?path=/GostTunel/Tunnel
    ```

=== "File (YAML)"

    ```yaml hl_lines="9"
    services:
    - name: service-0
      addr: :8443
      handler:
        type: auto
      listener:
        type: grpc
		metadata:
		  path: /GostTunel/Tunnel
    ```

**Client**

=== "CLI"

    ```bash
    gost -L http://:8080 -F grpc://:8443?path=/GostTunel/Tunnel
    ```

=== "File (YAML)"

    ```yaml hl_lines="21"
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
            type: grpc
            metadata:
              path: /GostTunel/Tunnel
    ```

### Keep-Alive

The client and server can each control the sending of heartbeats through several options.

**Client**

=== "CLI"

    ```bash
    gost -L http://:8080 -F "grpc://:8443?keepalive=true&keepalive.time=30s&keepalive.timeout=30s&keepalive.permitWithoutStream=true"
    ```

=== "File (YAML)"

    ```yaml hl_lines="21-24"
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
            type: grpc
            metadata:
              keepalive: true
              keepalive.time: 30s
              keepalive.timeout: 30s
              keepalive.permitWithoutStream: true
    ```

**Server**

=== "CLI"

    ```bash
    gost -L "grpc://:8443?keepalive=true&keepalive.minTime=30s&keepalive.time=60s&keepalive.timeout=30s&keepalive.permitWithoutStream=true&keepalive.maxConnectionIdle=5m"
    ```

=== "File (YAML)"

    ```yaml hl_lines="9-14"
    services:
    - name: service-0
      addr: :8443
      handler:
        type: auto
      listener:
        type: grpc
        metadata:
          keepalive: true
          keepalive.time: 60s
          keepalive.timeout: 30s
          keepalive.permitWithoutStream: true
          keepalive.minTime: 30s
          keepalive.maxConnectionIdle: 5m
    ```

`keepalive` (bool, default=false)
:   Whether to enable keep-alive.

`keepalive.time` (duration, default=30s)
:    When the idle time exceeds this set value, a heartbeat packet is sent. 

`keepalive.timeout` (duration, default=30s)
:    The duration of waiting for a heartbeat response.

`keepalive.permitWithoutStream` (bool, default=false)
:    Whether to allow sending heartbeat packets in idle state. **Note**: When the client turns on this option, the server should also turn it on at the same time, otherwise the server will forcibly close the current connection.

`keepalive.minTime` (duration, default=30s)
:    The minimum waiting time before the client sends a heartbeat packet. **Only valid on the server side.**

`keepalive.maxConnectionIdle` (duration, default=5m)
:    When the connection is idle for more than this time, the connection will be closed. **Only valid on the server side.**

!!! caution "Use With Caution"
    The keep-alive mechanism of gRPC requires cooperation between the client and the server. If the parameters are set incorrectly, connection abnormalities may occur. It is recommended to read the [official documentation](https://github.com/grpc/grpc/blob/master/doc/keepalive.md) before using it.

## Proxy

gRPC tunnel can be used in combination with various proxy protocols.

### HTTP Over gRPC

=== "CLI"

    ```bash
    gost -L http+grpc://:8443
    ```

=== "File (YAML)"

    ```yaml
    services:
    - name: service-0
      addr: :8443
      handler:
        type: http
      listener:
        type: grpc
    ```

### SOCKS5 Over gRPC

=== "CLI"

    ```bash
    gost -L socks5+grpc://:8443
    ```

=== "File (YAML)"

    ```yaml
    services:
    - name: service-0
      addr: :8443
      handler:
        type: socks5
      listener:
        type: grpc
    ```

### Relay Over gRPC

=== "CLI"

    ```bash
    gost -L relay+grpc://:8443
    ```

=== "File (YAML)"

    ```yaml
    services:
    - name: service-0
      addr: :8443
      handler:
        type: relay
      listener:
        type: grpc
    ```



## Port Forwarding

gRPC tunnel can also be used as port forwarding.

**Server**

=== "CLI"

    ```bash
    gost -L grpc://:8443/:1080 -L socks5://:1080
    ```

    is equivalent to

    ```bash
    gost -L forward+grpc://:8443/:1080 -L socks5://:1080
    ```

=== "File (YAML)"

    ```yaml
    services:
    - name: service-0
      addr: :8443
      handler:
        type: forward
      listener:
        type: grpc
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

By using port forwarding of the gRPC tunnel, a gRPC data channel is added to the SOCKS5 proxy service on port 1080.

At this time, port 8443 is equivalent to:


```bash
gost -L socks5+grpc://:8443
```
