---
comments: true
---

# Protocol

As described in [Proxy, Forwarding and Tunnel](../../concepts/proxy.md), a GOST service or node is divided into two layers, the data processing layer and the data channel layer, each layer corresponds to a network protocol. The two layers are independent of each other and can be used in any combination (except for some restrictions).

## Data Processing

Data processing is divided into two types: proxy and forwarding.

### Proxy

* `http` - HTTP
* `http2` - HTTP2
* `socks4` - SOCKS4/SOCKS4A
* `socks`，`socks5` - SOCKS5
* `ss` - Shadowsocks
* `ssu` - Shadowsocks UDP relay
* `sni` - SNI
* `relay` - Relay

### Forwarding

* `tcp` - TCP port forwarding
* `udp` - UDP port forwarding
* `rtcp` - TCP remote port forwarding
* `rudp` - UDP remote port forwarding

## Data Channel

The data channel is used to carry proxy or forward protocol data. Currently supported data channel protocols are:

* `tcp` - Raw TCP protocol
* `mtcp` - Multiplex over raw TCP
* `udp` - Raw UDP protocol
* `tls` - TLS
* `dtls` - DTLS
* `mtls` - Multiplex over TLS
* `ws` - Websocket
* `mws` - Multiplex over Websocket
* `wss` - Websocket Secure
* `mwss` - Multiplex over Websocket Secure
* `h2` - HTTP2
* `h2c` - HTTP2 Cleartext
* `grpc` - gRPC
* `pht` - Plain HTTP Tunnel
* `ssh`，`sshd` - SSH
* `kcp` - KCP
* `quic` - QUIC
* `h3` - PHT over HTTP/3
* `wt` - HTTP/3 WebTransport
* `ohttp` - HTTP Obfuscation
* `otls` - TLS Obfuscation
* `icmp`, `icmp6` - ICMP, ICMPv6
* `ftcp` - Fake TCP

## Some Special Protocols

`file`
:    [HTTP File Server](../file.md)

`https`
:    Equivalent to HTTP proxy and TLS channel combination (http+tls)

`http3`
:    HTTP3 reverse proxy service

`dns`
:    [DNS Proxy](../dns.md)

`red`，`redir`，`redirect`
:    TCP [Transparent Proxy](../redirect.md)

`redu`
:    UDP [Transparent Proxy](../redirect.md)

`tun`
:    [TUN Device](../tuntap.md)

`tap`
:    [TAP Device](../tuntap.md)

`router`
:    [Routing Tunnel](../routing-tunnel.md)

`tungo`
:    [TUN2SOCKS](../tungo.md)

`forward`
:    [Server-Side Forwarding](../port-forwarding.md#_7)

`virtual`
:    [Virtual Node](../../concepts/chain.md#_5)

`unix`
:    [Unix Domain Socket Redirector](../unix.md)

`serial`
:    [Serial Port Redirector](../serial.md)

## Limitation

* All data channels based on UDP protocol (such as kcp, quic, h3, wt, including icmp) can only be used for the first-level nodes in the forwarding chain.
