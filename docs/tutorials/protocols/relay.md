---
comments: true
---

# Relay协议

Relay协议是GOST特有的一个协议，同时具有代理和转发功能，可同时处理TCP和UDP的数据，并支持用户认证。

!!! note "无加密"
    Relay协议本身不具备加密功能，如果需要对数据进行加密传输，可以配合具有加密功能的数据通道(例如tls，wss，quic等)使用。

## 代理

Relay协议可以像HTTP/SOCKS5一样用作代理协议。

**服务端**

```bash
gost -L relay://username:password@:12345
```

**客户端**

```bash
gost -L :8080 -F relay://username:password@:12345?nodelay=false
```

!!! tip "延迟发送"
    默认情况下relay协议会等待请求数据，当收到请求数据后会把协议头部信息与请求数据一起发给服务端，减少数据交互次数。当`nodelay`选项设为`true`后不再等待客户端的请求数据，协议头部信息会立即发给代理服务并与目标主机建立连接。这种模式在某些情况下是必要的，例如当通过代理连接的目标服务会主动发送数据给客户端时(FTP，VNC，MySQL等)需要开启此选项，以免造成连接异常。

也可以配合端口转发支持同时转发TCP和UDP数据

**服务端**

=== "命令行"

    ```bash
    gost -L relay://:8420
    ```

=== "配置文件"

    ```yaml
    services:
    - name: service-0
      addr: :8420
      handler:
        type: relay
      listener:
        type: tcp
    ```

**客户端**

=== "命令行"

    ```bash
    gost -L tcp://:2222/:22 -L udp://:1053/:53 -F relay://:8420
    ```

=== "配置文件"

    ```yaml
    services:
    - name: service-0
      addr: :2222
      handler:
        type: tcp
        chain: chain-0
      listener:
        type: tcp
      forwarder:
        nodes:
        - name: target-0
          addr: :22
    - name: service-1
      addr: :1053
      handler:
        type: udp
        chain: chain-0
      listener:
        type: udp
      forwarder:
        nodes:
        - name: target-0
          addr: :53
    chains:
    - name: chain-0
      hops:
      - name: hop-0
        nodes:
        - name: node-0
          addr: :8420
          connector:
            type: relay
          dialer:
            type: tcp
    ```

## 端口转发

Relay服务本身也可以作为端口转发服务。

**服务端**

=== "命令行"

    ```bash
    gost -L relay://:8420/:53
    ```

=== "配置文件"

    ```yaml
    services:
    - name: service-0
      addr: :8420
      handler:
        type: relay
      listener:
        type: tcp
      forwarder:
        nodes:
        - name: target-0
          addr: :53
    ```

**客户端**

=== "命令行"

    ```bash
    gost -L udp://:1053 -L tcp://:2222 -F relay://:8420
    ```

=== "配置文件"

    ```yaml
    services:
    - name: service-0
      addr: :1053
      handler:
        type: udp
        chain: chain-0
      listener:
        type: udp
    - name: service-1
      addr: :2222
      handler:
        type: tcp
        chain: chain-0
      listener:
        type: tcp
    chains:
    - name: chain-0
      hops:
      - name: hop-0
        nodes:
        - name: node-0
          addr: :8420
          connector:
            type: relay
          dialer:
            type: tcp
    ```

## 远程端口转发

Relay协议实现了类似于SOCKS5的BIND功能，可以配合远程端口转发服务使用。

BIND功能默认未开启，需要通过设置`bind`选项为true来开启。

**服务端**

=== "命令行"

    ```bash
    gost -L relay://:8420?bind=true
    ```

=== "配置文件"

    ```yaml
    services:
    - name: service-0
      addr: :8420
      handler:
        type: relay
        metadata:
          bind: true
      listener:
        type: tcp
    ```

**客户端**

=== "命令行"

    ```bash
    gost -L rtcp://:2222/:22 -L rudp://:10053/:53 -F relay://:8420
    ```

=== "配置文件"

    ```yaml
    services:
    - name: service-0
      addr: :2222
      handler:
        type: rtcp
      listener:
        type: rtcp
        chain: chain-0
      forwarder:
        nodes:
        - name: target-0
          addr: :22
    - name: service-1
      addr: :10053
      handler:
        type: rudp
      listener:
        type: rudp
        chain: chain-0
      forwarder:
        nodes:
        - name: target-0
          addr: :53
    chains:
    - name: chain-0
      hops:
      - name: hop-0
        nodes:
        - name: node-0
          addr: :8420
          connector:
            type: relay
          dialer:
            type: tcp
    ```

## 数据通道

Relay协议可以与各种数据通道组合使用。

### Relay Over TLS

=== "命令行"

    ```bash
    gost -L relay+tls://:8443
    ```

=== "配置文件"

    ```yaml
    services:
    - name: service-0
      addr: :8443
      handler:
        type: relay
      listener:
        type: tls
    ```

### Relay Over Websocket

=== "命令行"

    ```bash
    gost -L relay+ws://:8080
    ```

    ```bash
    gost -L relay+wss://:8080
    ```

=== "配置文件"

    ```yaml
    services:
    - name: service-0
      addr: :8080
      handler:
        type: relay
      listener:
        type: ws
        # type: wss
    ```

### Relay Over KCP

=== "命令行"

    ```bash
    gost -L relay+kcp://:8080
    ```

=== "配置文件"

    ```yaml
    services:
    - name: service-0
      addr: :8080
      handler:
        type: relay
      listener:
        type: kcp
    ```
