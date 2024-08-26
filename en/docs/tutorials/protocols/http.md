# HTTP

HTTP proxy is a proxy service implemented using the [CONNECT method](https://developer.mozilla.org/zh-CN/docs/Web/HTTP/Methods/CONNECT) of the HTTP protocol.

## Standard HTTP Proxy

A simple HTTP proxy service without encryption or authentication.

=== "CLI"

    ```bash
    gost -L http://:8080
    ```

=== "File (YAML)"

    ```yaml
    services:
    - name: service-0
      addr: :8080
      handler:
        type: http
      listener:
        type: tcp
    ```

## Standard HTTP Proxy (With Authentication Enabled)

A non-encrypted HTTP proxy service with user authentication.

=== "CLI"

    ```bash
    gost -L http://user:pass@:8080
    ```

=== "File (YAML)"

    ```yaml hl_lines="6-8"
    services:
    - name: service-0
      addr: :8080
      handler:
        type: http
        auth:
          username: user
          password: pass
      listener:
        type: tcp
    ```

## Options

### Custom HTTP Headers

Option `header` allow you to customize request and response headers.

```yaml hl_lines="7 8 9 22 23 24"
services:
- name: service-0
  addr: :8080
  handler:
    type: http
    chain: chain-0
    header:
      Proxy-Agent: "gost/3.0"
      foo: bar
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
        metadata:
          header:
            User-Agent: "gost/3.0"
            foo: bar
      dialer:
        type: tcp
```

## Data Channel

HTTP proxies can be used in combination with various data channels.

### HTTP Over TLS

Standard HTTPS proxy service.

=== "CLI"

    ```bash
    gost -L https://:8443
    ```

    is equivalent to

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
    ```

### HTTP Over Websocket

=== "CLI"

    ```bash
    gost -L http+ws://:8080
    ```

    ```bash
    gost -L http+wss://:8080
    ```

=== "File (YAML)"

    ```yaml
    services:
    - name: service-0
      addr: :8080
      handler:
        type: http
      listener:
        type: ws
        # type: wss
    ```

### HTTP Over KCP

=== "CLI"

    ```bash
    gost -L http+kcp://:8080
    ```

=== "File (YAML)"

    ```yaml
    services:
    - name: service-0
      addr: :8080
      handler:
        type: http
      listener:
        type: kcp
    ```

## UDP Data Forwarding

HTTP proxy extends the support for UDP data based on the standard protocol to implement UDP-Over-HTTP function. The UDP forwarding function of HTTP proxy service is disabled by default and needs to be enabled through `udp` option.

**Server**

=== "CLI"

    ```bash
    gost -L http://:8080?udp=true
    ```

=== "File (YAML)"

    ```yaml hl_lines="7"
    services:
    - name: service-0
      addr: :8080
      handler:
        type: http
        metadata:
          udp: true
      listener:
        type: tcp
    ```

**Client**

=== "CLI"

    ```bash
    gost -L udp://:10053/1.1.1.1:53 -F http://:8080
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
          addr: :8080
          connector:
            type: http
          dialer:
            type: tcp
    ```