---
comments: true
---

# Shadowsocks

GOST对shadowsocks的支持基于[shadowsocks/shadowsocks-go](https://github.com/shadowsocks/shadowsocks-go)和[shadowsocks/go-shadowsocks2](https://github.com/shadowsocks/go-shadowsocks2)库。

!!! note "版本变更"
    - **3.1.0+**：移除了[shadowsocks/shadowsocks-go](https://github.com/shadowsocks/shadowsocks-go)库，其所支持的旧式流加密算法（如`aes-*-cfb`、`des-cfb`、`seed-cfb`、`none`/`dummy`等）也一并移除。仅保留 AEAD 加密算法。
    - **3.3.0+**：适配 [go-shadowsocks2 v0.1.3](https://github.com/go-gost/go-shadowsocks2/releases/tag/v0.1.3)，SS 处理器和连接器**必须设置认证信息**（`auth`），不再支持无认证的明文模式。如需无加密传输，可使用 `none` / `dummy` 密码（详见下文）。

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

!!! tip "延迟发送（nodelay）"
    默认情况下shadowsocks协议会等待请求数据，当收到请求数据后会把协议头部信息与请求数据一起发给服务端。当客户端`nodelay`选项设为`true`后，协议头部信息会立即发给服务端，不再等待用户的请求数据。当通过代理连接的服务端会主动发送数据给客户端时(例如FTP，VNC，MySQL)需要开启此选项，以免造成连接异常。

!!! note "v3.3.0+ 变更"
    从 3.3.0 版本起，`nodelay` 的实际处理逻辑已内移到 go-shadowsocks2 库中，连接器层不再显式调用 `ClientFirstWrite()`。

## `none` / `dummy` 密码模式

:material-tag: 3.3.0

GOST 3.3.0 适配了 [go-shadowsocks2 v0.1.3](https://github.com/go-gost/go-shadowsocks2/releases/tag/v0.1.3)，SS 处理器和连接器**必须设置认证信息**。对于仅需要协议帧封装但不需要数据加密的场景（如调试、测试、兼容旧版、或配合外部 TLS 加密使用），可使用 `none` 或 `dummy` 密码。

此模式并非简单的明文传输，而是保留了标准的 SS AEAD 协议帧格式（2字节长度前缀 + salt + 目标地址），只是跳过了实际的数据加密/解密步骤。

=== "命令行（TCP）"
    ```bash
    # 服务端
    gost -L "ss://none@:8338"
    # 客户端
    gost -L ":8080" -F "ss://none@proxy.example.com:8338"
    ```

=== "命令行（UDP）"
    ```bash
    # 服务端
    gost -L "ssu://none@:8338"
    # 客户端
    gost -L "udp://:10053/1.1.1.1:53" -F "ssu://none@proxy.example.com:8338"
    ```

=== "配置文件"
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

!!! warning "安全警告"
    `none` / `dummy` 模式不提供任何数据机密性和完整性保护。**仅用于调试、测试和兼容性场景**，切勿在生产环境中单独使用。如果需要安全性，请配合 TLS 等外部加密通道使用（参见下文"数据通道"），或直接使用标准加密算法。


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

使用 TLS 作为数据通道时，推荐使用 `none` 密码避免双重加密。

=== "命令行"

    ```bash
    gost -L ss+tls://none@:8443
    # 或使用有加密的密码（双重加密）
    gost -L ss+tls://chacha20-ietf-poly1305:pass@:8443
    ```

=== "配置文件"

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

!!! tip "双重加密"
    当一个连接同时使用 SS 加密和 TLS 加密时，就会出现双重加密。为了避免不必要的性能开销，建议在 TLS 通道之上使用 `none` 密码模式，让 TLS 单独负责传输安全。如果场景确实需要双重加密（例如掩盖 SS 流量特征），也可以同时使用 SS 加密和 TLS。

### SS Over Websocket

=== "命令行"

    ```bash
    gost -L ss+ws://chacha20-ietf-poly1305:pass@:8080
    ```

    ```bash
    gost -L ss+wss://chacha20-ietf-poly1305:pass@:8080
    ```

=== "配置文件"

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

=== "命令行"

    ```bash
    gost -L ss+kcp://chacha20-ietf-poly1305:pass@:8080
    ```

=== "配置文件"

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