# PROXY Protocol

The GOST service supports the receiving PROXY protocol(v1/v2). When the service is behind other proxy service (such as Nginx), the PROXY protocol is used to obtain the real IP of the client.

=== "CLI"

    ```
    gost -L=:8080?proxyProtocol=1
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

## Example

```
gost -L tcp://:8000/:8080 -L tcp://:8080/example.com:80?proxyProtocol=1
```

Port 8000 simulates a reverse proxy service and forwards data to the following 8080 service. Port 8080 is a port forwarding service.

```bash
curl -H"Host: example.com" http://192.168.100.100:8000
```

When accessing port 8000, the client IP obtained by the service on port 8080 is 127.0.0.1.

```json hl_lines="8"
{
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

```json hl_lines="8"
{
  "handler":"tcp",
  "kind":"handler",
  "level":"info",
  "listener":"tcp",
  "local":"192.168.100.100:8080",
  "msg":"192.168.100.100:57208 <> 192.168.100.100:8080",
  "remote":"192.168.100.100:57208",
  "service":"service-1"
}
```


