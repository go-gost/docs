---
authors:
  - ginuerzh
categories:
  - Reverse Proxy
readtime: 15
date: 2023-02-12
comments: true
---

# Reverse Proxy Tunnel in Practice

The [previous post](https://gost.run/blog/2023/reverse-proxy/) introduced reverse proxy and intranet penetration concepts. This post demonstrates practical use of the [reverse proxy tunnel](https://gost.run/tutorials/reverse-proxy-tunnel/) through concrete examples.

A reverse proxy tunnel combines reverse proxy with intranet penetration. These two concepts aren't inherently linked — reverse proxy can function without intranet penetration, and intranet penetration isn't solely for reverse proxy. However, many scenarios require combining them. For example, home or corporate networks may lack a public IP, making direct public access impossible — intranet penetration via a public IP server provides indirect access to intranet services.

<!-- more -->

Assume a public server with domain `my.domain`. We want `router.my.domain` to access the home router (`192.168.1.1:80`) and `work.my.domain` to access the company project management platform (`172.10.1.1:80`).

## Server Side

Using Docker Compose with Traefik as the front-end proxy for domain-based routing to the tunnel service.

The tunnel service listens on port 8080 using WebSocket transport, accessible via `tunnel.my.domain`. Traefik routes `router.my.domain` and `work.my.domain` traffic to the public entry point on port 8000.

Two tunnels are defined:
- `router.my.domain` → tunnel `6c538042-cc24-4910-8887-0f50916ad97f` → home network
- `work.my.domain` → tunnel `68e15803-a287-4ebd-b2ac-1aee1aa733ca` → company network

!!! example "docker-compose.yaml"

    ```yaml
    version: '3'
    services:
      traefik:
        image: traefik:v2.9.6
        restart: always
        command:
        - "--providers.docker"
        - "--entrypoints.web.address=:80"
        - "--entrypoints.websecure.address=:443"
        - "--entrypoints.web.http.redirections.entryPoint.to=websecure"
        - "--entrypoints.web.http.redirections.entryPoint.scheme=https"
        ports:
        - "80:80"
        - "443:443"
        volumes:
        - "/var/run/docker.sock:/var/run/docker.sock:ro"

      gost-tunnel:
        image: gogost/gost:3.0.0-rc10
        command: "-L tunnel+ws://:8080?entrypoint=:8000&tunnel=router.my.domain:6c538042-cc24-4910-8887-0f50916ad97f,work.my.domain:68e15803-a287-4ebd-b2ac-1aee1aa733ca"
        restart: always
        labels:
        - "traefik.http.routers.gost-tunnel.tls=true"
        - "traefik.http.routers.gost-tunnel.rule=Host(`tunnel.my.domain`)"
        - "traefik.http.routers.gost-tunnel.service=gost-tunnel"
        - "traefik.http.services.gost-tunnel.loadbalancer.server.port=8080"
        - "traefik.http.routers.gost-ingress.tls=true"
        - "traefik.http.routers.gost-ingress.rule=Host(`router.my.domain`, `work.my.domain`)"
        - "traefik.http.routers.gost-ingress.service=gost-ingress"
        - "traefik.http.services.gost-ingress.loadbalancer.server.port=8000"
    ```

## Client Side

On a machine in the home network, establish a tunnel to the server:

```bash
gost -L rtcp://:0/192.168.1.1:80 -F tunnel+wss://tunnel.my.domain:443?tunnel.id=6c538042-cc24-4910-8887-0f50916ad97f
```

On a machine in the company network:

```bash
gost -L rtcp://:0/172.10.1.1:80 -F tunnel+wss://tunnel.my.domain:443?tunnel.id=68e15803-a287-4ebd-b2ac-1aee1aa733ca
```

For services accessed by domain internally (e.g., home router via `router.my.home`):

```yaml
services:
- name: service-0
  addr: :0
  handler:
    type: rtcp
    metadata:
      sniffing: true
  listener:
    type: rtcp
    chain: chain-0
  forwarder:
    nodes:
    - name: router
      addr: 192.168.1.1:80
      http:
        host: router.my.home
chains:
- name: chain-0
  hops:
  - name: hop-0
    nodes:
    - name: node-0
      addr: tunnel.my.domain:443
      connector:
        type: tunnel
        metadata:
          tunnel.id: 6c538042-cc24-4910-8887-0f50916ad97f
      dialer:
        type: wss
```

After setup, `router.my.domain` accesses the home router and `work.my.domain` accesses the company project management platform.
