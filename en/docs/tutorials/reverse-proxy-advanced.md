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
    endpoint: $aede1f6a-762b-45da-b937-b6632356555a # private tunnel for ssh traffic
  - hostname: "redis.srv-3.local" 
    endpoint: $aede1f6a-762b-45da-b937-b6632356555a # private tunnel for redis traffic
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

    ```bash
    gost -L tcp://:8000?sniffing=true -F relay://:8443?tunnelID=ac74d9dd-3125-442a-a7c1-f9e49e05faca
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

### TCP Service

Private tunnel can also be applied to TCP services (such as SSH) for non-HTTP traffic. In the above example, the tunnel corresponding to the `ssh.srv-2.local` and `redis.srv-3.local` in the Ingress of the server can be regarded as a dedicated tunnel for SSH and redis traffic.

![Reverse Proxy - TCP Private Tunnel](/images/private-tunnel-tcp.png) 

#### Client

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

#### Visitor

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