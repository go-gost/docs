---
comments: true
---

# Shadowsocks

GOST's support for shadowsocks is based on the [shadowsocks/shadowsocks-go](https://github.com/shadowsocks/shadowsocks-go) and [shadowsocks/go-shadowsocks2](https://github.com/shadowsocks/go-shadowsocks2) libraries.

!!! note "Version Changes"
    - **3.1.0+**: Removed the [shadowsocks/shadowsocks-go](https://github.com/shadowsocks/shadowsocks-go) library and its legacy stream ciphers (e.g. `aes-*-cfb`, `des-cfb`, `seed-cfb`, `none`/`dummy`). Only AEAD ciphers are retained.
    - **3.3.0+**: Adapted to [go-shadowsocks2 v0.1.3](https://github.com/go-gost/go-shadowsocks2/releases/tag/v0.1.3). The SS handler and connector **require authentication** (`auth`) to be set — plaintext mode without auth is no longer supported. For unencrypted transport, use the `none` / `dummy` cipher (see below).

## Standard Proxy

=== "CLI"

    ```bash
    gost -L ss://chacha20-ietf-poly1305:pass@:8338
    ```

=== "File (YAML)"

    ```yaml
    services:
    - name: service-0
      addr: :8338
      handler:
        type: ss
        auth:
          username: chacha20-ietf-poly1305
          password: pass
      listener:
        type: tcp
    ```

!!! caution "Shadowsocks Handler" The Shadowsocks handler cannot use authenticator, and only supports setting single authentication information as encryption parameter.

!!! tip "Delay Sending (nodelay)"
    By default, the shadowsocks protocol will wait for request data, and when it receives the request data, it will send the protocol header information to the server together with the request data. When the client option `nodelay` is set to `true`, the protocol header information will be sent to the server immediately without waiting for the user's request data. When the server connected through the proxy actively sends data to the client (such as FTP, VNC, MySQL), this option needs to be turned on to avoid abnormal connection.

!!! note "v3.3.0+ Change"
    Starting from v3.3.0, the `nodelay` ClientFirstWrite logic has been moved into the go-shadowsocks2 library. The connector layer no longer explicitly calls `ClientFirstWrite()`.

## `none` / `dummy` Cipher Mode

:material-tag: 3.3.0

GOST 3.3.0 adapted to [go-shadowsocks2 v0.1.3](https://github.com/go-gost/go-shadowsocks2/releases/tag/v0.1.3), and the SS handler and connector **require auth to be set**. For scenarios where you only need protocol framing without data encryption (debugging, testing, legacy compatibility, or when pairing with external TLS), use the `none` or `dummy` cipher.

This mode preserves the standard SS AEAD wire framing (2-byte length prefix + salt + target address) but skips the actual data encryption/decryption step.

=== "CLI (TCP)"
    ```bash
    # Server
    gost -L "ss://none@:8338"
    # Client
    gost -L ":8080" -F "ss://none@proxy.example.com:8338"
    ```

=== "CLI (UDP)"
    ```bash
    # Server
    gost -L "ssu://none@:8338"
    # Client
    gost -L "udp://:10053/1.1.1.1:53" -F "ssu://none@proxy.example.com:8338"
    ```

=== "File (YAML)"
    ```yaml
    services:
    - name: service-0
      addr: ":8338"
      handler:
        type: ss
        auth:
          username: none
          password: ""
      listener:
        type: tcp
    ```

!!! warning "Security"
    The `none` / `dummy` mode provides **zero confidentiality or integrity protection**. It is intended for debugging, testing, and compatibility only — never use it in production alone. If you need security, pair it with an external encryption channel like TLS (see "Data Channel" below), or use a standard encryption cipher.

## UDP

The TCP and UDP services of shadowsocks in GOST are two independent services.

=== "CLI"

    ```bash
    gost -L ssu://chacha20-ietf-poly1305:pass@:8338
    ```

	  is equivalent to

    ```bash
    gost -L ssu+udp://chacha20-ietf-poly1305:pass@:8338
    ```

=== "File (YAML)"

    ```yaml
    services:
    - name: service-0
      addr: :8338
      handler:
        type: ssu
        auth:
          username: chacha20-ietf-poly1305
          password: pass
      listener:
        type: udp
    ```

### Port Forwarding

Shadowsocks UDP relay can be used with UDP port forwarding:

=== "CLI"

    ```bash
    gost -L udp://:10053/1.1.1.1:53 -F ssu://chacha20-ietf-poly1305:123456@:8338
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
          addr: :8338
          connector:
            type: ssu
            auth:
              username: chacha20-ietf-poly1305
              password: "123456"
          dialer:
            type: udp
    ```

## Data Channel

Shadowsocks proxy can be used in combination with various data channels.

### SS Over TLS

When using TLS as the data channel, it is recommended to use the `none` cipher to avoid double encryption.

=== "CLI"

    ```bash
    gost -L ss+tls://none@:8443
    # Or with encryption (double-encrypted)
    gost -L ss+tls://chacha20-ietf-poly1305:pass@:8443
    ```

=== "File (YAML)"

    ```yaml
    services:
    - name: service-0
      addr: :8443
      handler:
        type: ss
        auth:
          username: none
          password: ""
      listener:
        type: tls
    ```

!!! tip "Double Encryption"
    When a connection uses both SS encryption and TLS encryption, double encryption occurs. To avoid unnecessary performance overhead, use the `none` cipher on top of the TLS channel and let TLS handle transport security. If your scenario requires double encryption (e.g., to obfuscate SS traffic patterns), you can use both SS encryption and TLS together.

### SS Over Websocket

=== "CLI"

    ```bash
    gost -L ss+ws://chacha20-ietf-poly1305:pass@:8080
    ```

    ```bash
    gost -L ss+wss://chacha20-ietf-poly1305:pass@:8080
    ```

=== "File (YAML)"

    ```yaml
    services:
    - name: service-0
      addr: :8080
      handler:
        type: ss
        auth:
          username: chacha20-ietf-poly1305
          password: pass
      listener:
        type: ws
        # type: wss
    ```

### SS Over KCP

=== "CLI"

    ```bash
    gost -L ss+kcp://chacha20-ietf-poly1305:pass@:8080
    ```

=== "File (YAML)"

    ```yaml
    services:
    - name: service-0
      addr: :8080
      handler:
        type: ss
        auth:
          username: chacha20-ietf-poly1305
          password: pass
      listener:
        type: kcp
    ```
