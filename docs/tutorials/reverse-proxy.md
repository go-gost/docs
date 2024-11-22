---
comments: true
---

# 反向代理

[反向代理](https://zh.wikipedia.org/wiki/%E5%8F%8D%E5%90%91%E4%BB%A3%E7%90%86)是代理服务的一种。服务器根据客户端的请求，从其关系的一组或多组后端服务器（如Web服务器）上获取资源，然后再将这些资源返回给客户端，客户端只会得知反向代理的IP地址，而不知道在代理服务器后面的服务器集群的存在。

GOST中的[端口转发](port-forwarding.md)服务也可以被当作是一种功能受限的反向代理，因其只能转发到固定的一个或一组后端服务。

反向代理是端口转发服务的一个扩展，其依托于端口转发功能，并通过嗅探转发的请求数据来获取特定协议(目前支持HTTP/HTTPS)中的目标主机信息。

关于反向代理更详细的说明可以参考这篇[博文](https://gost.run/blog/2023/reverse-proxy/)。

## 本地端口转发

```yaml
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
      # filter:
      #   host: www.google.com
      matcher:
        rule: Host(`www.google.com`)
    - name: github
      addr: github.com:443
      # filter:
      #   host: *.github.com
      matcher:
        rule: Host(`*.github.com`)
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
      # filter:
      #   host: example.com
      matcher:
        rule: Host(`example.com`)
    - name: example-org
      addr: example.org:80
      # filter:
      #   host: example.org
      #   path: /
      matcher:
        rule: Host(`example.org`) && PathPrefix(`/`)
```

通过`sniffing`选项来开启流量嗅探，并在`forwarder.nodes`中通过`filter`或`matcher.rule`选项对节点设置路由条件或规则。

当开启流量嗅探后，转发服务会对客户端的请求信息应用转发器(forwarder)中节点设置的匹配条件(filter)或匹配规则(matcher.rule)过滤出最终转发的目标节点。

![Reverse Proxy - TCP Port Forwarding](../images/reverse-proxy-tcp.png) 

此时可以将对应的域名解析到本地通过反向代理来访问：

```bash
curl --resolve www.google.com:443:127.0.0.1 https://www.google.com
```

```bash
curl --resolve example.com:80:127.0.0.1 http://example.com
```

## 远程端口转发

远程端口转发服务同样也可以对流量进行嗅探。

```yaml
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
      # filter:
      #   host: srv-0.local
      matcher:
        rule: Host(`srv-0.local`)
    - name: local-1
      addr: 192.168.1.2:443
      # filter:
      #   host: srv-1.local
      matcher:
        rule: Host(`srv-1.local`)
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
      # filter:
      #   host: srv-0.local
      matcher:
        rule: Host(`srv-0.local`)
    - name: local-1
      addr: 192.168.1.2:80
      # filter:
      #   host: srv-1.local
      matcher:
        rule: Host(`srv-1.local`)
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

![Reverse Proxy - Remote TCP Port Forwarding](../images/reverse-proxy-rtcp.png) 

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

## 请求路由

反向代理中请求到目标节点的路由有两种模式：条件过滤和规则匹配。两种模式二选一，规则匹配优先。

### 条件过滤

在节点上通过`filter`选项来设置过滤条件，当请求满足此过滤条件时此节点为合格结点，将参与下一步的目标节点选择。

#### 主机名过滤

通过`filter.host`选项为节点设置主机名过滤。

`filter.host`也支持通配符，`*.example.com`或`.example.com`匹配example.com及其子域名abc.example.com，def.abc.example.com等。

```yaml  hl_lines="15 19"
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
    - name: example-org
      addr: example.org:80
      filter:
        host: *.example.org
```

#### 应用协议过滤

通过`filter.protocol`选项设置协议类型过滤，当嗅探到对应类型流量则会转发到此节点。

目前支持的应用协议有：

* `http` - HTTP流量数据。
* `tls` - TLS流量数据。
* `ssh` - SSH流量数据。

```yaml hl_lines="16 21 25"
services:
- name: service-0
  addr: :8000
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

#### URL路径过滤

通过`filter.path`选项为节点设置路径前缀过滤。当嗅探到HTTP流量后，会使用URL路径前缀匹配模式来选择节点。

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

### 规则匹配

除了简单的条件过滤外，请求路由同时也集成了Traefik中更加灵活的[规则路由](https://doc.traefik.io/traefik/routing/routers/)功能。

通过`matcher.rule`选项设置节点的匹配规则，当设置了规则后，`filter`将会被忽略。

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
      matcher:
        rule: Host(`www.example.com`) || Host(`www.example.org`)
    - name: target-1
      addr: 192.168.1.2:80
      matcher:
        rule: Host(`*.example.com`)
```

#### 规则

目前支持的匹配规则列表

| 规则                                    | 说明                                                                 | 示例                                                |
| ----------------------------------------| ---------------------------------------------------------------------| --------------------------------------------------- |
| ```Host(`domain`)```                    | HTTP请求的主机名或TLS请求的SNI匹配`domain`，等效于`filter.host`。       | ```Host(`example.com`)```，```Host(`*.example.org`)```      |
| ```HostRegexp(`regexp`)```              | HTTP请求的主机名或TLS请求的SNI匹配正则表达式`regexp`。                  | ```HostRegexp(`^.+\.example\.com$`)```                  |
| ```Method(`method`)```                  | HTTP请求的方法匹配`method`。                                          | ```Method(`POST`)```                                          |
| ```Path(`path`)```                      | HTTP请求的URI路径匹配`path`。                                          | ```Path(`/products/1234`)```                                        |
| ```PathPrefix(`prefix`)```              | HTTP请求的URI路径匹配前缀`prefix`，等效于`filter.path`。               | ```PathPrefix(`/products`)```                                   |
| ```PathRegexp(`regexp`)```              | HTTP请求的URI路径匹配正则表达式`regexp`。                              | ```PathRegexp(`\.(jpeg|jpg|png)$`)```                               |
| ```Query(`key`)```                      | HTTP请求的Query参数名包含`key`。                                       | ```Query(`foo`)```                |
| ```Query(`key`, `value`)```             | HTTP请求的Query参数名包含`key`,对应的参数值匹配`value`。                 | ```Query(`foo`, `bar`)```                |
| ```QueryRegexp(`key`, `regexp`)```      | HTTP请求的Query参数名包含`key`,对应的参数值匹配正则表达式`regexp`。       | ```QueryRegexp(`foo`, `^.*$`)```      |
| ```Header(`key`)```                     | HTTP请求的Header中包含`key`。                                          | ```Header(`Content-Type`)```                         |
| ```Header(`key`, `value`)```            | HTTP请求的Header中包含`key`,对应的值匹配`value`。                        | ```Header(`Content-Type`, `application/json`)```                         |
| ```HeaderRegexp(`key`, `regexp`)```     | HTTP请求的Header中包含`key`,对应的值匹配正则表达式`regexp`。              | ```HeaderRegexp(`Content-Type`, `^application/(json|yaml)$`)```             |
| ```ClientIP(`ip`)```                    | 请求的客户端IP匹配`ip`，`ip`格式为IPv4，IPv6或CIDR。                     | ```ClientIP(`192.168.0.1`)```，```ClientIP(`::1`)```，```ClientIP(`192.168.1.0/24`)```，```ClientIP(`fe80::/10`)```                     |
| ```Proto(`proto`)```                    | 匹配协议类型，等效于`filter.protocol`。                                  | ```Proto(`http`)```                                 |

!!! important "正则表达式"

    接受正则表达式作为其值的匹配器使用[Go](https://golang.org/pkg/regexp/)风格的语法。

!!! info "使用运算符和括号表达复杂规则"

    可以使用常见的 AND (`&&`) 和 OR (`||`) 逻辑运算符，以及预期的优先规则和括号。

    可以使用 NOT (`!`) 运算符反转匹配器。

    ```yaml
    Host(`example.com`) || (Host(`example.org`) && !Path(`/path`))
    ```

    上面的规则匹配：

    - 主机名是`example.com` 或，
    - 主机名是`example.org` 且 路径不是 `/path`。

#### 优先级

为了避免路径重叠，默认情况下，路由按规则长度降序排序。优先级直接等于规则的长度，因此最长的长度具有最高优先级。

通过`matcher.priority`选项可以设置节点的权重，从而改变节点选择的优先级。

```yaml hl_lines="16 21"
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
      matcher:
        rule: Host(`www.example.com`)
        priority: 100
    - name: target-1
      addr: 192.168.1.2:80
      matcher:
        rule: Host(`*.example.com`)
        priority: 50
```

当请求的Host为`www.example.com`时，会优先选择`target-0`节点。

## HTTP请求设置

当嗅探到HTTP流量时，可以在目标节点上通过`forwarder.nodes.http`选项对HTTP的请求信息进行设置，包括Host头重写，自定义头部信息，开启Basic Auth，URL路径重写。对本地和远程端口转发均适用。

### 重写Host头

通过设置`http.host`选项可以重写原始请求头中的Host。

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
      # filter:
      #   host: example.com
      matcher:
        rule: Host(`example.com`)
      http:
        host: test.example.com
    - name: example-org
      addr: example.org:80
      # filter:
      #   host: example.org
      matcher:
        rule: Host(`example.org`)
      http:
        host: test.example.org:80
```

```bash
curl --resolve example.com:80:127.0.0.1 http://example.com
```

当请求http://example.com时，最终发送给example.com:80的HTTP请求头中Host为test.example.com。

### 自定义请求头

通过设置`http.requestHeader`选项可以自定义请求头部信息，如果所设置的头部字段已存在则会被覆盖。

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
      # filter:
      #   host: example.com
      matcher:
        rule: Host(`example.com`)
      http:
        requestHeader:
          User-Agent: gost/3.0.0
          foo: bar
          bar: 123
        # host: test.example.com
    - name: example-org
      addr: example.org:80
      # filter:
      #   host: example.org
      matcher:
        rule: Host(`example.org`)
      http:
        requestHeader:
          User-Agent: curl/7.81.0
          foo: bar
          bar: baz
        # host: test.example.org:80
```

当请求http://example.com时，最终发送给example.com:80的HTTP请求头中将会添加`User-Agent`，`Foo`和`Bar`三个字段。

### 自定义响应头

通过设置`http.responseHeader`选项可以自定义响应头部信息，如果所设置的头部字段已存在则会被覆盖。

```yaml hl_lines="17-19"
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
      # filter:
      #   host: example.com
      matcher:
        rule: Host(`example.com`)
      http:
        responseHeader:
          foo: bar
          bar: 123
```

当请求http://example.com时，最终来自example.com:80的HTTP响应头中将会添加`Foo`和`Bar`两个字段。

### Basic Authentication

通过设置`http.auth`选项为目标节点启用[HTTP基本认证](https://zh.wikipedia.org/zh-cn/HTTP%E5%9F%BA%E6%9C%AC%E8%AE%A4%E8%AF%81)功能。

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
      # filter:
      #   host: example.com
      matcher:
        rule: Host(`example.com`)
      http:
        auth:
          username: user
          password: pass
```

当直接请求http://example.com时，会返回HTTP状态码401要求认证。

### URL路径重写

通过设置`http.rewriteURL`选项定义URL路径重写规则。

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
      # filter:
      #   host: example.com
      matcher:
        rule: Host(`example.com`)
      http:
        rewriteURL:
        - match: /api/login
          replacement: /user/login
        - match: /api/(.*)
          replacement: /$1
```

`rewriteURL.match` (string)
:    指定路径匹配模式(支持正则表达式)。

`rewriteURL.replacement` (string)
:    设置路径替换内容。

`http://example.com/api/login`会被重写为`http://example.com/user/login`。

`http://example.com/api/logout`会被重写为`http://example.com/logout`。

### 重写响应体

通过设置`http.rewriteBody`选项定义响应体重写规则。

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
      # filter:
      #   host: example.com
      matcher:
        rule: Host(`example.com`)
      http:
        rewriteBody:
        - match: foo
          replacement: bar
          type: text/html
```

`rewriteBody.match` (string)
:    指定内容匹配模式(支持正则表达式)。

`rewriteBody.replacement` (string)
:    设置替换内容。

`rewriteBody.type` (string, default=text/html)
:    设置响应的内容类型，与`Content-Type`匹配。可以是`,`分割的多个类型或`*`代表匹配所有类型。

## TLS请求设置

如果转发的目标节点启用了TLS，可以通过设置`forwarder.nodes.tls`来建立TLS连接。

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
      # filter:
      #   host: example.com
      matcher:
        rule: Host(`example.com`)
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
      # filter:
      #   host: .example.com
      matcher:
        rule: Host(`.example.com`)
    - name: example-org
      addr: example.org:80
      # filter:
      #   host: .example.org
      matcher:
        rule: Host(`.example.org`)
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
      # filter:
      #   host: .example.com
      matcher:
        rule: Host(`.example.com`)
    - name: example-org
      addr: example.org:80
      # filter:
      #   host: .example.org
      matcher:
        rule: Host(`.example.org`)
```

```bash
curl -k --http3 --resolve example.com:443:127.0.0.1 https://example.com
```
