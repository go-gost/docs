# HTTP3

HTTP3 has two modes: tunnel mode (data channel) and reverse proxy mode.

!!! tip "TLS Certificate Configuration"
    For TLS configuration, please refer to [TLS configuration](/en/tutorials/tls/)。

## Data Channel

HTTP3's data channel has two modes: PHT and WebTransport.

### PHT

Since HTTP3 is similar to HTTP protocol, it is used for Web data transmission and cannot be used directly as a data channel. The HTTP3 data channel in GOST adopts PHT-over-HTTP3, which uses [PHT](/en/tutorials/protocols/pht/) on top of HTTP3 protocol to implement the data channel function.

=== "CLI"

    ```bash
    gost -L "h3://:8443?authorizePath=/authorize&pushPath=/push&pullPath=/pull"
    ```

=== "File (YAML)"

    ```yaml
    services:
    - name: service-0
      addr: ":8443"
      handler:
        type: auto
      listener:
        type: h3
        metadata:
          authorizePath: /authorize
          pullPath: /pull
          pushPath: /push
    ```

### WebTransport

Similar to Websocket in the HTTP protocol, HTTP3 also defines an extended protocol [WebTransport](https://web.dev/webtransport/) for bidirectional data transmission.

=== "CLI"

    ```bash
    gost -L "wt://:8443"
    ```

=== "File (YAML)"

    ```yaml
    services:
    - name: service-0
      addr: ":8443"
      handler:
        type: auto
      listener:
        type: wt
    ```

## Reverse Proxy

HTTP3-to-HTTP reverse proxy.

The HTTP3 reverse proxy service can dynamically add HTTP/3 support to the backend HTTP service.

```yaml
services:
- name: http3
  addr: :443
  handler:
    type: http3
  listener:
    type: http3
  forwarder:
    nodes:
    - name: example-com
      addr: example.com:80
      host: .example.com
    - name: example-org
      addr: example.org:80
      host: .example.org
```

```bash
curl -k --http3 --resolve example.com:443:127.0.0.1 https://example.com
```

