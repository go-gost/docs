---
comments: true
---

# 协议

正如[代理转发和通道](../../concepts/proxy.md)所述，一个GOST服务或节点被分为两层，数据处理层和数据通道层，每一层分别对应一种网络协议。两层之间相互独立，并可以任意组合使用（除了有部分限制）。


## 数据处理

数据处理分为代理和转发两种类型。

### 代理

* `http` - HTTP协议
* `http2` - HTTP2协议
* `socks4` - SOCKS4/SOCKS4A协议
* `socks`，`socks5` - SOCKS5协议
* `ss` - Shadowsocks协议
* `ssu` - Shadowsocks UDP relay协议
* `sni` - SNI
* `relay` - Relay协议

### 转发

* `tcp` - TCP端口转发
* `udp` - UDP端口转发
* `rtcp` - TCP远程端口转发
* `rudp` - UDP远程端口转发

## 数据通道

数据通道用于承载代理或转发协议数据，目前支持的数据通道协议有：

* `tcp` - 原始TCP协议
* `mtcp` - Multiplex TCP 多路复用功能的TCP
* `udp` - 原始UDP协议
* `tls` - TLS协议
* `dtls` - DTLS协议
* `mtls` - Multiplex TLS，在TLS上增加多路复用功能
* `ws` - Websocket
* `mws` - Multiplex Websocket，在Websocket上增加多路复用功能
* `wss` - Websocket Secure，基于TLS加密的Websocket
* `mwss` - Multiplex Websocket Secure，在基于TLS加密的Websocket上增加多路复用功能
* `h2` - HTTP2协议
* `h2c` - HTTP2 Cleartext
* `grpc` - gRPC协议
* `pht` - Plain HTTP Tunnel
* `ssh`，`sshd` - SSH协议
* `kcp` - 基于UDP的KCP协议
* `quic` - 基于UDP的QUIC协议
* `h3` - HTTP3协议，基于PHT协议构建数据通道
* `wt` - HTTP/3 WebTransport模式
* `ohttp` - HTTP Obfuscation
* `otls` - TLS Obfuscation
* `icmp`, `icmp6` - ICMP和ICMPv6协议
* `ftcp` - Fake TCP

## 一些特殊的协议

`file`
:    开启一个[HTTP文件服务](../file.md)

`https`
:    等同于HTTP代理与TLS通道组合（http+tls）

`http3`
:    用于HTTP3反向代理服务

`dns`
:    [DNS代理](../dns.md)

`red`，`redir`，`redirect`
:    TCP[透明代理](../redirect.md)

`redu`
:    UDP[透明代理](../redirect.md)

`tun`
:    [TUN设备](../tuntap.md)

`tap`
:    [TAP设备](../tuntap.md)

`router`
:    [路由隧道](../routing-tunnel.md)

`tungo`
:    [TUN2SOCKS](../tungo.md)

`forward`
:    [服务端转发](../port-forwarding.md#_7)

`virtual`
:    [虚拟节点](../../concepts/chain.md#_5)

`unix`
:    [Unix Domain Socket转发](../unix.md)

`serial`
:    [串口转发](../serial.md)


## 限制

* 所有基于UDP协议的数据通道（例如kcp，quic，h3，wt，包括icmp）仅能用于转发链的第一层级节点。
