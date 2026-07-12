---
authors:
  - ginuerzh
categories:
  - Port Forwarding
readtime: 10
date: 2016-08-31
comments: true
---

# GOST 2.1 Local Port Forwarding

Original post: [https://groups.google.com/g/go-gost/c/_Bn0oDKants](https://groups.google.com/g/go-gost/c/_Bn0oDKants).

The [2.1 version](https://github.com/ginuerzh/gost/tree/2.1) is under development, with the main addition being port forwarding. This post covers local port forwarding.

GOST's local port forwarding is similar to SSH's `-L` option. The key differences are:

1. GOST supports UDP port forwarding.
2. GOST supports port forwarding through a forwarding chain.

<!-- more -->

Assume three machines: `local_host`, `proxy_host`, `remote_host`

* `local_host` is our local machine, which can access `proxy_host` but cannot directly access `remote_host`.
* `proxy_host` is the proxy host, which can access both `local_host` and `remote_host`.
* `remote_host` is a remote host reachable from `proxy_host`.

`local_host` <-> `proxy_host` <-> `remote_host`

### TCP Port Forwarding

To SSH from `local_host` to `remote_host` (port 22) using local port forwarding:

```bash
gost -L=tcp://:2222/remote_host:22 -F proxy_host:8080
```

This assumes `proxy_host` has an HTTP proxy listening on port 8080.

Then on `local_host`:

```bash
ssh -p 2222 root@localhost
```

This connects to `remote_host`.

### UDP Port Forwarding

Same scenario, but now we want to access the UDP 53 (DNS) service on `remote_host`:

```bash
gost -L=udp://:5353/remote_host:53 -F socks://proxy_host:1080
```

This assumes `proxy_host` has a GOST SOCKS5 proxy listening on port 1080.

Then on `local_host`:

```bash
dig @localhost -p 5353 www.google.com
```

This queries `remote_host`'s UDP 53 port.

**Note**: UDP port forwarding uses UDP-over-TCP, so the last hop (the final `-F` parameter) must be a GOST SOCKS5 type.
