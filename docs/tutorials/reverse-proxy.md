---
comments: true
---

# 反向代理

[反向代理](https://zh.wikipedia.org/wiki/%E5%8F%8D%E5%90%91%E4%BB%A3%E7%90%86)是代理服务的一种。服务器根据客户端的请求，从其关系的一组或多组后端服务器（如Web服务器）上获取资源，然后再将这些资源返回给客户端，客户端只会得知反向代理的IP地址，而不知道在代理服务器后面的服务器集群的存在。

GOST中的[端口转发](/tutorials/port-forwarding/)服务也可以被当作是一种功能受限的反向代理，因其只能转发到固定的一个或一组后端服务。

反向代理是端口转发服务的一个扩展，其依托于端口转发功能，并通过嗅探转发的数据来获取特定协议(目前支持HTTP/HTTPS)中的目标主机信息。

关于反向代理更详细的说明可以参考这篇[博文](https://gost.run/blog/2023/reverse-proxy/)。

## 本地端口转发

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

通过`sniffing`选项来开启流量嗅探，并在`forwarder.nodes`中通过`host`选项可以对每一个节点设置(虚拟)主机名。

当开启流量嗅探后，转发服务会通过客户端的请求数据获取访问的目标主机，再通过转发器(forwarder)中的节点设置的虚拟主机名(node.host)找到最终转发的目标地址(node.addr)。

![Reverse Proxy - TCP Port Forwarding](/images/reverse-proxy-tcp.png) 

`node.host`也支持通配符，*.example.com或.example.com匹配example.com及其子域名：abc.example.com，def.abc.example.com等。

此时可以将对应的域名解析到本地通过反向代理来访问：

```bash
curl --resolve www.google.com:443:127.0.0.1 https://www.google.com
```

```bash
curl --resolve example.com:80:127.0.0.1 http://example.com
```

## 远程端口转发

远程端口转发服务同样也可以对流量进行嗅探。

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

通过`sniffing`选项来开启流量嗅探，并在`forwarder.nodes`中通过`host`选项可以对每一个节点设置(虚拟)主机名。

![Reverse Proxy - Remote TCP Port Forwarding](/images/reverse-proxy-rtcp.png) 

此时可以将对应的域名解析到服务器地址通过反向代理来访问内网服务：

```bash
curl --resolve srv-0.local:443:SERVER_IP https://srv-0.local
```

```bash
curl --resolve srv-1.local:80:SERVER_IP http://srv-1.local
```

如果访问的目标主机没有与转发器中的节点设定的主机名匹配上，当存在没有设置主机名的节点，则会在这些节点中选择一个使用。

```bash
curl --resolve srv-2.local:443:SERVER_IP https://srv-2.local
```

由于srv-2.local没有匹配到节点，因此会被转发到fallback节点(192.168.2.1:443)。

## URL路径路由

通过`path`选项为节点指定路径前缀。当嗅探到HTTP流量后，会使用URL路径通过最长前缀匹配模式来选择节点。

```yaml hl_lines="14 17"
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
      path: /
    - name: target-1
      addr: 192.168.1.2:80
      path: /test
```

## HTTP请求头设置

当嗅探到HTTP流量时，可以在目标节点上通过`forwarder.nodes.http`选项对HTTP的请求头部信息进行设置，包括Host头重写和自定义头部信息，对本地和远程端口转发均适用。

### 重写Host头

通过设置`http.host`选项可以重写原始请求头中的Host。

```yaml hl_lines="15 16"
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
      host: example.com
      http:
        host: test.example.com
    - name: example-org
      addr: example.org:80
      host: example.org
      http:
        host: test.example.org:80
```

```bash
curl --resolve example.com:80:127.0.0.1 http://example.com
```

当请求http://example.com时，最终发送给example.com:80的HTTP请求头中Host为test.example.com。

### 自定义头

通过设置`http.header`选项可以自定义头部信息，如果所设置的头部字段已存在则会被覆盖。

```yaml hl_lines="15 16 17 18 19"
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
      host: example.com
      http:
        header:
          User-Agent: gost/3.0.0
          foo: bar
          bar: 123
        # host: test.example.com
    - name: example-org
      addr: example.org:80
      host: example.org
      http:
        header:
          User-Agent: curl/7.81.0
          foo: bar
          bar: baz
        # host: test.example.org:80
```

当请求http://example.com时，最终发送给example.com:80的HTTP请求头中将会添加`User-Agent`，`Foo`和`Bar`三个字段。

## TLS请求设置

如果转发的目标节点启用了TLS，可以通过设置`forwarder.nodes.tls`来建立TLS连接。

```yaml hl_lines="15 16 17"
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
:    是否开启服务器证书和域名校验。

`tls.serverName` (string)
:    若`secure`设置为true，则需要通过此参数指定服务器域名用于域名校验。

`tls.options.minVersion` (string)
:    TLS最小版本，可选值`VersionTLS10`，`VersionTLS11`，`VersionTLS12`，`VersionTLS13`。

`tls.options.maxVersion` (string)
:    TLS最大版本，可选值`VersionTLS10`，`VersionTLS11`，`VersionTLS12`，`VersionTLS13`。

`tls.options.cipherSuites` (list)
:    加密套件，可选值参考[Cipher Suites](https://pkg.go.dev/crypto/tls#pkg-constants)。

## HTTP Basic Authentication

可以通过设置`forwarder.nodes.auth`选项为目标节点启用[HTTP基本认证](https://zh.wikipedia.org/zh-cn/HTTP%E5%9F%BA%E6%9C%AC%E8%AE%A4%E8%AF%81)功能。

```yaml hl_lines="15 16 17"
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
      host: example.com
      auth:
        username: user
        password: pass
```

## 特定应用转发

本地和远程端口转发服务也支持对特定的应用流量嗅探。目前支持的应用协议有：

* `http` - HTTP流量数据。
* `tls` - TLS流量数据。
* `ssh` - SSH数据。

在forwarder.nodes中通过`protocol`选项指定节点协议类型，当嗅探到对应类型流量则会转发到此节点。

=== "本地端口转发"

    ```yaml hl_lines="15 19 22"
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
          host: example.com
          addr: example.com:80
          protocol: http
        - name: https-server
          host: example.com
          addr: example.com:443
          protocol: tls
        - name: ssh-server
          addr: example.com:22
          protocol: ssh
    ```

=== "远程端口转发"

    ```yaml hl_lines="15 18 21"
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
          protocol: http
        - name: local-https
          addr: 192.168.2.1:443
          protocol: tls
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

## 转发通道

除了原始TCP数据通道可以用来作为端口转发，其他数据通道也可以作为端口转发服务。

### TLS转发通道

HTTPS-to-HTTP反向代理。

TLS转发通道可以动态的给后端HTTP服务添加TLS支持。

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

### HTTP3转发通道

HTTP3-to-HTTP反向代理。

HTTP3转发通道可以动态的给后端HTTP服务添加HTTP/3支持。

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
