---
comments: true
---

# 域名解析

通过在服务或转发链中设置域名解析器，可以更改域名解析行为。

!!! tip "动态配置"
    解析器支持通过[Web API](../tutorials/api/overview.md)进行动态配置。

## 域名解析器

域名解析器通过设置上级域名服务列表对指定的域名进行解析，域名解析器可以应用于服务或转发链中。服务中的域名解析器对请求的目标地址进行解析，转发链中的域名解析器对转发链中的节点地址进行解析。

## 服务上的解析器

当服务中的处理器在与目标主机建立连接之前，会使用域名解析器对请求目标地址进行解析。

=== "命令行"

	```bash
	gost -L http://:8080?resolver=1.1.1.1,tcp://8.8.8.8,tls://8.8.8.8:853,https://1.0.0.1/dns-query
	```

	通过`resolver`参数来指定上级域名解析服务列表。

=== "配置文件"

    ```yaml hl_lines="4 10"
    services:
    - name: service-0
      addr: ":8080"
      resolver: resolver-0
      handler:
        type: http
      listener:
        type: tcp
	resolvers:
	- name: resolver-0
	  nameservers:
	  - addr: 1.1.1.1
	  - addr: tcp://8.8.8.8
	  - addr: tls://8.8.8.8:853
	  - addr: https://1.0.0.1/dns-query
	```

	服务中使用`resolver`属性通过引用解析器名称(name)来使用指定的解析器。

每个DNS服务的格式为：

`[protocol://]ip[:port]`

* `protocol`支持的类型有`udp`，`tcp`，`tls`，`https`，默认值为`udp`。

* `port`默认值为53。

!!! example

	* udp://1.1.1.1:53，或udp://1.1.1.1
	* tcp://1.1.1.1:53
	* tls://1.1.1.1:853
	* https://1.0.0.1/dns-query

## 转发链上的解析器

转发链中可以在跳跃点上或节点上设置解析器，当节点上未设置解析器，则使用跳跃点上的解析器。

=== "命令行"

	```bash
	gost -L http://:8000 -F http://example.com:8080?resolver=1.1.1.1,tcp://8.8.8.8,tls://8.8.8.8:853,https://1.0.0.1/dns-query
	```

	通过`resolver`参数来指定上级域名解析服务列表。`resolver`参数对应配置文件中hop级别的解析器。

=== "配置文件"

    ```yaml hl_lines="14 19"
    services:
    - name: service-0
      addr: ":8000"
      handler:
        type: http
		chain: chain-0
      listener:
        type: tcp
	chains:
    - name: chain-0
      hops:
      - name: hop-0
	    # hop level resolver
        resolver: resolver-0
        nodes:
		- name: node-0
		  addr: example.com:8080
	      # node level resolver
          # resolver: resolver-0
		  connector:
			type: http
		  dialer:
			type: tcp
	resolvers:
	- name: resolver-0
	  nameservers:
	  - addr: 1.1.1.1
	  - addr: tcp://8.8.8.8
	  - addr: tls://8.8.8.8:853
	  - addr: https://1.0.0.1/dns-query
	```

	转发链的hop或node中使用`resolver`属性通过引用解析器名称(name)来使用指定的解析器。

## 使用转发链

域名解析器中的每个上级域名服务可以分别设置转发链。

```yaml hl_lines="45 47 49"
services:
- name: service-0
  addr: ":8080"
  resolver: resolver-0
  handler:
	type: http
  listener:
	type: tcp
chains:
- name: chain-0
  hops:
  - name: hop-0
	nodes:
	- name: node-0
	  addr: 192.168.1.1:8081
	  connector:
		type: http
	  dialer:
		type: tcp
- name: chain-1
  hops:
  - name: hop-0
	nodes:
	- name: node-0
	  addr: 192.168.1.2:8082
	  connector:
		type: socks5
	  dialer:
		type: tcp
- name: chain-2
  hops:
  - name: hop-0
	nodes:
	- name: node-0
	  addr: 192.168.1.3:8083
	  connector:
		type: relay
	  dialer:
		type: tls
resolvers:
- name: resolver-0
  nameservers:
  - addr: 1.1.1.1
  - addr: tcp://8.8.8.8:53
	chain: chain-0
  - addr: tls://8.8.8.8:853
	chain: chain-1
  - addr: https://1.0.0.1/dns-query
	chain: chain-2
```

## 缓存

每个解析器内部有一个缓存，通过`ttl`参数可以设置缓存时长，默认使用DNS查询返回结果中的TTL，当设置为负值，则不使用缓存。

```yaml hl_lines="5"
resolvers:
- name: resolver-0
  nameservers:
  - addr: 1.1.1.1
    ttl: 30s
```

## IPv6优先

解析器默认返回IPv4地址，可以通过`prefer`选项设置切换到IPv6地址优先。

```yaml hl_lines="5"
resolvers:
- name: resolver-0
  nameservers:
  - addr: 1.1.1.1
    prefer: ipv6 # default is ipv4
```

## IPv4/IPv6 Only

可以通过`only`选项设置仅使用IPv4或IPv6地址，当设置了`only`选项后，`prefer`选项将被忽略。

```yaml hl_lines="5"
resolvers:
- name: resolver-0
  nameservers:
  - addr: 1.1.1.1
    only: ipv6 # or ipv4
```

## 异步查询

通过`async`选项设置对DNS服务的查询请求为异步，此时当缓存失效后仍旧返回缓存中的结果，同时再向DNS服务异步发送查询请求并更新缓存。当缓存被禁用时，此功能无效。

```yaml hl_lines="5"
resolvers:
- name: resolver-0
  nameservers:
  - addr: 1.1.1.1
    async: true
```

## ECS

通过`clientIP`参数设置客户端IP，开启ECS(EDNS Client Subnet)扩展功能。

```yaml hl_lines="5"
resolvers:
- name: resolver-0
  nameservers:
  - addr: 1.1.1.1
    clientIP: 1.2.3.4
```

## 插件

域名解析器可以配置为使用外部[插件](plugin.md)服务，解析器会将解析请求转发给插件服务处理。当使用插件时其他参数无效。

```yaml
resolvers:
- name: resolver-0
  plugin:
    type: grpc
    addr: 127.0.0.1:8000
    tls: 
      secure: false
      serverName: example.com
```

`type` (string, default=grpc)
:    插件类型：`grpc`, `http`。

`addr` (string, required)
:    插件服务地址。

`tls` (object, default=null)
:    设置后将使用TLS加密传输，默认不使用TLS加密。

### HTTP插件

```yaml
resolvers:
- name: resolver-0
  plugin:
    type: http
    addr: http://127.0.0.1:8000/resolver
```

#### 请求示例

```bash
curl -XPOST http://127.0.0.1:8000/resolver -d '{"network": "ip4", "host":"example.com", "client": "gost"}'
```

```json
{"ips": ["1.2.3.4","2.3.4.5"], "ok": true}
```

`network` (string, default=ip4)
:    网络地址类型：`ip4` - 解析为IPv4地址。`ip6` - 解析为IPv6地址。

`host` (string)
:    主机名。

`client` (string)
:    用户身份标识，此信息由认证器生成。

`ips` ([]string)
:    IP地址列表