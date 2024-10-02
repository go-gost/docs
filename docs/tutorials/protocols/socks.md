---
comments: true
---

# SOCKS4，SOCKS5

## SOCKS4

标准的SOCKS4代理服务，同时兼容SOCKS4A协议。

=== "命令行"

    ```bash
    gost -L socks4://:1080
    ```

=== "配置文件"

    ```yaml
    services:
    - name: service-0
      addr: :1080
      handler:
        type: socks4
      listener:
        type: tcp
    ```

!!! note "BIND方法"
    SOCKS4(A)当前仅支持CONNECT方法，不支持BIND方法。


## SOCKS5

GOST完整的实现了SOCKS5协议的所有功能，包括[RFC1928](https://www.rfc-editor.org/rfc/rfc1928)中的三个命令(CONNECT，BIND，UDP ASSOCIATE)和[RFC1929](https://www.rfc-editor.org/rfc/rfc1929)中的用户名/密码认证。

### 标准的SOCKS5代理服务

=== "命令行"

    ```bash
    gost -L socks5://user:pass@:1080
    ```

=== "配置文件"

    ```yaml
    services:
    - name: service-0
      addr: :1080
      handler:
        type: socks5
        auth:
          username: user
          password: pass
      listener:
        type: tcp
    ```

### BIND

BIND功能在服务端默认是禁用状态，可以通过`bind`选项来开启此功能。

=== "命令行"

    ```bash
    gost -L socks5://user:pass@:1080?bind=true
    ```

=== "配置文件"

    ```yaml
    services:
    - name: service-0
      addr: :1080
      handler:
        type: socks5
        auth:
          username: user
          password: pass
        metadata:
          bind: true
      listener:
        type: tcp
    ```

### UDP ASSOCIATE

UDP中转功能在服务端默认是禁用状态，可以通过`udp`选项来开启此功能。

**服务端**

=== "命令行"

    ```bash
    gost -L "socks5://:1080?udp=true&udpBufferSize=4096"
    ```

=== "配置文件"

    ```yaml
    services:
    - name: service-0
      addr: :1080
      handler:
        type: socks5
        metadata:
          udp: true
          udpBufferSize: 4096
      listener:
        type: tcp
    ```

`udp` (bool, default=false)
:    开启UDP中转功能，默认禁用。

`udpBufferSize` (int, default=4096)
:    UDP缓冲区大小。最小值为：最大UDP包大小+10，否则数据中转会失败。

**客户端**

=== "命令行"

    ```bash
    gost -L udp://:1053/:53 -F "socks5://:1080?relay=udp&udpBufferSize=4096"
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
          addr: :1080
          connector:
            type: socks5
            metadata:
              relay: udp
              udpBufferSize: 4096
          dialer:
            type: tcp
    ```

`relay` (bool, default=false)
:    使用标准的UDP中转方式传输数据，默认使用UDP-TUN(UDP-Over-TCP tunnel)方式。

`udpBufferSize` (int, default=4096)
:    UDP缓冲区大小。最小值为：最大UDP包大小+10，否则数据中转会失败。

#### iperf测试

可以通过iperf3来测试UDP中转功能。

开启iperf3服务

```bash
iperf3 -s
```

开启标准SOCKS5服务(也可以使用其他支持UDP中转的SOCKS5服务)

```bash
gost -L "socks5://:1080?notls=true&udp=true&udpBufferSize=65535"
```

开启端口转发

```bash
gost -L "tcp://:15201/:5201" -L "udp://:15201/:5201?keepalive=true&readBufferSize=65535" -F "socks5://:1080?relay=udp&udpBufferSize=65535"
```

执行perf3客户端测试

```bash
iperf3 -c 127.0.0.1 -p 15201 -u
```

### 扩展功能

GOST在标准SOCKS5协议基础之上增加了一些扩展功能。

#### 协商加密

GOST支持标准SOCKS5协议的0x00(NO AUTHENTICATION REQUIRED)和0x02(USERNAME/PASSWORD)方法，并在此基础上扩展了两个方法：TLS(0x80)和TLS-AUTH(0x82)，用于数据加密。

如果客户端和服务端都使用GOST，则数据传输默认会被加密(协商使用0x80或0x82方法)，否则使用标准SOCKS5进行通讯(0x00或0x02方法)。可以在任意一端通过`notls`选项关闭加密协商功能。

=== "命令行"

    ```bash
    gost -L socks5://user:pass@:1080?notls=true
    ```

=== "配置文件"

    ```yaml
    services:
    - name: service-0
      addr: :1080
      handler:
        type: socks5
        auth:
          username: user
          password: pass
        metadata:
          notls: true
      listener:
        type: tcp
    ```

#### MBIND (Multiplex BIND)

GOST对BIND方法进行了扩展，增加了支持多路复用的BIND方法(0xF2)，多路复用基于[xtaci/smux](https://github.com/xtaci/smux)库。此扩展主要用于TCP远程端口转发。

**服务端**

=== "命令行"

    ```bash
    gost -L socks5://:1080?bind=true
    ```

=== "配置文件"

    ```yaml
    services:
    - name: service-0
      addr: :1080
      handler:
        type: socks5
        metadata:
          bind: true
      listener:
        type: tcp
    ```

**客户端**

=== "命令行"

    ```bash
    gost -L rtcp://:2222/:22 -F socks5://:1080
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
    chains:
    - name: chain-0
      hops:
      - name: hop-0
        nodes:
        - name: node-0
          addr: :1080
          connector:
            type: socks5
          dialer:
            type: tcp
    ```

#### UDP-TUN (UDP-Over-TCP Tunnel)

GOST对UDP中转方法进行了扩展，增加了UDP-Over-TCP方法(0xF3)，此扩展主要用于UDP端口转发。

**服务端**

=== "命令行"

    ```bash
    gost -L socks5://:1080?udp=true
    ```

=== "配置文件"

    ```yaml
    services:
    - name: service-0
      addr: :1080
      handler:
        type: socks5
        metadata:
          udp: true
      listener:
        type: tcp
    ```

**客户端**

=== "命令行"

    ```bash
    gost -L udp://:10053/:53 -F socks5://:1080
    ```

=== "配置文件"

    ```yaml
    services:
    - name: service-0
      addr: :10053
      handler:
        type: udp
      listener:
        type: udp
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
          addr: :1080
          connector:
            type: socks5
          dialer:
            type: tcp
    ```

## 数据通道

SOCKS代理可以与各种数据通道组合使用。

### SOCKS Over TLS

=== "命令行"

    ```bash
    gost -L socks4+tls://:8443
    ```

    ```bash
    gost -L socks5+tls://:8443?notls=true
    ```

=== "配置文件"

    ```yaml
    services:
    - name: service-0
      addr: :8443
      handler:
        type: socks5
        # type: socks4
        metadata:
          notls: true
      listener:
        type: tls
    ```

!!! tip "双重加密"
    这里为了避免双重加密，将SOCKS5的加密协商功能关闭(notls)。

### SOCKS Over Websocket

=== "命令行"

    ```bash
    gost -L socks5+ws://:8080
    ```

    ```bash
    gost -L socks5+wss://:8080
    ```

=== "配置文件"

    ```yaml
    services:
    - name: service-0
      addr: :8080
      handler:
        type: socks5
        # type: socks4
      listener:
        type: ws
        # type: wss
    ```

### SOCKS Over KCP

=== "命令行"

    ```bash
    gost -L socks5+kcp://:8080
    ```

=== "配置文件"

    ```yaml
    services:
    - name: service-0
      addr: :8080
      handler:
        type: socks5
        # type: socks4
      listener:
        type: kcp
    ```


