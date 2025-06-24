---
comments: true
---

# TUN Networking Solution Based On Routing Tunnel

In the previous [TUN/TAP device](tuntap.md) tutorial, a simple networking solution was implemented using a client/server architecture based on UDP communication. In this mode, the server acts as a data router between multiple clients. In this tutorial, a more general and flexible routing tunnel will be used to implement data routing.

## Routing Tunnel

Routing tunnel is a tunnel service used for data routing. It currently supports IP packet routing and is used to support TUN device networking.

**Server**

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

The routing tunnel service defines data routing rules through a [router](../concepts/router.md). Data sent to 192.168.123.1 and 192.168.100.0/24 is routed to host host-1, and data sent to 192.168.123.2 and 192.168.200.0/24 is routed to host host-2.


**Client**

=== "CLI"

    ```bash
    gost -L "tun:///host-1?net=192.168.123.1/24" -F "router://server_ip:8443"
    ```

=== "File (YAML)"

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

The client sets the host name to host-1 and reports it to the routing tunnel.

## Routing Namespace

Similar to the concept of network namespace, routing tunnels also support namespaces. Data and routing rules in different namespaces are isolated from each other and do not affect each other.

**Server**

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

The server defines multiple groups of routers, each of which is assigned a unique ID by `name`. The client uses this ID to select the routing rule to use. A default router (router-0) can also be defined. When the router specified by the client does not exist, this default router is used.

**Client**

=== "CLI"

    ```bash
    gost -L "tun:///host-1?net=192.168.123.1/24" -F "router://server_ip:8443?router.id=e87f56dd-fd57-4921-9ab8-a0847662daae"
    ```

=== "File (YAML)"

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

The client specifies the routing table to use via `router.id` option.

## Ingress

Routing tunnels can use [Ingress](../concepts/ingress.md) to restrict client access.

**Server**

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

The rules in Ingress are the restrictions on host names to routing tables. For example, hosts `host-1-ns1` and `host-2-ns1` are restricted to use only routing table e87f56dd-fd57-4921-9ab8-a0847662daae, and hosts `host-1-ns2` and `host-2-ns2` are restricted to use only routing table ef502590-c5f4-437e-a81f-fe4083505075.