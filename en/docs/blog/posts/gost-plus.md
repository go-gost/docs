---
authors:
  - ginuerzh
categories:
  - Reverse Proxy
readtime: 10
date: 2023-10-15
comments: true
---

# GOST.PLUS — Public Reverse Proxy Service

The [reverse proxy tunnel](https://gost.run/tutorials/reverse-proxy-tunnel/) is one of the major new features in GOST, and a very important one. With reverse proxy and intranet penetration, you can easily expose internal web services to the public network for access anytime, anywhere.

To test this feature more comprehensively and provide a quick way for users needing temporary public access to internal services, we launched the `GOST.PLUS` public reverse proxy test service. This service is open to all users without registration.

<!-- more -->

This is primarily a testing service. All public access points are temporary, with a 24-hour validity period.

## Usage

Suppose you have a local HTTP service `192.168.1.1:80` that needs temporary public exposure. Run the following command on your local machine:

```bash
gost -L rtcp://:0/192.168.1.1:80 -F tunnel+wss://tunnel.gost.plus:443?tunnel.id=f8baa731-4057-4300-ab75-c4e603834f1b
```

Or use a randomly generated tunnel ID (omit the `tunnel.id` option):

```bash
gost -L rtcp://:0/192.168.1.1:80 -F tunnel+wss://tunnel.gost.plus:443
```

!!! tip "Tunnel ID"
    Each tunnel is uniquely identified by its `tunnel.id`. Each tunnel ID corresponds to a unique public access point. The tunnel ID is a valid UUID, which can be generated using any UUID generator.

!!! caution
    The tunnel ID is the sole credential for the tunnel and service. Keep it secure to prevent leakage and abuse.

If the tunnel is established successfully, the following log output appears:

```json
{"connector":"tunnel","dialer":"wss","endpoint":"f1bbbb4aa9d9868a","hop":"hop-0","kind":"connector","level":"info",
"msg":"create tunnel on f1bbbb4aa9d9868a:0/tcp OK, tunnel=f8baa731-4057-4300-ab75-c4e603834f1b, connector=df4d62df-8b73-478a-96a2-26826e9cd675",
"node":"node-0","time":"2023-10-15T14:21:29.580Z",
"tunnel":"f8baa731-4057-4300-ab75-c4e603834f1b"}
```

The `endpoint` field value `f1bbbb4aa9d9868a` is the public access point. You can now access the internal `192.168.1.1:80` service via `https://f1bbbb4aa9d9868a.gost.plus`.

## Custom Public Access Point

You can also specify a custom access point name:

```bash
gost -L rtcp://hello/192.168.1.1:80 -F tunnel+wss://tunnel.gost.plus:443?tunnel.id=f8baa731-4057-4300-ab75-c4e603834f1b
```

This sets the access point to `hello`, accessible via `https://hello.gost.plus`.

!!! note "Binding Access Points"
    Each access point registers and binds to a tunnel ID on first use, with a binding duration of 1 hour. During this time, other tunnels cannot bind to this access point. After timeout, the binding expires and the access point can be bound to a different tunnel.

For more settings and usage, refer to the [reverse proxy documentation](https://gost.run/tutorials/reverse-proxy/).

## TCP Services

TCP services can also be accessed via private tunnels. Assume `192.168.1.1:22` is an SSH service:

```bash
gost -L rtcp://:0/192.168.1.1:22 -F tunnel+wss://tunnel.gost.plus:443?tunnel.id=f8baa731-4057-4300-ab75-c4e603834f1b
```

To access this service, start a private entry point on the accessing end:

```bash
gost -L tcp://:2222/f1bbbb4aa9d9868a.gost.plus -F tunnel+wss://tunnel.gost.plus:443?tunnel.id=f8baa731-4057-4300-ab75-c4e603834f1b
```

The tunnel IDs on both ends must match for access to work.

Then SSH to `192.168.1.1:22`:

```bash
ssh -p 2222 user@localhost
```

## UDP Services

Similarly, shared UDP services can be exposed via private tunnels. Assume `192.168.1.1:53` is a DNS service:

```bash
gost -L rudp://:0/192.168.1.1:53 -F tunnel+wss://tunnel.gost.plus:443?tunnel.id=f8baa731-4057-4300-ab75-c4e603834f1b
```

Start a private entry point on the accessing end:

```bash
gost -L udp://:1053/f1bbbb4aa9d9868a.gost.plus -F tunnel+wss://tunnel.gost.plus:443?tunnel.id=f8baa731-4057-4300-ab75-c4e603834f1b
```

Test it:

```bash
dig -p 1053 @127.0.0.1
```

## Self-Hosted Public Reverse Proxy

You can also set up your own reverse proxy service:

`gost.yml`
```yaml
services:
- name: service-0
  addr: :8080
  handler:
    type: tunnel
    metadata:
      entrypoint: :8000
      ingress: ingress-0
  listener:
    type: ws

ingresses:
- name: ingress-0
  plugin:
    type: grpc
    addr: gost-plugins:8000
```
