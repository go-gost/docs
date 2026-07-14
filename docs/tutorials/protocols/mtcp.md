---
comments: true
---

# MTCP

具有多路复用功能的TCP数据通道。多路复用支持[xtaci/smux](https://github.com/xtaci/smux)和[hashicorp/yamux](https://github.com/hashicorp/yamux)后端，通过`mux.type`选项选择。 :material-tag: 3.3.0

## 用法

=== "命令行"

    ```bash
    gost -L mtcp://:8000
    ```

=== "配置文件"

    ```yaml
    services:
    - name: service-0
      addr: :
      handler:
        type: auto
      listener:
        type: mtcp
        metadata:
          mux.version: 2
          mux.keepaliveDisabled: false
          mux.keepaliveInterval: 10s
          mux.keepaliveTimeout: 30s
          mux.maxFrameSize: 32768
          mux.maxReceiveBuffer: 4194304
          mux.maxStreamBuffer: 65536
    ```

## 选项 

`mux.version` (int, default=2)
:    SMUX协议版本

`mux.keepaliveDisabled` (bool, default=false)
:    是否禁用心跳

`mux.keepaliveInterval` (duration, default=10s)
:    心跳间隔时长

`mux.keepaliveTimeout` (duration, default=30s)
:    心跳超时时长

`mux.maxFrameSize` (int, default=32768)
:    帧最大长度

`mux.maxReceiveBuffer` (int, default=4194304)
:    接收缓冲区大小

`mux.maxStreamBuffer` (int, default=65536)
:    Steam缓冲区大小

`mux.type` (string, default=smux) :material-tag: 3.3.0
:    多路复用后端类型。支持的值：`smux`（默认），`yamux`。

`mux.maxStreamWindow` (int) :material-tag: 3.3.0
:    yamux最大流窗口大小（字节）。仅在`mux.type`为`yamux`时有效。

## 代理协议

MTCP数据通道可以与各种代理协议组合使用。

### HTTP Over MTCP

=== "命令行"

    ```bash
    gost -L http+mtcp://:8443
    ```

=== "配置文件"

    ```yaml
    services:
    - name: service-0
      addr: :8443
      handler:
        type: http
      listener:
        type: mtcp
    ```

### SOCKS5 Over MTCP

=== "命令行"

    ```bash
    gost -L socks5+mtcp://:8443
    ```

=== "配置文件"

    ```yaml
    services:
    - name: service-0
      addr: :8443
      handler:
        type: socks5
      listener:
        type: mtcp
    ```

### Relay Over MTCP

=== "命令行"

    ```bash
    gost -L relay+mtcp://:8443
    ```

=== "配置文件"

    ```yaml
    services:
    - name: service-0
      addr: :8443
      handler:
        type: relay
      listener:
        type: mtcp
    ```

## 端口转发

MTCP通道也可以用作端口转发。

**服务端**

=== "命令行"

    ```bash
    gost -L mtcp://:8443/:8080 -L http://:8080
    ```

    等同于

    ```bash
    gost -L forward+mtcp://:8443/:8080 -L http://:8080
    ```

=== "配置文件"

    ```yaml
    services:
    - name: service-0
      addr: :8443
      handler:
        type: forward
      listener:
        type: mtcp
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
