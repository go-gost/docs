---
comments: true
---

# PROXY Protocol

GOST support for [proxy protocol](https://www.haproxy.org/download/1.8/doc/proxy-protocol.txt) depends on the [pires/go-proxyproto](https://github.com/pires/go-proxyproto) library.


## Receive Proxy Protocol Header

The GOST service supports the receiving PROXY protocol(v1/v2). When the service is behind other proxy service (such as Nginx), the PROXY protocol is used to obtain the real IP of the client.

=== "CLI"

    ```bash
    gost -L=:8080?proxyProtocol=
    ```

=== "File (YAML)"

    ```yaml hl_lines="9"
    services:
    - name: service-0
      addr: :8080
      handler:
        type: http
      listener:
        type: tcp
	  metadata:
	    proxyProtocol: 1
    ```

Enable PROXY protocol function with the `proxyProtocol` option.

!!! tip
    After the PROXY protocol function is enabled, the client is not forced to send PROXY protocol header, and the service will automatically determine whether there is PROXY protocol header based on the received data.

### Example

```bash
gost -L tcp://:8000/:8080 -L tcp://:8080/example.com:80?proxyProtocol=1
```

Port 8000 simulates a reverse proxy service and forwards data to the following 8080 service. Port 8080 is a port forwarding service.

```bash
curl -H"Host: example.com" http://192.168.100.100:8000
```

When accessing port 8000, the client IP obtained by the service on port 8080 is 127.0.0.1.

```json hl_lines="2"
{
  "client":"127.0.0.1:53574",
  "handler":"tcp",
  "kind":"handler",
  "level":"info",
  "listener":"tcp",
  "local":"127.0.0.1:8080",
  "msg":"127.0.0.1:53574 <> 127.0.0.1:8080",
  "remote":"127.0.0.1:53574",
  "service":"service-1"
}
```

If the client sends PROXY protocol header, the 8080 port service can get the real IP of the client.

```bash
curl --haproxy-protocol -H"Host:example.com" http://192.168.100.100:8000
```

```json hl_lines="2"
{
  "client":"192.168.100.100:57208",
  "handler":"tcp",
  "kind":"handler",
  "level":"info",
  "listener":"tcp",
  "local":"127.0.0.1:8080",
  "msg":"127.0.0.1:41700 <> 127.0.0.1:8080",
  "remote":"127.0.0.1:41700",
  "service":"service-1"
}
```

## Send Proxy Protocol Header

:material-tag: 3.2.1

GOST supports sending proxy protocol header to upstream forwarding nodes and proxy nodes to inform the upstream nodes of the real IP address.

### Port Forwarding Node

Enable sending of proxy protocol headers by using `proxyProtocol` option on the handler.

=== "CLI"

    ```bash
    gost -L tcp://:8080/:8000?handler.proxyProtocol=1
    ```

    ```bash
    gost -L rtcp://:8080/:8000?handler.proxyProtocol=1
    ```

    The `handler.proxyProtocol` is a [scoped parameter](../reference/configuration/cmd.md#scoped-parameters) that applies to the handler. If use `proxyProtocol` directly, it applies to the service level.

=== "File (YAML)"

    ```yaml hl_lines="7"
    services:
    - name: service-0
      addr: :8080
      handler:
        type: tcp
        metadata:
          proxyProtocol: 1
      listener:
        type: tcp
      forwarder:
        nodes:
          - name: target-0
            addr: :8000
    ```

### Proxy Node

=== "CLI"

    ```bash
    gost -L :8080 -F http://:8000?proxyProtocol=1
    ```

=== "File (YAML)"

    ```yaml hl_lines="21"
    services:
      - name: service-0
        addr: :8080
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
                addr: :8000
                connector:
                  type: http
                dialer:
                  type: tcp
            metadata:
              proxyProtocol: 1
    ```

!!! note "Limitation"

    The proxy protocol function currently does not support the UDP protocol.