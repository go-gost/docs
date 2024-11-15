---
comments: true
---

# HTTP2

HTTP2 has two modes: proxy mode and tunnel mode.

!!! tip "TLS Certificate Configuration"
    For TLS configuration, please refer to [TLS configuration](../tls.md).

## Proxy Mode

In proxy mode, HTTP2 is used as the proxy protocol and the data channel layer of the HTTP2 proxy must be `http2`.

=== "CLI"

    ```bash
    gost -L http2://:8443
    ```

=== "File (YAML)"

    ```yaml
    services:
    - name: service-0
      addr: :8443
      handler:
        type: http2
      listener:
        type: http2
    ```

## Tunnel Mode

In tunnel mode, HTTP2 is used as the data channel, which is divided into encrypted (h2) and plain text (h2c).

=== "CLI"

    ```bash
    gost -L http+h2://:8443
    ```

    ```bash
    gost -L http+h2c://:8080
    ```

=== "File (YAML)"

    ```yaml
    services:
    - name: service-0
      addr: :8443
      handler:
        type: http
      listener:
        type: h2
        # type: h2c
    ```

### Custom Request Path

The HTTP2 data channel uses `CONNECT` method to establish a connection by default. You can customize the request path through `path` option. In this case, the method `GET` is used to establish a connection.

!!! note "Path Matching Verification"
    The connection can be successfully established only when the `path` option set by the client and the server are the same.

**Server**

=== "CLI"

    ```bash
    gost -L http+h2://:8443?path=/http2
    ```

=== "File (YAML)"

    ```yaml hl_lines="9"
    services:
    - name: service-0
      addr: :8443
      handler:
        type: http
      listener:
        type: h2
		metadata:
		  path: /http2
    ```

**Client**

=== "CLI"

    ```bash
    gost -L http://:8080 -F http+h2://:8443?path=/http2
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
            type: h2
            metadata:
              path: /http2
    ```

### Custom Request Hostname

By default, the HTTP2 data channel client uses the node address (-F parameter or the address specified in nodes.addr) as the request hostname (HTTP `Host` header). The request hostname can be customized through `host` option.

=== "CLI"

    ```bash
    gost -L http://:8080 -F http+h2://:8443?host=example.com
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
            type: h2
            metadata:
              host: example.com
    ```

### Custom HTTP Request Headers

You can customize the request header information through `header` option.

```yaml hl_lines="21-23"
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
        type: h2
        metadata:
          header:
            User-Agent: "gost/3.0"
            foo: bar
```