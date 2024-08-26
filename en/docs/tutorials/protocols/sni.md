# SNI

[SNI](https://www.cloudflare.com/zh-cn/learning/ssl/what-is-sni/) (Server Name Indication) is an extension of the TLS protocol and is included in the TLS handshake process (Client Hello) to identify the target hostname. The SNI proxy obtains the target access address by parsing the SNI part in the TLS handshake information.

The SNI proxy also accepts HTTP requests, using the HTTP `Host` header as the target address.

## Standard SNI Proxy

=== "CLI"

    ```bash
    gost -L sni://:443
    ```

=== "File (YAML)"

    ```yaml
    services:
    - name: service-0
      addr: :443
      handler:
        type: sni
      listener:
        type: tcp
    ```

## Host Obfuscation

The SNI client can specify the Host alias through `host` option. The SNI client will replace the SNI part in the TLS handshake or the Host in the HTTP request header with the content specified by the host option.

=== "CLI"

    ```bash
    gost -L http://:8080 -F sni://:443?host=example.com
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
          addr: :443
          connector:
            type: sni
            metadata:
              host: example.com
          dialer:
            type: tcp
    ```


## Data Channel

The SNI proxy belongs to the data processing layer, so it can also be used in combination with various data channels.

### SNI Over TLS

=== "CLI"

    ```bash
    gost -L sni+tls://:8443
    ```

=== "File (YAML)"

    ```yaml
    services:
    - name: service-0
      addr: :8443
      handler:
        type: sni
      listener:
        type: tls
    ```

### SNI Over Websocket

=== "CLI"

    ```bash
    gost -L sni+ws://:8080
    ```

    ```bash
    gost -L sni+wss://:8080
    ```

=== "File (YAML)"

    ```yaml
    services:
    - name: service-0
      addr: :8080
      handler:
        type: sni 
      listener:
        type: ws
        # type: wss
    ```

### SS Over KCP

=== "CLI"

    ```bash
    gost -L sni+kcp://:8080
    ```

=== "File (YAML)"

    ```yaml
    services:
    - name: service-0
      addr: :8080
      handler:
        type: sni
      listener:
        type: kcp
    ```
