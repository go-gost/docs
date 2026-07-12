---
authors:
  - ginuerzh
categories:
  - Deploy
  - Docker
  - K8S
readtime: 15
date: 2022-12-20
comments: true
---

# Deploying GOST Services with Traefik and Docker

[Traefik](https://traefik.io/traefik/) is a reverse proxy tool similar to Nginx, with cloud-native features that make it particularly convenient in Docker and Kubernetes environments.

Assume your domain is `gost.run`, with each service routed via a separate subdomain (URI path routing is also possible).

<!-- more -->

## Docker

Since both Traefik and GOST support Docker containers, Docker Compose simplifies deployment.

??? example "docker-compose.yaml"

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
        labels:
        - "traefik.http.routers.dashboard.tls=true"
        - "traefik.http.routers.dashboard.rule=Host(`traefik.gost.run`)"
        - "traefik.http.services.dashboard.loadbalancer.server.port=8080"

      gost-ws:
        image: gogost/gost
        restart: always
        command: "-L relay+ws://:8080"
        labels:
        - "traefik.http.routers.gost-ws.tls=true"
        - "traefik.http.routers.gost-ws.rule=Host(`ws.gost.run`)"
        - "traefik.http.services.gost-ws.loadbalancer.server.port=8080"

      gost-grpc:
        image: gogost/gost
        restart: always
        command: "-L relay+grpc://:8080?grpcInsecure=true"
        labels:
        - "traefik.http.routers.gost-grpc.tls=true"
        - "traefik.http.routers.gost-grpc.rule=Host(`grpc.gost.run`)"
        - "traefik.http.services.gost-grpc.loadbalancer.server.port=8080"
        - "traefik.http.services.gost-grpc.loadbalancer.server.scheme=h2c"

      gost-pht:
        image: gogost/gost
        restart: always
        command: "-L relay+pht://:8080"
        labels:
        - "traefik.http.routers.gost-pht.tls=true"
        - "traefik.http.routers.gost-pht.rule=Host(`pht.gost.run`)"
        - "traefik.http.services.gost-pht.loadbalancer.server.port=8080"

      watchtower:
        image: containrrr/watchtower:1.5.1
        restart: always
        volumes:
        - "/var/run/docker.sock:/var/run/docker.sock:ro"
        command: --interval 300
    ```

Deploy with a single command:

```bash
docker-compose -f docker-compose.yml -p web up -d
```

### Traefik

The `traefik` service exposes ports 80 and 443, redirecting HTTP to HTTPS. The dashboard can be enabled with `--api.insecure=true` and `--api.dashboard=true`, routed via `traefik.gost.run`.

### GOST WebSocket

`gost-ws` is a relay proxy using [WebSocket](https://gost.run/tutorials/protocols/ws/) as the data channel, listening on port 8080 and routed via `ws.gost.run`. TLS termination is handled by Traefik, so the WebSocket channel uses plaintext (ws instead of wss).

### GOST gRPC

`gost-grpc` uses [gRPC](https://gost.run/tutorials/protocols/grpc/) as the data channel, with `grpcInsecure=true` for plaintext and TLS handled by Traefik. An additional label `traefik.http.services.gost-grpc.loadbalancer.server.scheme=h2c` marks this as a gRPC service.

### GOST PHT

`gost-pht` uses [PHT](https://gost.run/tutorials/protocols/pht/) as the data channel, routed via `pht.gost.run`.

### Watchtower

[Watchtower](https://containrrr.github.io/watchtower) automatically updates running containers by periodically checking for new images.

## Kubernetes

Since Traefik is the default Ingress Controller in [k3s](https://k3s.io), we'll use k3s v1.24.3+k3s1 with Traefik v2.6.2.

??? example "deploy.yaml"

    ```yaml
    apiVersion: v1
    kind: Service
    metadata:
      name: gost-ws
    spec:
      selector:
        app: gost-ws
      ports:
      - name: ws
        port: 8080
        targetPort: ws
    ---
    apiVersion: v1
    kind: Service
    metadata:
      name: gost-grpc
    spec:
      selector:
        app: gost-grpc
      ports:
      - name: grpc
        port: 8080
        targetPort: grpc
    ---
    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: gost-ws
    spec:
      replicas: 1
      selector:
        matchLabels:
          app: gost-ws
      template:
        metadata:
          labels:
            app: gost-ws
        spec:
          containers:
          - image: gogost/gost
            name: gost
            args:
              - -L
              - relay+ws://:8080
            ports:
            - name: ws
              containerPort: 8080
              protocol: TCP
    ---
    apiVersion: networking.k8s.io/v1
    kind: Ingress
    metadata:
      name: gost-ws
      annotations:
        kubernetes.io/ingress.class: traefik
        traefik.ingress.kubernetes.io/preserve-host: "true"
    spec:
      rules:
      - host: ws.gost.run
        http:
          paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: gost-ws
                port:
                  name: ws
    ```

Apply:

```bash
kubectl apply -f deploy.yaml
```

## Cloudflare CDN

These three data channels (WebSocket, gRPC, PHT) can be used with reverse proxies like Traefik/Nginx and CDNs like Cloudflare. This provides free TLS certificates managed by the CDN while hiding your server IP.

For WebSocket, enable the WebSockets protocol in Cloudflare's Network settings.

Client connection:
```
gost -L :8080 -F relay+wss://ws.gost.run:443
```

For gRPC, enable gRPC in Cloudflare's Network settings.

Client connection:
```
gost -L :8080 -F relay+grpc://grpc.gost.run:443
```

For PHT, use it directly or with HTTP/3 acceleration by enabling HTTP/3 in Cloudflare.

Direct connection:
```
gost -L :8080 -F relay+phts://pht.gost.run:443
```

HTTP/3 acceleration:
```
gost -L :8080 -F relay+h3://pht.gost.run:443
```

Without a domain, use [host-IP mapping](https://gost.run/concepts/hosts/). Assuming your server IP is `192.168.1.2`:

```
gost -L :8080 -F relay+wss://ws.gost.run:443?hosts=ws.gost.run:192.168.1.2
```
