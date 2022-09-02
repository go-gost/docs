# 转发链

!!! tip "动态配置"
    转发链支持通过Web API进行动态配置。

转发链是由若干个节点按照特定的层级分组所形成的节点组列表，每一层级节点组构成一个跳跃点，数据依次经过每个跳跃点进行转发。转发链是GOST中一个重要模块，是服务与服务之间建立连接的纽带。

转发链中的节点彼此之间相互独立，每个节点可以单独使用不同的数据通道和数据处理协议。

=== "命令行"

	```
	gost -L http://:8080 -F https://192.168.1.1:8080 -F socks5+ws://192.168.1.2:1080
	```

=== "配置文件"

    ```yaml
	services:
	- name: service-0
	  addr: ":8080"
	  handler:
		type: http
		chain: chain-0
	  listener:
		type: tcp
	chains:
	- name: chain-0
	  hops:
	  - name: hop-0
		nodes:
		- name: node-0
		  addr: 192.168.1.1:8080
		  connector:
			type: http
		  dialer:
		    type: tls
	  - name: hop-1
		nodes:
		- name: node-0
		  addr: 192.168.1.2:1080
		  connector:
			type: socks5
		  dialer:
		    type: ws
	```

在命令行中所有的`-F`参数构成一个转发链，所有的服务使用此转发链。
在配置文件中服务的监听器或处理器通过`chain`属性引用转发链的名称(`name`属性)使用指定的转发链。

## 节点组

每一层级可以添加多个节点组成节点组。

=== "命令行"

	```
	gost -L http://:8080 -F https://192.168.1.1:8080,192.168.1.1:8081,192.168.1.2:8082 -F socks5+ws://192.168.0.1:1080,192.168.0.1:1081,192.168.0.2:1082
	```

=== "配置文件"

    ```yaml
	services:
	- name: service-0
	  addr: ":8080"
	  handler:
		type: http
		chain: chain-0
	  listener:
		type: tcp
	chains:
	- name: chain-0
	  hops:
	  - name: hop-0
		nodes:
		- name: node-0
		  addr: 192.168.1.1:8080
		  connector:
			type: http
		  dialer:
		    type: tls
		- name: node-1
		  addr: 192.168.1.1:8081
		  connector:
			type: http
		  dialer:
		    type: tls
		- name: node-2
		  addr: 192.168.1.2:8082
		  connector:
			type: http
		  dialer:
		    type: tls
	  - name: hop-1
		nodes:
		- name: node-0
		  addr: 192.168.0.1:1080
		  connector:
			type: socks5
		  dialer:
		    type: ws
		- name: node-1
		  addr: 192.168.0.1:1081
		  connector:
			type: socks5
		  dialer:
		    type: ws
		- name: node-2
		  addr: 192.168.0.2:1082
		  connector:
			type: socks5
		  dialer:
		    type: ws
	```

第一个跳跃点(hop-0)节点组中有三个节点：192.168.1.1:8080(node-0)，192.168.1.1:8081(node-1)，192.168.1.2:8082(node-2)，它们使用相同的节点配置。

第二个跳跃点(hop-1)节点组中有三个节点：192.168.0.1:1080(node-0)，192.168.0.1:1081(node-1)，192.168.0.2:1082(node-2)，它们使用相同的节点配置。

如果需要自由配置每个节点可以使用配置文件。

```yaml
services:
- name: service-0
  addr: ":8080"
  handler:
    type: http
    chain: chain-0
  listener:
    type: tcp
chains:
- name: chain-0
  hops:
  - name: hop-0
    nodes:
    - name: node-0
      addr: 192.168.1.1:8080
      connector:
        type: http
      dialer:
        type: tls
    - name: node-1
      addr: 192.168.1.1:8081
      connector:
        type: socks5
      dialer:
        type: ws
    - name: node-2
      addr: 192.168.1.2:8082
      connector:
        type: relay
      dialer:
        type: tls
  - name: hop-1
    nodes:
    - name: node-0
      addr: 192.168.0.1:1080
      connector:
        type: socks5
      dialer:
        type: ws
    - name: node-1
      addr: 192.168.0.1:1081
      connector:
        type: relay
      dialer:
        type: tls
    - name: node-2
      addr: 192.168.0.2:1082
      connector:
        type: http
      dialer:
        type: h2
```

## 多条转发链

在配置文件中可以设置多个转发链，不同的服务可以根据名称来使用不同的转发链。

```yaml linenums="1" hl_lines="6 13 17 27"
services:
- name: service-0
  addr: ":8080"
  handler:
    type: http
    chain: chain-0
  listener:
    type: tcp
- name: service-1
  addr: ":1080"
  handler:
    type: socks5
    chain: chain-1
  listener:
    type: tcp
chains:
- name: chain-0
  hops:
  - name: hop-0
  	nodes:
    - name: node-0
      addr: 192.168.1.1:8080
      connector:
        type: http
      dialer:
        type: tls
- name: chain-1
  hops:
  - name: hop-0
    nodes:
    - name: node-0
      addr: 192.168.1.2:8082
      connector:
        type: relay
      dialer:
        type: tls
  - name: hop-1
    nodes:
    - name: node-0
      addr: 192.168.0.1:1080
      connector:
        type: socks5
      dialer:
        type: ws
    - name: node-1
      addr: 192.168.0.1:1081
      connector:
        type: relay
      dialer:
        type: tls
```

服务service-0使用转发链chain-0，服务service-1使用转发链chain-1。

## 转发链组

在服务的监听器或处理器上也可以通过`chainGroup`参数来指定转发链组来使用多条转发链，同时也可以设置一个[选择器(selector)](/concepts/selector/)指定转发链使用方式，默认使用轮询策略。


```yaml linenums="1" hl_lines="6 7 8 9 10 11 12 13"
services:
- name: service-0
  addr: ":8080"
  handler:
    type: http
    chainGroup:
      chains:
      - chain-0
      - chain-1
      selector:
        strategy: round
        maxFails: 1
        failTimeout: 10s
  listener:
    type: tcp
chains:
- name: chain-0
  hops:
  - name: hop-0
    nodes:
    - name: node-0
      addr: :8081
      connector:
        type: http
      dialer:
        type: tcp
- name: chain-1
  hops:
  - name: hop-0
    nodes:
    - name: node-0
      addr: :8082
      connector:
        type: http
      dialer:
        type: tcp
```

服务service-0采用轮询的方式使用两条转发链chain-0和chain-1。


!!! caution "限制"
    如果节点的数据通道使用UDP协议，例如QUIC, KCP等，则此节点只能用于转发链第一层级。