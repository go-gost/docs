---
comments: true
---

# Protocol

As described in [Proxy, Forwarding and Tunnel](/en/concepts/proxy/), a GOST service or node is divided into two layers, the data processing layer and the data channel layer, each layer corresponds to a network protocol. The two layers are independent of each other and can be used in any combination (except for some restrictions).

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
:    [HTTP File Server](/en/tutorials/file/)

`https`
:    Equivalent to HTTP proxy and TLS channel combination (http+tls)

`http3`
:    HTTP3 reverse proxy service

`dns`
:    [DNS Proxy](/en/tutorials/dns/)

`red`，`redir`，`redirect`
:    TCP [Transparent Proxy](/en/tutorials/redirect/)

`redu`
:    UDP [Transparent Proxy](/en/tutorials/redirect/)

`tun`
:    [TUN Device](/en/tutorials/tuntap/)

`tap`
:    [TAP Device](/en/tutorials/tuntap/)

`forward`
:    [Server-Side Forwarding](/en/tutorials/port-forwarding/#_7)

`virtual`
:    [Virtual Node](/en/concepts/chain/#_5)

`unix`
:    [Unix Domain Socket Redirector](/en/tutorials/unix/)

`serial`
:    [Serial Port Redirector](/en/tutorials/serial/)

## Limitation

* All data channels based on UDP protocol (such as kcp, quic, h3, wt, including icmp) can only be used for the first-level nodes in the forwarding chain.
