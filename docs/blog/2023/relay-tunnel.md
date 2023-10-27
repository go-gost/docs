---
template: blog.html
author: ginuerzh
author_gh_user: ginuerzh
read_time: 15min
publish_date: 2023-02-12 23:00
---

上一篇[博文](https://gost.run/blog/2023/reverse-proxy/)中，对反向代理和内网穿透做了基本的介绍。本篇将通过具体应用案例更加直观的展示[反向代理隧道](https://gost.run/tutorials/reverse-proxy-tunnel/)的使用。

反向代理隧道是将反向代理和内网穿透两个功能相结合一种技术手段，这两个概念之间其实没有必然的联系，反向代理可以不使用内网穿透，内网穿透也并不一定是为了实现反向代理，只不过很多情况下我们需要这两个功能组合在一起使用。例如一般的家庭网络或公司网络可能没有公网IP，因此无法通过公网直接访问，这个时候就需要用到内网穿透，通过一台具有公网IP的机器来间接的访问内网的服务。

假设有一台公网服务器并且绑定了域名my.domain。我们想要通过域名router.my.domain来访问到家庭网络中的路由器(192.168.1.1:80)，并想要通过域名work.my.domain来访问公司中的项目管理平台(172.10.1.1:80)。

## 服务端

这里使用Docker Compose来简化部署，并且使用Traefik作为前置代理，通过域名将流量路由到隧道服务。

隧道服务监听在8080端口采用websocket传输方式并通过域名tunnel.my.domain来访问。router.my.domain和work.my.domain的流量通过traefik路由到了公共入口点(entrypoint)8000端口。

服务端定义了两条隧道：

* router.my.domain对应隧道`6c538042-cc24-4910-8887-0f50916ad97f`将连接到家庭网络。
* work.my.domain对应隧道`68e15803-a287-4ebd-b2ac-1aee1aa733ca`将连接到公司网络。

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
        # The HTTP port
        - "80:80"
        # The HTTPS port
        - "443:443"
        volumes:
        # So that Traefik can listen to the Docker events
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

## 客户端

在家庭网络的一台机器上运行以下命令建立到服务端的隧道

```bash
gost -L rtcp://:0/192.168.1.1:80 -F tunnel+wss://tunnel.my.domain:443?tunnel.id=6c538042-cc24-4910-8887-0f50916ad97f
```

在公司网络的一台机器上运行以下命令建立到服务端的隧道

```bash
gost -L rtcp://:0/172.10.1.1:80 -F tunnel+wss://tunnel.my.domain:443?tunnel.id=68e15803-a287-4ebd-b2ac-1aee1aa733ca
```

如果家庭或公司内的服务需要通过域名来访问(例如家庭内部需要通过router.my.home来访问路由器)可以做如下设置

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
      # host: router.my.domain
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

以上设置完毕后，就可以通过router.my.domain来访问到家庭路由器，通过work.my.domain访问到公司项目管理平台。

