# 域名解析

## 域名解析器

在服务中可以设置域名解析器来自定义域名的解析。当服务中的处理器在与目标主机建立连接之前，会使用域名解析器对域名进行解析。

=== "命令行"
	```
	gost -L http://:8080?resolver=1.1.1.1,tcp://8.8.8.8,tls://8.8.8.8:853,https://1.0.0.1/dns-query
	```

	通过`resolver`参数来指定上级域名解析服务列表。


=== "配置文件"
    ```yaml
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

每个DNS服务的格式为：[protocol://]ip[:port]。

`protocol`支持的类型有`udp`，`tcp`，`tls`，`https`，默认值为`udp`。

`port`默认值为53。

## 使用转发链

域名解析器中的每个上级域名服务可以分别设置转发链。

```yaml
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
