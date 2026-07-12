---
authors:
  - ginuerzh
categories:
  - VPN
readtime: 10
date: 2017-01-16
comments: true
---

# Global Network Access with L2TP/IPSec + iptables + GOST on Linux

Original post: [https://groups.google.com/g/go-gost/c/bx0fYx2jmG4](https://groups.google.com/g/go-gost/c/bx0fYx2jmG4).

Previously, I wrote a [similar article](../2015/redirect.md) using PPTP + iptables + redsocks. Since newer iOS versions no longer support PPTP, this version uses IPSec instead.

<!-- more -->

Newer gost versions also support transparent proxy, eliminating the need for redsocks. This approach is simpler than the previous one.

First, install the IPSec VPN service. There's an automated script available: [https://github.com/hwdsl2/setup-ipsec-vpn](https://github.com/hwdsl2/setup-ipsec-vpn).

Then start the transparent proxy:

```bash
gost -L redirect://:12345 -F http2://SERVER_IP:443?ping=30
```

To avoid DNS pollution, add DNS forwarding:

```bash
gost -L udp://:1053/8.8.8.8:53?ttl=5 -L redirect://:12345 -F http2://SERVER_IP:443?ping=30
```

Then configure iptables. Edit `/etc/iptables.rules`, add to the nat table:

```
-A PREROUTING -i eth+ -p udp --dport 53 -j DNAT --to LOCAL_IP:1053
-A PREROUTING -p tcp -j REDSOCKS
-A OUTPUT -p tcp -j REDSOCKS
-A REDSOCKS -d 0.0.0.0/8 -j RETURN
-A REDSOCKS -d 10.0.0.0/8 -j RETURN
-A REDSOCKS -d 127.0.0.0/8 -j RETURN
-A REDSOCKS -d 169.254.0.0/16 -j RETURN
-A REDSOCKS -d 192.168.0.0/16 -j RETURN
-A REDSOCKS -d 224.0.0.0/4 -j RETURN
-A REDSOCKS -d 240.0.0.0/4 -j RETURN
-A REDSOCKS -d SERVER_IP -j RETURN
-A REDSOCKS -p tcp -j REDIRECT --to-ports 12345
```

There's an even simpler approach: use port forwarding to map the VPN directly to local:

```bash
gost -L udp://:500/SERVER_IP:500 -L udp://:4500/SERVER_IP:4500 -L udp://:1701/SERVER_IP:1701 -F http2://SERVER_IP:443
```

This way, the local machine acts as a VPN server without any additional setup.
