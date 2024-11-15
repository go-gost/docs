# GO Simple Tunnel

## A simple security tunnel written in golang

## Features

- [x] Listening on multiple ports
- [x] Multi-level forwarding chain.
- [x] Rich protocol
- [x] TCP/UDP port forwarding
- [x] Reverse Proxy and Tunnel
- [x] TCP/UDP transparent proxy
- [x] DNS resolver and proxy
- [x] TUN/TAP device
- [x] Load balancing
- [x] Routing control
- [x] Rate Limiting
- [x] Admission control
- [x] Dynamic configuration
- [x] Plugin system
- [x] Prometheus metrics
- [x] Web API
- [x] GUI/WebUI

## Overview

![Overview](images/overview.png)

There are three main ways to use GOST as a tunnel.

### Proxy

As a proxy service to access the network, multiple protocols can be used in combination to form a forwarding chain for traffic forwarding.

![Proxy](images/proxy.png)

### Port Forwarding

Mapping the port of one service to the port of another service, you can also use a combination of multiple protocols to form a forwarding chain for traffic forwarding.

![Forward](images/forward.png)

### Reverse Proxy

Use tunnel and intranet penetration to expose local services behind NAT or firewall to public network for access.

![Reverse Proxy](images/reverse-proxy.png)

## Installation

### Binary files

[https://github.com/go-gost/gost/releases](https://github.com/go-gost/gost/releases)

### From source

```
git clone https://github.com/go-gost/gost.git
cd gost/cmd/gost
go build
```

### Docker

```
docker run --rm gogost/gost -V
```

## Tools

### GUI

[go-gost/gostctl](https://github.com/go-gost/gostctl)

### WebUI

[ui.gost.run](https://ui.gost.run)

[go-gost/gost-ui](https://github.com/go-gost/gost-ui)

### Shadowsocks Android Plugin

[xausky/ShadowsocksGostPlugin](https://github.com/xausky/ShadowsocksGostPlugin)

## Support

GitHub: [https://github.com/go-gost/gost/issues](https://github.com/go-gost/gost/issues)

YouTube: [https://www.youtube.com/@gost-tunnel](https://www.youtube.com/@gost-tunnel)

Telegram: [https://t.me/gogost](https://t.me/gogost)

Google group: [https://groups.google.com/d/forum/go-gost](https://groups.google.com/d/forum/go-gost)

Legacy version: [v2.gost.run](https://v2.gost.run)
