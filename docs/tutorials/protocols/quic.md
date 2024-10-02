---
comments: true
---

# QUIC

QUIC是GOST中的一种数据通道类型。QUIC的实现依赖于[quic-go/quic-go](https://github.com/quic-go/quic-go)库。

!!! tip "TLS证书配置"
    TLS配置请参考[TLS配置说明](/tutorials/tls/)。

## 示例

=== "命令行"

    ```bash
    gost -L http+quic://:8443
    ```

=== "配置文件"

    ```yaml
    services:
    - name: service-0
      addr: ":8443"
      handler:
        type: http
      listener:
        type: quic
    ```

## 选项

### 心跳

客户端或服务端可以通过`keepalive`选项开启心跳，并通过`ttl`选项设置心跳包发送的间隔时长。

=== "命令行"

    ```bash
    gost -L http://:8080 -F "quic://:8443?keepalive=true&ttl=10s"
    ```

=== "配置文件"

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
          addr: :8443
          connector:
            type: http
          dialer:
            type: quic
            metadata:
              keepalive: true
              ttl: 10s
    ```

## 代理协议

QUIC数据通道可以与各种代理协议组合使用。

### HTTP Over QUIC

=== "命令行"

    ```bash
    gost -L http+quic://:8443
    ```

=== "配置文件"

    ```yaml
    services:
    - name: service-0
      addr: :8443
      handler:
        type: http
      listener:
        type: quic
    ```

!!! note "QUIC与HTTP3"
    HTTP-over-QUIC并不是HTTP3，因此不能将一个HTTP-over-QUIC服务当作HTTP3服务使用。

### SOCKS5 Over QUIC

=== "命令行"

    ```bash
    gost -L socks5+quic://:8443
    ```

=== "配置文件"

    ```yaml
    services:
    - name: service-0
      addr: :8443
      handler:
        type: socks5
      listener:
        type: quic
    ```

### Relay Over QUIC

=== "命令行"

    ```bash
    gost -L relay+quic://:8443
    ```

=== "配置文件"

    ```yaml
    services:
    - name: service-0
      addr: :8443
      handler:
        type: relay
      listener:
        type: quic
    ```

## 端口转发

QUIC通道也可以用作端口转发。

**服务端**

=== "命令行"

    ```bash
    gost -L quic://:8443/:1080 -L socks5://:1080
    ```
    等同于
    ```bash
    gost -L forward+quic://:8443/:1080 -L socks5://:1080
    ```

=== "配置文件"

    ```yaml
    services:
    - name: service-0
      addr: :8443
      handler:
        type: forward
      listener:
        type: quic
      forwarder:
        nodes:
        - name: target-0
          addr: :1080
    - name: service-1
      addr: :1080
      handler:
        type: socks5
      listener:
        type: tcp
    ```

通过使用QUIC数据通道的端口转发，给1080端口的SOCKS5代理服务增加了QUIC数据通道。

此时8443端口等同于：

```bash
gost -L socks5+quic://:8443
```
