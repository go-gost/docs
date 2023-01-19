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
      entryPoint: ":8000"
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

### Client

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

In this example, when the traffic enters the entry point (port 8000 of the server), it will sniff the traffic to obtain the hostname, and then find the matching rule in the Ingress through the hostname to obtain the corresponding service endpoint (tunnel) , and finally obtain a valid connection in the connection pool of the tunnel (round robin strategy, up to 3 failed retries) and send the traffic to the client through this connection.

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
