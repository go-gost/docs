# DTLS

DTLS is a data channel type in GOST. The implementation of DTLS depends on the [pion/dtls](https://github.com/pion/dtls) library.

!!! tip "TLS Certificate Configuration"
    For TLS configuration, please refer to [TLS configuration](/en/tutorials/tls/)。


## DTLS Service

=== "CLI"

    ```bash
    gost -L dtls://:8443
    ```

=== "File (YAML)"

    ```yaml
    services:
    - name: service-0
      addr: :
      handler:
        type: auto
      listener:
        type: dtls
    ```

## Proxy

DTLS data channel can be used in combination with various proxy protocols.

### HTTP Over DTLS

=== "CLI"

    ```bash
    gost -L http+dtls://:8443
    ```

=== "File (YAML)"

    ```yaml
    services:
    - name: service-0
      addr: :8443
      handler:
        type: http
      listener:
        type: dtls
    ```

### SOCKS5 Over DTLS

=== "CLI"

    ```bash
    gost -L socks5+dtls://:8443
    ```

=== "File (YAML)"

    ```yaml
    services:
    - name: service-0
      addr: :8443
      handler:
        type: socks5
      listener:
        type: dtls
    ```

### Relay Over DTLS

=== "CLI"

    ```bash
    gost -L relay+dtls://:8443
    ```

=== "File (YAML)"

    ```yaml
    services:
    - name: service-0
      addr: :8443
      handler:
        type: relay
      listener:
        type: dtls
    ```

## Port Forwarding

DTLS channels can also be used for port forwarding, which is equivalent to adding TLS encryption on top of the UDP port forwarding service.

**Server**

=== "CLI"

    ```bash
    gost -L dtls://:8443/:8080 -L http://:8080
    ```

    is equivalent to

    ```bash
    gost -L forward+dtls://:8443/:8080 -L http://:8080
    ```

=== "File (YAML)"

    ```yaml
    services:
    - name: service-0
      addr: :8443
      handler:
        type: forward
      listener:
        type: dtls
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

By using port forwarding of the DTLS data channel, a DTLS encrypted data channel is added to the HTTP proxy service on port 8080.

At this time, port 8443 is equivalent to:

```bash
gost -L http+dtls://:8443
```