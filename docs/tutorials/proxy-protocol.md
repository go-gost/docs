---
comments: true
---

# 代理协议(PROXY Protocol)

GOST对[代理协议](https://www.haproxy.org/download/1.8/doc/proxy-protocol.txt)的支持依赖于[pires/go-proxyproto](https://github.com/pires/go-proxyproto)库。

## 接收代理协议头

GOST服务支持接收代理协议头(PROXY protocol v1/v2)，当服务处于其他代理服务(例如Nginx)后面时，通过代理协议用于获取客户端真实IP。

=== "命令行"

    ```bash
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

### 示例

```bash
gost -L tcp://:8000/:8080 -L tcp://:8080/example.com:80?proxyProtocol=1
```

这里8000端口模拟一个反向代理服务，将数据转发给后面的8080服务。8080端口是一个端口转发服务。

```bash
curl -H"Host: example.com" http://192.168.100.100:8000
```

此时如果直接访问8000端口，8080端口的服务获取到的客户端IP为127.0.0.1。

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

如果客户端发送代理协议头，8080端口服务就能获取到客户端的真实地址。

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

## 发送代理协议头

:material-tag: 3.2.1

GOST支持向上游转发节点和代理节点发送代理协议头，以便告知上游节点真实IP地址。

### 端口转发节点

通过在handler上使用`proxyProtocol`选项开启代理协议头发送功能。

=== "命令行"

    ```bash
    gost -L tcp://:8080/:8000?handler.proxyProtocol=1
    ```

    ```bash
    gost -L rtcp://:8080/:8000?handler.proxyProtocol=1
    ```

    这里的`handler.proxyProtocol`为[限定作用域参数](../reference/configuration/cmd.md#_3)，其作用对象为handler。如果直接使用`proxyProtocol`则其作用对象为service级别。

=== "配置文件"

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

### 代理节点

=== "命令行"

    ```bash
    gost -L :8080 -F http://:8000?proxyProtocol=1
    ```

=== "配置文件"

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

!!! note "限制"

    代理协议功能目前不支持UDP协议。