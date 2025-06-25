---
comments: true
---

# Shadowsocks

GOST对shadowsocks的支持基于[shadowsocks/shadowsocks-go](https://github.com/shadowsocks/shadowsocks-go)和[shadowsocks/go-shadowsocks2](https://github.com/shadowsocks/go-shadowsocks2)库。

!!! note
    从3.1.0版本开始，移除了[shadowsocks/shadowsocks-go](https://github.com/shadowsocks/shadowsocks-go)库，其所支持的加密算法也一并移除。

## 标准shadowsocks代理

=== "命令行"

    ```bash
    gost -L ss://chacha20-ietf-poly1305:pass@:8338
    ```

=== "配置文件"

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

!!! tip "延迟发送"
    默认情况下shadowsocks协议会等待请求数据，当收到请求数据后会把协议头部信息与请求数据一起发给服务端。当客户端`nodelay`选项设为`true`后，协议头部信息会立即发给服务端，不再等待用户的请求数据。当通过代理连接的服务端会主动发送数据给客户端时(例如FTP，VNC，MySQL)需要开启此选项，以免造成连接异常。


## UDP

GOST中shadowsocks的TCP和UDP服务是相互独立的两个服务。

=== "命令行"

    ```bash
    gost -L ssu://chacha20-ietf-poly1305:pass@:8338
    ```

	  等同于

    ```bash
    gost -L ssu+udp://chacha20-ietf-poly1305:pass@:8338
    ```

=== "配置文件"

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

### 端口转发

Shadowsocks UDP relay可以配合UDP端口转发来使用：

=== "命令行"

    ```bash
    gost -L udp://:10053/1.1.1.1:53 -F ssu://chacha20-ietf-poly1305:123456@:8338
    ```

=== "配置文件"

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

## 数据通道

Shadowsocks代理可以与各种数据通道组合使用。

### SS Over TLS

=== "命令行"

    ```bash
    gost -L ss+tls://:8443
    ```

=== "配置文件"

    ```yaml
    services:
    - name: service-0
      addr: :8443
      handler:
        type: ss
      listener:
        type: tls
    ```

!!! tip "双重加密"
    这里为了避免双重加密，Shadowsocks未使用任何加密方法，采用明文传输。

### SS Over Websocket

=== "命令行"

    ```bash
    gost -L ss+ws://:8080
    ```

    ```bash
    gost -L ss+wss://:8080
    ```

=== "配置文件"

    ```yaml
    services:
    - name: service-0
      addr: :8080
      handler:
        type: ss
      listener:
        type: ws
        # type: wss
    ```

### SS Over KCP

=== "命令行"

    ```bash
    gost -L ss+kcp://:8080
    ```

=== "配置文件"

    ```yaml
    services:
    - name: service-0
      addr: :8080
      handler:
        type: ss
      listener:
        type: kcp
    ```