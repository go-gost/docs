---
comments: true
---

# 基于路由隧道的TUN组网方案

:material-tag: 3.1.0

在前一篇[TUN/TAP设备](tuntap.md)教程中，采用客户端/服务器架构，基于UDP通讯的方式实现了简单的组网方案。这种模式下，服务端充当了多个客户端之间的数据路由角色。本篇中将使用更加通用且灵活的路由隧道来实现数据路由功能。

## 路由隧道

路由隧道是用来进行数据路由的隧道服务，目前支持IP数据包路由，用来支持TUN设备组网。

**服务端**

```yaml
services:
  - name: service-0
    addr: :8443
    handler:
      type: router
      metadata:
        router: router-0
    listener:
      type: tcp
routers:
  - name: router-0
    routes:
      - dst: 192.168.123.1
        gateway: host-1
      - dst: 192.168.100.0/24
        gateway: host-1
      - dst: 192.168.123.2
        gateway: host-2
      - dst: 192.168.200.0/24
        gateway: host-2
```

路由隧道服务通过[路由器](../concepts/router.md)来定义数据的路由规则，发往192.168.123.1和192.168.100.0/24的数据被路由到主机host-1，发往192.168.123.2和192.168.200.0/24的数据被路由到主机host-2。


**客户端**

=== "命令行"

    ```bash
    gost -L "tun:///host-1?net=192.168.123.1/24" -F "router://server_ip:8443"
    ```

=== "配置文件"

    ```yaml
    services:
    - name: service-0
      handler:
        type: tun
      listener:
        type: tun
        metadata:
          net: 192.168.123.1/24
          route: 192.168.200.0/24
      forwarder:
        nodes:
        - name: host
          addr: host-1
    chains:
    - name: chain-0
      hops:
      - name: hop-0
        nodes:
        - name: node-0
          addr: server_ip:8443
          connector:
            type: router
          dialer:
            type: tcp
    ```

客户端设置主机名为host-1，并通报给路由隧道。

## 路由命名空间

与网络命名空间的概念类似，路由隧道也支持命名空间，不同命名空间中的数据和路由规则相互隔离互不影响。

**服务端**

```yaml
services:
  - name: service-0
    addr: :8443
    handler:
      type: router
      metadata:
        router: router-0 # optional
    listener:
      type: tcp

routers:
  - name: e87f56dd-fd57-4921-9ab8-a0847662daae
    routes:
      - dst: 192.168.123.1
        gateway: host-1
      - dst: 192.168.10.0/24
        gateway: host-1
      - dst: 192.168.123.2
        gateway: host-2
      - dst: 192.168.11.0/24
        gateway: host-2
  - name: ef502590-c5f4-437e-a81f-fe4083505075
    routes: 
      - dst: 192.168.124.1
        gateway: host-1
      - dst: 192.168.100.0/24
        gateway: host-1
      - dst: 192.168.124.2
        gateway: host-2
      - dst: 192.168.101.0/24
        gateway: host-2
  - name: router-0
    plugin:
      type: http
      addr: http://127.0.0.1:8000
```

服务端定义多组路由器，每个路由器通过`name`指定唯一ID，客户端通过此ID来选择所使用的路由规则。同时也可以定义一个默认的路由器(router-0)，当客户端指定的路由器不存在时，则使用此默认路由器。

**客户端**

=== "命令行"

    ```bash
    gost -L "tun:///host-1?net=192.168.123.1/24" -F "router://server_ip:8443?router.id=e87f56dd-fd57-4921-9ab8-a0847662daae"
    ```

=== "配置文件"

    ```yaml hl_lines="24"
    services:
    - name: service-0
      handler:
        type: tun
      listener:
        type: tun
        metadata:
          net: 192.168.123.1/24
          route: 192.168.200.0/24
      forwarder:
        nodes:
        - name: host
          addr: host-1
    chains:
    - name: chain-0
      hops:
      - name: hop-0
        nodes:
        - name: node-0
          addr: server_ip:8443
          connector:
            type: router
            metadata:
              router.id: e87f56dd-fd57-4921-9ab8-a0847662daae
          dialer:
            type: tcp
    ```

客户端通过`router.id`选项指定所使用的路由表。

## Ingress

路由隧道可以使用[Ingress](../concepts/ingress.md)来限制客户端的接入。

**服务端**

```yaml
services:
  - name: service-0
    addr: :8443
    handler:
      type: router
      metadata:
        router: router-0
        ingress: ingress-0
    listener:
      type: tcp

ingresses:
  - name: ingress-0
    rules:
     - hostname: host-1-ns1
       endpoint: e87f56dd-fd57-4921-9ab8-a0847662daae
     - hostname: host-2-ns1
       endpoint: e87f56dd-fd57-4921-9ab8-a0847662daae
     - hostname: host-1-ns2
       endpoint: ef502590-c5f4-437e-a81f-fe4083505075
     - hostname: host-2-ns2
       endpoint: ef502590-c5f4-437e-a81f-fe4083505075
    
routers:
  - name: e87f56dd-fd57-4921-9ab8-a0847662daae
    routes:
      - dst: 192.168.123.1
        gateway: host-1
      - dst: 192.168.10.0/24
        gateway: host-1
      - dst: 192.168.123.2
        gateway: host-2
      - dst: 192.168.11.0/24
        gateway: host-2
  - name: ef502590-c5f4-437e-a81f-fe4083505075
    routes: 
      - dst: 192.168.124.1
        gateway: host-1
      - dst: 192.168.100.0/24
        gateway: host-1
      - dst: 192.168.124.2
        gateway: host-2
      - dst: 192.168.101.0/24
        gateway: host-2
  - name: router-0
    plugin:
      type: http
      addr: http://127.0.0.1:8000
```

Ingress中的规则为主机名到路由表的限定条件。例如主机host-1-ns1和host-2-ns1被限定为只能只用路由表e87f56dd-fd57-4921-9ab8-a0847662daae，主机host-1-ns2和host-2-ns2被限定为只能使用路由表ef502590-c5f4-437e-a81f-fe4083505075。
