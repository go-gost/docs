---
authors:
  - ginuerzh
categories:
  - Port Forwarding
readtime: 10
date: 2016-10-09
comments: true
---

# Accessing Intranet HTTP Services with GOST

Original post: [https://groups.google.com/g/go-gost/c/ouzBXF0Fqk8](https://groups.google.com/g/go-gost/c/ouzBXF0Fqk8).

GOST 2.1 added remote port forwarding, which maps an intranet port to a specified external port. However, TCP remote port forwarding has a limitation: each time a connection is made to the external mapped port, the listening port closes and waits for the intranet gost to re-establish the connection and reopen it.

This limits its use to single-connection services like SSH, while multi-connection services like HTTP are not feasible.

GOST 2.2 added HTTP/2 support. Since HTTP/2 supports multiplexing — especially for HTTP — a single connection can transport multiple request/response pairs. This allows us to use HTTP/2 to access intranet HTTP services from the external network.

<!-- more -->

Assume a public server A with IP `1.2.3.4`.

Intranet server B with IP `192.168.1.100`.

First, run gost on public server A:

```bash
gost -L http2://:443
```

Run gost on intranet server B (must be in HTTP/2 mode):

```bash
gost -L http2://:8080
```

**Important step**: On intranet server B, enable TCP remote port forwarding:

```bash
gost -L rtcp://:1443/:8080 -F http2://1.2.3.4:443
```

This maps the HTTP/2 proxy port on intranet server B to port 1443 on the external server. Accessing the external server's 1443 port is equivalent to accessing the intranet's 8080 port.

Suppose there is a router at `192.168.1.1` on B's network. On another computer C (which can access port 1443 of server A), run:

```
gost -L :8888 -F http2://1.2.3.4:1443
```

This effectively uses intranet server B's HTTP/2 proxy (port 8080), giving access to any service on B's network. Set the browser proxy on machine C to `localhost:8888`, and navigate to `192.168.1.1` to access the router's admin interface.
