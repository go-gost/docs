---
authors:
  - ginuerzh
categories:
  - General
readtime: 10
date: 2015-11-19
comments: true
---

# Global SOCKS5 Proxy with Redsocks + iptables on Linux

Original post: [https://groups.google.com/g/go-gost/c/c7QCorgZiLU](https://groups.google.com/g/go-gost/c/c7QCorgZiLU).

I previously wrote a [similar document](redsocks.md), but it was more complex because it included VPN configuration. Here is the simplified version.

Applications on Linux typically require manual proxy configuration within each app, and some apps don't support proxies at all.
With redsocks + iptables, you can achieve VPN-like functionality by redirecting all TCP traffic through a SOCKS5 (or HTTPS) proxy.

<!-- more -->

Steps:

1. Install redsocks:

On Ubuntu:
```
sudo apt-get install redsocks
```

If the package isn't available, compile from source: [https://github.com/darkk/redsocks](https://github.com/darkk/redsocks).

2. Configure redsocks:

Create `redsocks.conf`:

```
base {
    log_debug = off;
    log_info = on;
    log = "file:/tmp/reddi.log";
    daemon = on;
    redirector = iptables;
}

redsocks {
    local_ip = 127.0.0.1;
    local_port = 31338;
    ip = 127.0.0.1;
    port = 8888;
    type = socks5;
}
```

The `port` setting refers to the SOCKS5 proxy port (8888 in this example).

Run redsocks:

```
redsocks -c redsocks.conf
```

Verify it's running (listening on port 31338):

```bash
netstat -tlnp
```

3. Configure iptables. Create `ipt.conf`:

```
*filter
:INPUT ACCEPT
:FORWARD ACCEPT
:OUTPUT ACCEPT
COMMIT

*nat
:PREROUTING ACCEPT
:INPUT ACCEPT
:OUTPUT ACCEPT
:POSTROUTING ACCEPT
:REDSOCKS -

-A REDSOCKS -d 0.0.0.0/8 -j RETURN
-A REDSOCKS -d 10.0.0.0/8 -j RETURN
-A REDSOCKS -d 127.0.0.0/8 -j RETURN
-A REDSOCKS -d 169.254.0.0/16 -j RETURN
-A REDSOCKS -d 192.168.0.0/16 -j RETURN
-A REDSOCKS -d 224.0.0.0/4 -j RETURN
-A REDSOCKS -d 240.0.0.0/4 -j RETURN
-A REDSOCKS -d proxy_server_ip -j RETURN
-A REDSOCKS -p tcp -j REDIRECT --to 31338
-A OUTPUT -p tcp -j REDSOCKS
COMMIT
```

**Important**: Replace `proxy_server_ip` with the IP of the remote proxy server your local proxy software connects to. For example, with gost:

```
gost -L :8888 -F a.b.c.d:8080
```

Replace `proxy_server_ip` with `a.b.c.d`.

Apply the iptables rules:

```
sudo iptables-restore < ipt.conf
```

Done!
