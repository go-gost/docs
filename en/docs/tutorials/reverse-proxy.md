---
comments: true
---

# Reverse Proxy

[Reverse Proxy](https://en.wikipedia.org/wiki/Reverse_proxy) is a type of proxy service. According to the client's request, the server obtains resources from one or more groups of backend servers (such as web servers) related to it, and then returns these resources to the client. The client only knows the IP address of the reverse proxy, without knowing the existence of server clusters behind proxy servers.

The port forwarding service in GOST can also be regarded as a reverse proxy with limited functions, because it can only forward to a fixed one or a set of backend services.

Reverse proxy is an extension of the port forwarding service, which relies on the port forwarding function, and obtains the target host information in a specific protocol (currently supports HTTP/HTTPS) by sniffing the forwarded data.

## Local Port Forwarding

```yaml hl_lines="7 15 19"
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
      filter:
        host: www.google.com
    - name: github
      addr: github.com:443
      filter:
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
      filter:
        host: example.com
    - name: example-org
      addr: example.org:80
      filter:
        host: example.org
```

Use the `sniffing` option to enable traffic sniffing, and pass the `filter.host` option in `forwarder.nodes` to set the (virtual) hostname for each node.

When traffic sniffing is enabled, the forwarding service will obtain the target host through the client’s request data, and then find the final forwarding target address (addr) via `filter.host`.

![Reverse Proxy - TCP Port Forwarding](/images/reverse-proxy-tcp.png) 

`filter.host` also supports wildcards, *.example.com or .example.com matches example.com and its subdomains: abc.example.com, def.abc.example.com, etc.

At this time, the corresponding domain name can be resolved to the local and then accessed through the reverse proxy:

```bash
curl --resolve www.google.com:443:127.0.0.1 https://www.google.com
```

```bash
curl --resolve example.com:80:127.0.0.1 http://example.com
```

## Remote Port Forwarding

Remote port forwarding services can also sniff traffic.

```yaml hl_lines="7 16 20"
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
      filter:
        host: srv-0.local
    - name: local-1
      addr: 192.168.1.2:443
      filter:
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
      filter:
        host: srv-0.local
    - name: local-1
      addr: 192.168.1.2:80
      filter:
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

Use the `sniffing` option to enable traffic sniffing, and pass the `filter.host` option in `forwarder.nodes` to set the (virtual) hostname for each node.

![Reverse Proxy - Remote TCP Port Forwarding](/images/reverse-proxy-rtcp.png) 

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

Since srv-2.local does not match the node, it will be forwarded to the fallback node (192.168.2.1:443).

## URL Path Routing

Specify the path prefix for the node via the `filter.path` option. When HTTP traffic is sniffed, the URL path is used to select nodes using the longest prefix matching pattern.

```yaml hl_lines="15 19"
services:
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
    - name: target-0
      addr: 192.168.1.1:80
      filter:
        path: /
    - name: target-1
      addr: 192.168.1.2:80
      filter:
        path: /test
```

## HTTP Request Settings

When sniffing HTTP traffic, you can set the HTTP request information on the target node through the `forwarder.nodes.http` option, including Host header rewriting, custom header information, basic auth, URL path rewriting.

### Rewrite Host Header

The Host in the original request header can be overridden by setting the `http.host` option.

```yaml hl_lines="16 17"
services:
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
      filter:
        host: example.com
      http:
        host: test.example.com
    - name: example-org
      addr: example.org:80
      filter:
        host: example.org
      http:
        host: test.example.org:80
```

```bash
curl --resolve example.com:80:127.0.0.1 http://example.com
```

When requesting http://example.com, the Host in the HTTP request header sent to example.com:80 is test.example.com.

### Custom Header

The header information can be customized by setting the `http.header` option, if the header field already exists, it will be overwritten.

```yaml hl_lines="16-20"
services:
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
      filter:
        host: example.com
      http:
        header:
          User-Agent: gost/3.0.0
          foo: bar
          bar: 123
        # host: test.example.com
    - name: example-org
      addr: example.org:80
      filter:
        host: example.org
      http:
        header:
          User-Agent: curl/7.81.0
          foo: bar
          bar: baz
        # host: test.example.org:80
```

When requesting http://example.com, three fields `User-Agent`, `Foo` and `Bar` will be added to the HTTP request header sent to example.com:80.

### HTTP Basic Authentication

You can enable [HTTP Basic Authentication](https://en.wikipedia.org/wiki/Basic_access_authentication) for target node by setting the `http.auth` option.

```yaml hl_lines="16-19"
services:
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
      filter:
        host: example.com
      http:
        auth:
          username: user
          password: pass
```

When requesting http://example.com directly, HTTP status code 401 will be returned to require authentication.

### Rewrite URL Path

Define URL path rewriting rules by setting the `http.rewrite` option. 

```yaml hl_lines="16-21"
services:
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
      filter:
        host: example.com
      http:
        rewrite:
        - match: /api/login
          replacement: /user/login
        - match: /api/(.*)
          replacement: /$1
```

`rewrite.match` (string)
:    specify path matching pattern (supports regular expression).

`rewrite.replacement` (string)
:    set the path replacement content.

`http://example.com/api/login` will be rewritten to `http://example.com/user/login`.

`http://example.com/api/logout` will be rewritten to `http://example.com/logout`.

### Rewrite Response Body

Define the response body rewriting rules by setting the `http.rewriteBody` option.

```yaml hl_lines="16-20"
services:
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
      filter:
        host: example.com
      http:
        rewriteBody:
        - match: foo
          replacement: bar
          type: text/html
```

`rewriteBody.match` (string)
:    Specify content matching pattern (regular expressions are supported).

`rewrite.replacement` (string)
:    Set the replacement content.

`rewriteBody.type` (string, default=text/html)
:    Set the content type of the response, matching the `Content-Type` header. It can be multiple types separated by `,` or `*` to match all types.

## TLS Settings

If the forwarding target node has TLS enabled, you can establish a TLS connection by setting `forwarder.nodes.tls`.

```yaml hl_lines="16-23"
services:
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
      addr: example.com:443
      filter:
        host: example.com
      tls:
        secure: true
        serverName: example.com
        options:
          minVersion: VersionTLS12
          maxVersion: VersionTLS13
          cipherSuites:
          - TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256
```

`tls.secure` (bool, default=false)
:    Whether to enable server certificate and domain name verification.

`tls.serverName` (string)
:    If `secure` is set to true, you need to specify the server domain name for domain name verification through this parameter.

`tls.options.minVersion` (string)
:    Minimum TLS Version, `VersionTLS10`, `VersionTLS11`, `VersionTLS12` or `VersionTLS13`.

`tls.options.maxVersion` (string)
:    Maximum TLS Version, `VersionTLS10`, `VersionTLS11`, `VersionTLS12` or `VersionTLS13`.

`tls.options.cipherSuites` (list)
:    Cipher Suites, See [Cipher Suites](https://pkg.go.dev/crypto/tls#pkg-constants) for more information.

## Application-Specific Forwarding

Local and remote port forwarding services also support sniffing of specific application traffic. Currently supported application protocols are: 

* `http` - HTTP traffic.
* `tls` - TLS traffic.
* `ssh` - SSH traffic.

In forwarder.nodes, specify the node protocol type through the `filter.protocol` option, and when the corresponding traffic is detected, it will be forwarded to this node.

=== "Local Port Forwarding"

    ```yaml hl_lines="16 21 25"
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
        - name: http-server
          addr: example.com:80
          filter:
            host: example.com
            protocol: http
        - name: https-server
          addr: example.com:443
          filter:
            host: example.com
            protocol: tls
        - name: ssh-server
          addr: example.com:22
          filter:
            protocol: ssh
    ```

=== "Remote Port Forwarding"

    ```yaml hl_lines="16 20 24"
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
        - name: local-http
          addr: 192.168.2.1:80
          filter:
            protocol: http
        - name: local-https
          addr: 192.168.2.1:443
          filter:
            protocol: tls
        - name: local-ssh
          addr: 192.168.2.1:22
          filter:
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
      filter:
        host: .example.com
    - name: example-org
      addr: example.org:80
      filter:
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
      filter:
        host: .example.com
    - name: example-org
      addr: example.org:80
      filter:
        host: .example.org
```

```bash
curl -k --http3 --resolve example.com:443:127.0.0.1 https://example.com
```