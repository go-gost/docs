---
template: blog.html
author: ginuerzh
author_gh_user: ginuerzh
read_time: 10min
publish_date: 2023-10-15 22:00
---

[反向代理隧道](https://gost.run/tutorials/reverse-proxy-tunnel/)是GOST中新增的一个较大功能，同时也是一个很重要的功能，借助于反向代理和内网穿透，可以很方便的将内网Web服务暴露到公网，随时随地都能访问。

为了能够对此功能进行更全面的测试，同时也为了能够给需要临时暴露内网服务的用户提供一种快捷的方式，特公开推出`GOST.PLUS`公共反向代理测试服务。此服务面向所有用户开放，无需注册。

本服务以测试为主要目的，所有公共访问点均为临时访问点，有效期为1小时。

## 使用方法

假如本地有一个HTTP服务`192.168.1.1:80`需要临时暴露到公网，只需在本地机器上运行以下命令：

```bash
gost -L rtcp://:0/192.168.1.1:80 -F tunnel+wss://tunnel.gost.plus:443?tunnel.id=f8baa731-4057-4300-ab75-c4e603834f1b
```

或者使用随机生成的隧道ID(不设置`tunnel.id`选项):

```bash
gost -L rtcp://:0/192.168.1.1:80 -F tunnel+wss://tunnel.gost.plus:443
```

!!! tip "隧道ID"
    每个隧道通过`tunnel.id`指定的隧道ID来唯一标识，每个隧道ID对应唯一的一个公共访问点。隧道ID是一个合法的UUID，可以通过UUID生成器来生成。

!!! caution
    隧道ID作为隧道和服务的唯一凭证，请妥善保管，防止泄露被滥用。

执行后如果隧道建立成功则会有以下日志输出：

```json
{"connector":"tunnel","dialer":"wss","endpoint":"f1bbbb4aa9d9868a","hop":"hop-0","kind":"connector","level":"info",
"msg":"create tunnel on f1bbbb4aa9d9868a:0/tcp OK, tunnel=f8baa731-4057-4300-ab75-c4e603834f1b, connector=df4d62df-8b73-478a-96a2-26826e9cd675",
"node":"node-0","time":"2023-10-15T14:21:29.580Z",
"tunnel":"f8baa731-4057-4300-ab75-c4e603834f1b"}
```

日志的`endpoint`字段中`f1bbbb4aa9d9868a`即为此服务的公共访问点，此时通过`https://f1bbbb4aa9d9868a.gost.plus`便可访问到内网的192.168.1.1:80服务。

## 自定义公共访问点

除了自动生成公共访问点，也可以通过自己指定访问点名称：

```bash
gost -L rtcp://hello/192.168.1.1:80 -F tunnel+wss://tunnel.gost.plus:443?tunnel.id=f8baa731-4057-4300-ab75-c4e603834f1b
```

上面的命令中指定了公共访问点为`test`，便可以通过`https://hello.gost.plus`来访问。

!!! note "绑定访问点"
    每个访问点在第一次使用时会注册并绑定到对应的隧道ID，绑定时长为1小时，在此期间其他隧道无法再次绑定并使用此访问点。当超时后绑定将失效，访问点可以再次绑定到不同的隧道。

更多的设置和使用方法请参考[反向代理](https://gost.run/tutorials/reverse-proxy/)。

## TCP服务

对于TCP服务同样可以以私有隧道的方式来访问。这里假设192.168.1.1:22是一个SSH服务。

```bash
gost -L rtcp://:0/192.168.1.1:22 -F tunnel+wss://tunnel.gost.plus:443?tunnel.id=f8baa731-4057-4300-ab75-c4e603834f1b
```

要访问此服务需要在访问端开启一个私有入口点:

```bash
gost -L tcp://:2222/f1bbbb4aa9d9868a.gost.plus -F tunnel+wss://tunnel.gost.plus:443?tunnel.id=f8baa731-4057-4300-ab75-c4e603834f1b
```

注意两端的隧道ID必须匹配才能访问到隧道对应的服务。

此时在访问端执行以下命令便可以访问到192.168.1.1:22。

```bash
ssh -p 2222 user@localhost
```

## UDP服务

同样也可以以私有隧道的方式暴露共享UDP服务。这里假设192.168.1.1:53是一个DNS服务。

```bash
gost -L rudp://:0/192.168.1.1:53 -F tunnel+wss://tunnel.gost.plus:443?tunnel.id=f8baa731-4057-4300-ab75-c4e603834f1b
```

要访问此服务需要在访问端开启一个私有入口点:

```bash
gost -L udp://:1053/f1bbbb4aa9d9868a.gost.plus -F tunnel+wss://tunnel.gost.plus:443?tunnel.id=f8baa731-4057-4300-ab75-c4e603834f1b
```

注意两端的隧道ID必须匹配才能访问到隧道对应的服务。

此时在访问端执行以下命令便可以访问到192.168.1.1:53。

```bash
dig -p 1053 @127.0.0.1
```

## 自建公共反向代理

你也可以通过以下配置来搭建自己的反向代理服务。

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

log:
  level: info
```


`docker-compose.yml`

```yaml
version: '3'

services:
  traefik:
    image: traefik:v2.9.6
    restart: always
    command: 
      # - "--api.insecure=true"
      # - "--api.dashboard=true"
      - "--providers.docker"
      - "--entrypoints.web.address=:80"
      - "--entrypoints.websecure.address=:443"
      - "--entrypoints.web.http.redirections.entryPoint.to=websecure"
      - "--entrypoints.web.http.redirections.entryPoint.scheme=https"
      - "--log.level=INFO"
      - "--log.format=json"
      # - "--accesslog"
      # - "--accesslog.format=json"
      # - "--accesslog.filters.statuscodes=400-600"
      # - "--serversTransport.maxIdleConnsPerHost=0"
      # - "--serversTransport.forwardingTimeouts.idleConnTimeout=1s"
    ports:
      # The HTTP port
      - "80:80"
      # The HTTPS port
      - "443:443"
      # The Web UI (enabled by --api.insecure=true)
      # - "8080:8080"
    volumes:
      # So that Traefik can listen to the Docker events
      - "/var/run/docker.sock:/var/run/docker.sock:ro"

  gost-tunnel: 
    image: gogost/gost
    restart: always
    labels:
      - "traefik.http.routers.gost-tunnel.tls=true"
      - "traefik.http.routers.gost-tunnel.rule=Host(`tunnel.gost.local`)"
      - "traefik.http.routers.gost-tunnel.service=gost-tunnel"
      - "traefik.http.services.gost-tunnel.loadbalancer.server.port=8080"
      - "traefik.http.routers.gost-ingress.tls=true"
      - "traefik.http.routers.gost-ingress.service=gost-ingress"
      - "traefik.http.routers.gost-ingress.rule=HostRegexp(`{subdomain:[a-z0-9]+}.gost.local`)"
      - "traefik.http.routers.gost-ingress.priority=10"
      - "traefik.http.services.gost-ingress.loadbalancer.server.port=8000"
    volumes:
      - ./gost.yaml:/etc/gost/gost.yaml

  gost-plugins: 
    image: ginuerzh/gost-plugins
    restart: always
    command: "ingress --addr=:8000 --redis.addr=redis:6379 --redis.db=2 --redis.expiration=1h --domain=gost.local --log.level=debug"

  redis: 
    image: redis:7.2.1-alpine
    restart: always
    command: "redis-server --save 60 1 --loglevel warning"
    volumes:
      - redis:/data

volumes:
  redis:
    driver: local
```