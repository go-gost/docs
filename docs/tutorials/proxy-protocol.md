---
comments: true
---

# PROXY Protocol

GOST服务支持接收代理协议头(PROXY protocol v1/v2)，当服务处于其他代理服务(例如Nginx)后面时，通过代理协议用于获取客户端真实IP。

=== "命令行"

    ```
    gost -L=:8080?proxyProtocol=1
    ```

=== "配置文件"

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

通过`proxyProtocol`选项开启接收代理协议功能。

!!! tip
    代理协议功能开启后，并不强制客户端发送代理协议头，服务端会根据接收到的数据自动判断是否有代理协议数据。

## 示例

```
gost -L tcp://:8000/:8080 -L tcp://:8080/example.com:80?proxyProtocol=1
```

这里8000端口模拟一个反向代理服务，将数据转发给后面的8080服务。8080端口是一个端口转发服务。

```bash
curl -H"Host: example.com" http://192.168.100.100:8000
```

此时如果直接访问8000端口，8080端口的服务获取到的客户端IP为127.0.0.1。

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

如果客户端发送代理协议头，8080端口服务就能获取到客户端的真是IP。

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


