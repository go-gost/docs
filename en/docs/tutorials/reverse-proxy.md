# Reverse Proxy

[Reverse Proxy](https://en.wikipedia.org/wiki/Reverse_proxy) is a type of proxy service. According to the client's request, the server obtains resources from one or more groups of backend servers (such as web servers) related to it, and then returns these resources to the client. The client only knows the IP address of the reverse proxy, without knowing the existence of server clusters behind proxy servers.

The port forwarding service in GOST can also be regarded as a reverse proxy with limited functions, because it can only forward to a fixed one or a set of backend services.

Reverse proxy is an extension of the port forwarding service, which relies on the port forwarding function, and obtains the target host information in a specific protocol (currently supports HTTP/HTTPS) by sniffing the forwarded data.

## Local Port Forwarding

![Reverse Proxy - TCP Port Forwarding](/images/reverse-proxy-tcp.png) 

```yaml hl_lines="7 14 17"
services:
- name: https
  addr: :443
  handler:
    type: tcp
    metadata:
      sniffing: true
  listener:
    type: tcp
  forwarder:
    nodes:
    - name: google
      addr: www.google.com:443
      host: www.google.com
    - name: github
      addr: github.com:443
      host: "*.github.com"
      # host: .github.com
- name: http
  addr: :80
  handler:
    type: tcp
    metadata:
      sniffing: true
  listener:
    type: tcp
  forwarder:
    nodes:
    - name: example-com
      addr: example.com:80
      host: example.com
    - name: example-org
      addr: example.org:80
      host: example.org
```

Use the `sniffing` option to enable traffic sniffing, and pass the `host` option in `forwarder.nodes` to set the (virtual) hostname for each node.

When traffic sniffing is enabled, the forwarding service will obtain the target host through the client’s request data, and then find the final forwarding target address (node.addr) via `node.host`.

`node.host` also supports wildcards, *.example.com or .example.com matches example.com and its subdomains: abc.example.com, def.abc.example.com, etc.

At this time, the corresponding domain name can be resolved to the local and then accessed through the reverse proxy:

```bash
curl --resolve www.google.com:443:127.0.0.1 https://www.google.com
```

```bash
curl --resolve example.com:80:127.0.0.1 http://example.com
```

## Remote Port Forwarding

Remote port forwarding services can also sniff traffic.

![Reverse Proxy - Remote TCP Port Forwarding](/images/reverse-proxy-rtcp.png) 

```yaml hl_lines="7 15 18"
services:
- name: https
  addr: :443
  handler:
    type: rtcp
    metadata:
      sniffing: true
  listener:
    type: rtcp
    chain: chain-0
  forwarder:
    nodes:
    - name: local-0
      addr: 192.168.1.1:443
      host: srv-0.local
    - name: local-1
      addr: 192.168.1.2:443
      host: srv-1.local
	- name: fallback
	  addr: 192.168.2.1:443
- name: http
  addr: :80
  handler:
    type: rtcp
    metadata:
      sniffing: true
  listener:
    type: rtcp
    chain: chain-0
  forwarder:
    nodes:
    - name: local-0
      addr: 192.168.1.1:80
      host: srv-0.local
    - name: local-1
      addr: 192.168.1.2:80
      host: srv-1.local
chains:
- name: chain-0
  hops:
  - name: hop-0
    nodes:
    - name: node-0
      addr: SERVER_IP:8443 
      connector:
        type: relay
      dialer:
        type: wss
```

Use the `sniffing` option to enable traffic sniffing, and pass the `host` option in `forwarder.nodes` to set the (virtual) hostname for each node.

At this time, the corresponding domain name can be resolved to the server address to access the internal service through the reverse proxy:

```bash
curl --resolve srv-0.local:443:SERVER_IP https://srv-0.local
```

```bash
curl --resolve srv-1.local:80:SERVER_IP http://srv-1.local
```

If the accessed target host does not match the hostname set by the node in the forwarder, when there are nodes without a hostname set, one of these nodes will be selected for use.

```bash
curl --resolve srv-2.local:443:SERVER_IP https://srv-2.local
```

Since srv-2.local does not match the node, it will be forwarded to the fallback node (192.168.2.443).

## Application-Specific Forwarding

Local and remote port forwarding services also support sniffing of specific application traffic. Currently supported application protocols are: SSH.

### SSH

In forwarder.nodes, specify the node protocol type as `ssh` through the `protocol` option, and when the SSH protocol traffic is sniffed, it will be forwarded to this node.

=== "Local Port Forwarding"

    ```yaml hl_lines="14"
    services:
    - name: https
      addr: :443
      handler:
        type: tcp
        metadata:
          sniffing: true
      listener:
        type: tcp
      forwarder:
        nodes:
        - name: ssh-server
          addr: example.com:22
          protocol: ssh
    ```

=== "Remote Port Forwarding"

    ```yaml hl_lines="15"
    services:
    - name: https
      addr: :443
      handler:
        type: rtcp
        metadata:
          sniffing: true
      listener:
        type: rtcp
        chain: chain-0
      forwarder:
        nodes:
        - name: local-ssh
          addr: 192.168.2.1:22
          protocol: ssh
    chains:
    - name: chain-0
      hops:
      - name: hop-0
        nodes:
        - name: node-0
          addr: SERVER_IP:8443 
          connector:
            type: relay
          dialer:
            type: wss
    ```

!!! note "Priority"
    When the `host` and `protocol` options are set at the same time, only `host` will be matched.

## Forwarding Tunnel

In addition to the original TCP data tunnel can be used as port forwarding, other tunnels can also be used as port forwarding services.

### TLS

HTTPS-to-HTTP

The TLS forwarding tunnel can dynamically add TLS support to the backend HTTP service.

```yaml
services:
- name: https
  addr: :443
  handler:
    type: forward
    metadata:
      sniffing: true
  listener:
    type: tls
  forwarder:
    nodes:
    - name: example-com
      addr: example.com:80
      host: .example.com
    - name: example-org
      addr: example.org:80
      host: .example.org
```

```bash
curl -k --resolve example.com:443:127.0.0.1 https://example.com
```

### HTTP3

HTTP3-to-HTTP.

The HTTP3 forwarding tunnel can dynamically add HTTP/3 support to the backend HTTP service.

```yaml
services:
- name: http3
  addr: :443
  handler:
    type: http3
  listener:
    type: http3
  forwarder:
    nodes:
    - name: example-com
      addr: example.com:80
      host: .example.com
    - name: example-org
      addr: example.org:80
      host: .example.org
```

```bash
curl -k --http3 --resolve example.com:443:127.0.0.1 https://example.com
```