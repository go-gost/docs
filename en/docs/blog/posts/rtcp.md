---
authors:
  - ginuerzh
categories:
  - Port Forwarding
readtime: 10
date: 2016-09-06
comments: true
---

# GOST 2.1 Remote Port Forwarding

Original post: [https://groups.google.com/g/go-gost/c/_-akAbTe3ho](https://groups.google.com/g/go-gost/c/_-akAbTe3ho).

The [previous post](../2016/tcp/) covered local port forwarding. This one covers remote port forwarding.

GOST's remote port forwarding is similar to SSH's `-R` option. Like local port forwarding, it supports UDP and forwarding chains.

<!-- more -->

Using the same scenario:

Three machines: `local_host`, `proxy_host`, `remote_host`

* `local_host` can access `proxy_host` and `remote_host`.
* `proxy_host` cannot access `local_host` or `remote_host`.
* `remote_host` can access `local_host`.

`proxy_host` <- `local_host` <-> `remote_host`

Note that communication between `proxy_host` and `local_host` is one-way — `local_host` is behind a firewall.

### TCP Remote Port Forwarding

To SSH from `proxy_host` to `remote_host`, run this on `local_host`:

```bash
gost -L=rtcp://:2222/remote_host:22 -F=socks://proxy_host:1080
```

This assumes `proxy_host` has a GOST SOCKS5 proxy on port 1080. GOST connects to `proxy_host` through the chain and instructs it to listen on TCP port 2222. When you SSH to `proxy_host:2222`, it connects to `remote_host:22`:

```bash
ssh -p 2222 root@localhost
```

### UDP Remote Port Forwarding

To access the DNS service on `remote_host` from `proxy_host`, run this on `local_host`:

```bash
gost -L=rudp://:5353/remote_host:53 -F=socks://proxy_host:1080
```

GOST connects to `proxy_host` through the chain and listens on UDP 5353. Sending UDP data to `proxy_host:5353` forwards it to `remote_host:53`:

```bash
dig @localhost -p 5353 www.google.com
```

**Note**: TCP remote port forwarding uses the SOCKS5 BIND protocol, so the last hop must be SOCKS5. UDP remote port forwarding uses UDP-over-TCP, so the last hop must be GOST SOCKS5.
