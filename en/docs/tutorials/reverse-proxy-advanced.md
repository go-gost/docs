# Reverse Proxy Tunnel

In the previous [Reverse Proxy](/en/tutorials/reverse-proxy/) tutorial, port forwarding was used to implement a simple reverse proxy function. In this article, the Tunnel function of the Relay protocol will be used to implement an enhanced reverse proxy similar to [Cloudflare Tunnel ](https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/).

## Tunnel

Tunnel is a (logical) channel between the server and the client. The server will listen on the entry point at the same time, and the traffic entering from the entry point will be sent to the client through the tunnel. Each tunnel has a unique ID (legal UUID), and a tunnel can have multiple connections (connection pools) to achieve high availability.

![Reverse Proxy - Remote TCP Port Forwarding](/images/reverse-proxy-rtcp2.png) 

### Server

```yaml hl_lines="7 8"
services:
- name: service-0
  addr: :8443
  handler:
    type: relay
    metadata:
      entryPoint: ":80"
      ingress: ingress-0
  listener:
    type: tcp

ingresses:
- name: ingress-0
  rules:
  - hostname: ".example.com"
    endpoint: 4d21094e-b74c-4916-86c1-d9fa36ea677b
  - hostname: "example.org"
    endpoint: ac74d9dd-3125-442a-a7c1-f9e49e05faca
```

When the Relay service sets the `entryPoint` option, the tunnel mode will be enabled, and the entryPoint specifies the entry point of the traffic. At the same time, specify [Ingress](/en/concepts/ingress/) through the `ingress` option to define traffic routing rules.

!!! note "Tunnel ID Allocation"
    The tunnel ID should be allocated by the server in advance and recorded in the Ingress. If the client uses a tunnel ID that is not registered in the Ingress, traffic cannot be routed to the client.

### Client

=== "CLI"

    ```bash
    gost -L rtcp://:0/192.168.1.1:80 -F relay://:8443?tunnelID=4d21094e-b74c-4916-86c1-d9fa36ea677b
    ```

=== "File (YAML)"

    ```yaml
    services:
    - name: service-0
      addr: :0
      handler:
        type: rtcp
      listener:
        type: rtcp
        chain: chain-0
      forwarder:
        nodes:
        - name: target-0
          addr: 192.168.1.1:80
    chains:
    - name: chain-0
      hops:
      - name: hop-0
        nodes:
        - name: node-0
          addr: :8443
          connector:
            type: relay
            metadata:
              tunnelID: 4d21094e-b74c-4916-86c1-d9fa36ea677b
          dialer:
            type: tcp
    ```

When the Relay client sets the `tunnelID` option, the tunnel mode is enabled, and the `addr` parameter specified in the rtcp service is invalid at this time.

In this example, when the traffic enters the entry point (port 80 of the server), it will sniff the traffic to obtain the hostname, and then find the matching rule in the Ingress through the hostname to obtain the corresponding service endpoint (tunnel) , and finally obtain a valid connection in the connection pool of the tunnel (round robin strategy, up to 3 failed retries) and send the traffic to the client through this connection.

When the hostname is `example.com`, the tunnel with the ID 4d21094e-b74c-4916-86c1-d9fa36ea677b is matched according to the rules in the Ingress. When the traffic reaches the client, it is forwarded by the rtcp service to the 192.168.1.1:80 service.

!!! tip "High Availability"
    In order to improve the availability of a single tunnel, multiple clients can be run, and these clients use the same tunnel ID.

## Client Routing

The client can also enable traffic sniffing at the same time to re-route the traffic.

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
    - name: example-com
      addr: 192.168.1.1:80
      host: example.com
    - name: sub-example-com
      addr: 192.168.1.2:80
      host: sub.example.com
    - name: fallback
      addr: 192.168.2.1:80
chains:
- name: chain-0
  hops:
  - name: hop-0
    nodes:
    - name: node-0
      addr: :8443
      connector:
        type: relay
        metadata:
          tunnelID: 4d21094e-b74c-4916-86c1-d9fa36ea677b
      dialer:
        type: tcp
```

When the hostname is `example.com`, the tunnel 4d21094e-b74c-4916-86c1-d9fa36ea677b is matched according to the rules in the Ingress. When the traffic reaches the client, it is forwarded by the rtcp service to the 192.168.1.1:80 service.

When the hostname is `sub.example.com`, it matches the tunnel 4d21094e-b74c-4916-86c1-d9fa36ea677b according to the rules in the Ingress. When the traffic reaches the client, it is forwarded by the rtcp service to the 192.168.1.2:80 service.

When the hostname is `abc.example.com`, according to the rules in the Ingress, the tunnel 4d21094e-b74c-4916-86c1-d9fa36ea677b is matched. When the traffic reaches the client, it is forwarded by the rtcp service to the 192.168.2.1:80 service.

## Private Tunnel

In Ingress, access to the tunnel can be restricted by marking the tunnel as private, and the traffic entering from the public entry point cannot be routed to the private tunnel.

To use a private tunnel, the user (visitor side) needs to start a service as the private entry point. This service specifies the tunnel to be accessed by setting the tunnel ID (not limited to the private tunnel).

![Reverse Proxy - Web Private Tunnel](/images/private-tunnel-web.png) 

### Server

```yaml hl_lines="19"
services:
- name: service-0
  addr: :8443
  handler:
    type: relay
    metadata:
      entryPoint: ":80"
      ingress: ingress-0
  listener:
    type: tcp
ingresses:
- name: ingress-0
  rules:
  - hostname: "srv-0.local"
    endpoint: 4d21094e-b74c-4916-86c1-d9fa36ea677b
  - hostname: "srv-1.local"
    endpoint: 4d21094e-b74c-4916-86c1-d9fa36ea677b
  - hostname: "srv-2.local"
    endpoint: $ac74d9dd-3125-442a-a7c1-f9e49e05faca # private tunnel
  - hostname: "srv-3.local"
    endpoint: ac74d9dd-3125-442a-a7c1-f9e49e05faca
  - hostname: "ssh.srv-2.local" 
    endpoint: aede1f6a-762b-45da-b937-b6632356555a # tunnel for ssh TCP traffic
  - hostname: "redis.srv-3.local" 
    endpoint: aede1f6a-762b-45da-b937-b6632356555a # tunnel for redis TCP traffic
  - hostname: "dns.srv-2.local" 
    endpoint: aede1f6a-762b-45da-b937-b6632356555a # tunnel for DNS UDP traffic
  - hostname: "dns.srv-3.local" 
    endpoint: aede1f6a-762b-45da-b937-b6632356555a # tunnel for DNS UDP traffic
```

In the Ingress rule, mark the tunnel corresponding to this rule as private by adding `$` before the tunnel ID value represented by the endpoint, for example, the tunnel ac74d9dd-3125-442a-a7c1-f9e49e05faca corresponding to the above srv-2.local host  is a private tunnel, so traffic entering through port 80 of the public entry point cannot use this tunnel.

!!! note "Scope Of Privacy"
    The scope of privacy is Ingress rules, not the tunnel itself. The same tunnel can have different privacy in different rules. For example, in the above example, srv-2.local and srv-3.local use the same tunnel, but the tunnel in the corresponding rule of srv-3.local is not private, so traffic to srv-3.local can be routed to this tunnel.

### Client

=== "CLI"

    ```bash
    gost -L rtcp://:0/192.168.2.1:80 -F relay://:8443?tunnelID=ac74d9dd-3125-442a-a7c1-f9e49e05faca
    ```

=== "File (YAML)"

    ```yaml
    services:
    - name: service-0
      addr: :0
      handler:
        type: rtcp
      listener:
        type: rtcp
        chain: chain-0
      forwarder:
        nodes:
        - name: srv-2.local
          addr: 192.168.2.1:80
    chains:
    - name: chain-0
      hops:
      - name: hop-0
        nodes:
        - name: node-0
          addr: :8443
          connector:
            type: relay
            metadata:
              tunnelID: ac74d9dd-3125-442a-a7c1-f9e49e05faca
          dialer:
            type: tcp
    ```

The configuration of the client is the same as above.

### Visitor

=== "CLI"
    Automatically sniff the host name
    ```bash
    gost -L tcp://:8000?sniffing=true -F relay://:8443?tunnelID=ac74d9dd-3125-442a-a7c1-f9e49e05faca
    ```
    or specify host name manually
    ```bash
    gost -L tcp://:8000/srv-2.local:0 -F relay://:8443?tunnelID=ac74d9dd-3125-442a-a7c1-f9e49e05faca
    ```

=== "File (YAML)"
   
    ```yaml hl_lines="8 21"
      services:
      - name: service-0
        addr: :8000
        handler:
          type: tcp
          chain: chain-0
          metadata:
            sniffing: true
        listener:
          type: tcp
      chains:
      - name: chain-0
        hops:
        - name: hop-0
          nodes:
          - name: node-0
            addr: :8443
            connector:
              type: relay
              metadata:
                tunnelID: ac74d9dd-3125-442a-a7c1-f9e49e05faca
              dialer:
                type: tcp
    ```

The visitor start a service to listen on port 8000, and specifies the tunnel to be used by setting the `tunnelID` option.

## TCP Service

Tunnel can also be applied to any TCP service (such as SSH). In the above example, the tunnel corresponding to the `ssh.srv-2.local` and `redis.srv-3.local` in the Ingress of the server can be regarded as a dedicated tunnel for SSH and redis traffic.

![Reverse Proxy - TCP Private Tunnel](/images/private-tunnel-tcp.png) 

### Client

```yaml hl_lines="13 16"
services:
- name: service-0
  addr: :0
  handler:
    type: rtcp
  listener:
    type: rtcp
    chain: chain-0
  forwarder:
    nodes:
    - name: ssh
      addr: 192.168.2.1:22
      host: ssh.srv-2.local
    - name: redis
      addr: 192.168.2.2:6379
      host: redis.srv-3.local
chains:
- name: chain-0
  hops:
  - name: hop-0
    nodes:
    - name: node-0
      addr: :8443
      connector:
        type: relay
        metadata:
          tunnelID: aede1f6a-762b-45da-b937-b6632356555a
      dialer:
        type: tcp
```

The client's forwarder sets up two target nodes: the ssh service at 192.168.2.1:22 and the redis service at 192.168.2.2:6379.
Note that the `host` parameter on each node needs to match the `hostname` in the server-side Ingress corresponding rule.

### Visitor

=== "CLI"

    ssh service:
    ```bash
    gost -L tcp://:2222/ssh.srv-2.local:0 -F relay://:8443?tunnelID=aede1f6a-762b-45da-b937-b6632356555a
    ```
    or redis service:
    ```bash
    gost -L tcp://:6379/redis.srv-3.local:0 -F relay://:8443?tunnelID=aede1f6a-762b-45da-b937-b6632356555a
    ```

=== "File (YAML)"
   
```yaml hl_lines="11 12"
  services:
  - name: service-0
    addr: :2222
    handler:
      type: tcp
      chain: chain-0
    listener:
      type: tcp
    forwarder:
      nodes:
      - name: ssh
        addr: ssh.srv-2.local:0
      # - name: redis
      #   addr: redis.srv-3.local:0
  chains:
  - name: chain-0
    hops:
    - name: hop-0
      nodes:
      - name: node-0
        addr: :8443
        connector:
          type: relay
          metadata:
            tunnelID: aede1f6a-762b-45da-b937-b6632356555a
          dialer:
            type: tcp
```

The visitor needs to specify the target node address in the forwarder, which needs to match the `hostname` in the corresponding rule of the server Ingress.

## UDP Service

Tunnel can also be applied to any UDP service (eg DNS). For example, the tunnel corresponding to the `dns.srv-2.local` and `dns.srv-3.local` hosts in the Ingress of the server above.

![Reverse Proxy - UDP Tunnel](/images/tunnel-udp.png) 

### Client

```yaml hl_lines="5 7 13 16"
services:
- name: service-0
  addr: :0
  handler:
    type: rudp
  listener:
    type: rudp
    chain: chain-0
  forwarder:
    nodes:
    - name: dns-1
      addr: 192.168.2.1:53
      host: dns.srv-2.local
    - name: dns-2
      addr: 192.168.2.2:53
      host: dns.srv-3.local
chains:
- name: chain-0
  hops:
  - name: hop-0
    nodes:
    - name: node-0
      addr: :8443
      connector:
        type: relay
        metadata:
          tunnelID: aede1f6a-762b-45da-b937-b6632356555a
      dialer:
        type: tcp
```

The client's forwarder sets up two target nodes: the dns service at 192.168.2.1:53 and the dns service at 192.168.2.2:53.
Note that the `host` parameter on each node needs to match the `hostname` in the server-side Ingress corresponding rule.

### Visitor

=== "CLI"

    dns-1
    ```bash
    gost -L tcp://:1053/dns.srv-2.local:0 -F relay://:8443?tunnelID=aede1f6a-762b-45da-b937-b6632356555a
    ```
    or dns-2
    ```bash
    gost -L tcp://:2053/dns.srv-3.local:0 -F relay://:8443?tunnelID=aede1f6a-762b-45da-b937-b6632356555a
    ```

=== "File (YAML)"
   
    ```yaml hl_lines="5 8 11 12"
      services:
      - name: service-0
        addr: :1053
        handler:
          type: udp
          chain: chain-0
        listener:
          type: udp
        forwarder:
          nodes:
          - name: dns-1
            addr: dns.srv-2.local:0
          # - name: dns-2
          #   addr: dns.srv-3.local:0
      chains:
      - name: chain-0
        hops:
        - name: hop-0
          nodes:
          - name: node-0
            addr: :8443
            connector:
              type: relay
              metadata:
                tunnelID: aede1f6a-762b-45da-b937-b6632356555a
              dialer:
                type: tcp
    ```

The visitor needs to specify the target node address in the forwarder, which needs to match the `hostname` in the corresponding rule of the server Ingress.

## Multiplexing

The tunnel itself supports multiplexing. A single tunnel is not limited to a certain type of traffic, but also supports simultaneous transmission of different types of traffic (Web, TCP, UDP). Next, a specific example will be used to illustrate.

## iperf Test Through Tunnel

![Reverse Proxy - iperf3](/images/tunnel-iperf.png) 

### Server

The server assigns a virtual host named `iperf.local` corresponding to a tunnel, and this tunnel will carry both TCP and UDP traffic of iperf.

```yaml hl_lines="19"
services:
- name: service-0
  addr: :8443
  handler:
    type: relay
    metadata:
      ingress: ingress-0
  listener:
    type: tcp
ingresses:
- name: ingress-0
  rules:
  - hostname: "iperf.local"
    endpoint: 22f43305-42f7-4232-bbbc-aa6c042e3bc3
```


### Client

Since there is only one forwarding target, you can use the command line to forward directly. If you want to forward multiple services, you need to define the host name (`forwarder.nodes.host`) for each target node in the forwarder through the configuration file. Through the host name to match different services.

=== "CLI"

    ```bash
    gost -L rtcp://:0/:5201 -L rudp://:0/:5201 -F relay://:8443?tunnelID=22f43305-42f7-4232-bbbc-aa6c042e3bc3
    ```

=== "File (YAML)"

    ```yaml
    services:
    - name: iperf-tcp
      addr: :0
      handler:
        type: rtcp
      listener:
        type: rtcp
        chain: chain-0
      forwarder:
        nodes:
        - name: iperf
          addr: :5201
          host: iperf.local
    - name: iperf-udp
      addr: :0
      handler:
        type: rudp
      listener:
        type: rudp
        chain: chain-0
      forwarder:
        nodes:
        - name: iperf
          addr: :5201
          host: iperf.local
    chains:
    - name: chain-0
      hops:
      - name: hop-0
        nodes:
        - name: node-0
          addr: :8443
          connector:
            type: relay
            metadata:
              tunnelID: 22f43305-42f7-4232-bbbc-aa6c042e3bc3
          dialer:
            type: tcp
    ```

### Visitor

The forwarded target address needs to match the host name corresponding to the rule in the Ingress of the server. If you want to forward multiple services, you need to define the host name (`forwarder.nodes.host`) for each target node in the forwarder through the configuration file, through host name to match different services.

!!! note "UDP Keepalive"
    By default, the UDP port forwarding service will invalidate the connection status after a data exchange, which is very effective for services like DNS. However, for UDP services that require multiple data interactions, the connection maintenance function needs to be enabled through the `keepalive` option. In addition, the timeout period can be controlled by the `ttl` option. By default, the connection status will be invalid if there is no data interaction for more than 5 seconds.

=== "CLI"

    ```bash
    gost -L tcp://:15201/iperf.local:0 -L udp://:15201/iperf.local:0?keepalive=true -F relay://:8443?tunnelID=22f43305-42f7-4232-bbbc-aa6c042e3bc3
    ```

=== "File (YAML)"
   
    ```yaml hl_lines="5 8 11 12"
      services:
      - name: iperf-tcp
        addr: :15201
        handler:
          type: tcp
          chain: chain-0
        listener:
          type: tcp
        forwarder:
          nodes:
          - name: iperf
            addr: iperf.local:0
      services:
      - name: iperf-udp
        addr: :15201
        handler:
          type: udp
          chain: chain-0
        listener:
          type: udp
          metadata:
            keepalive: true
            # ttl: 5s
        forwarder:
          nodes:
          - name: iperf
            addr: iperf.local:0
      chains:
      - name: chain-0
        hops:
        - name: hop-0
          nodes:
          - name: node-0
            addr: :8443
            connector:
              type: relay
              metadata:
                tunnelID: 22f43305-42f7-4232-bbbc-aa6c042e3bc3
              dialer:
                type: tcp
    ```

### iperf3 Server

Start iperf3 server.

```
iperf3 -s
```

### iperf3 Test

TCP Test

```
iperf3 -c 127.0.0.1 -p 15201
```

UDP Test

```
iperf3 -c 127.0.0.1 -p 15201 -u
```