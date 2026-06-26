---
comments: true
---

# Plain HTTP Tunnel

PHT is a data channel type in GOST.

The CONNECT method is not supported by all HTTP services. For more general use, GOST uses the more commonly used GET and POST methods in the HTTP protocol to implement data channels, including encrypted `phts` and plain text `pht` modes.

!!! tip "TLS Certificate Configuration"
    For TLS configuration, please refer to [TLS configuration](../tls.md).

## Without TLS

=== "CLI"

    ```bash
    gost -L "http+pht://:8443?authorizePath=/authorize&pushPath=/push&pullPath=/pull"
    ```

=== "File (YAML)"

    ```yaml
    services:
    - name: service-0
      addr: ":8443"
      handler:
        type: http
      listener:
        type: pht
        metadata:
          authorizePath: /authorize
          pushPath: /push
          pullPath: /pull
    ```

## With TLS 

PHT over LTS。

=== "CLI"

    ```bash
    gost -L "http+phts://:8443?authorizePath=/authorize&pushPath=/push&pullPath=/pull"
    ```

=== "File (YAML)"

    ```yaml
    services:
    - name: service-0
      addr: ":8443"
      handler:
        type: http
      listener:
        type: phts
        metadata:
          authorizePath: /authorize
          pushPath: /push
          pullPath: /pull
    ```

## Custom Request Path

The PHT channel consists of three parts:

* Authorization - The client needs to obtain the server's authorization code before transferring data with the server. The request URI is set through the `authorizePath` option. The default value is `/authorize`.
* Receive data - The client receives data from the server. The request URI is set by `pullPath` option. The default value is `/pull`.
* Send data - The client sends data to the server. The request URI is set by `pushPath` option. The default value is `/push`.

!!! note "Path Matching Verification"
    The connection can be successfully established only when the options set by the client and the server are the same.

## Custom Request Headers

The `header` option allows setting custom HTTP request headers. When establishing a PHT channel between client and server, these custom headers are automatically added to authorize, push, and pull requests.

This feature can be used with header-based authentication systems (e.g., Cloudflare Access), enabling authentication by including tokens in requests.

=== "CLI"

    ```bash
    gost -L :8080 -F "http+pht://:8443?header.ServiceToken=eyJhbGciOi..."
    ```

=== "File (YAML)"

    ```yaml
    services:
    - name: service-0
      addr: ":8080"
      handler:
        type: auto
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
            type: pht
            metadata:
              header:
                ServiceToken: "eyJhbGciOi..."
                X-Custom-Header: "value"
    ```

## Proxy

PHT tunnel can be used in combination with various proxy protocols.

### HTTP Over PHT

=== "CLI"

    ```bash
    gost -L http+pht://:8443
    ```

=== "File (YAML)"

    ```yaml
    services:
    - name: service-0
      addr: :8443
      handler:
        type: http
      listener:
        type: pht
        # type: phts
    ```

### SOCKS5 Over PHT

=== "CLI"

    ```bash
    gost -L socks5+pht://:8443
    ```

=== "File (YAML)"

    ```yaml
    services:
    - name: service-0
      addr: :8443
      handler:
        type: socks5
      listener:
        type: pht
        # type: phts
    ```

### Relay Over PHT

=== "CLI"

    ```bash
    gost -L relay+pht://:8443
    ```

=== "File (YAML)"

    ```yaml
    services:
    - name: service-0
      addr: :8443
      handler:
        type: relay
      listener:
        type: pht
        # type: phts
    ```

## Port Forwarding

PHT tunnel can also be used as port forwarding.

**Server**

=== "CLI"

    ```bash
    gost -L pht://:8443/:1080 -L socks5://:1080
    ```

    is equivalent to

    ```bash
    gost -L forward+pht://:8443/:1080 -L socks5://:1080
    ```

=== "File (YAML)"

    ```yaml
    services:
    - name: service-0
      addr: :8443
      handler:
        type: forward
      listener:
        type: pht
        # type: phts
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

By using port forwarding of the PHT tunnel, a PHT data channel is added to the SOCKS5 proxy service on port 1080.

At this time, port 8443 is equivalent to:

```bash
gost -L socks5+pht://:8443
```
