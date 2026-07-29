---
comments: true
---

# 转发链

!!! tip "动态配置"
    转发链支持通过[Web API](../tutorials/api/overview.md)进行动态配置。

转发链是由若干个节点按照特定的层级分组所形成的节点组列表，每一层级节点组构成一个[跳跃点](hop.md)，数据依次经过每个跳跃点进行转发。转发链是GOST中一个重要模块，是服务与服务之间建立连接的纽带。

转发链中的节点彼此之间相互独立，每个节点可以单独使用不同的数据通道和数据处理协议。

=== "命令行"

	```bash
	gost -L http://:8080 -F https://192.168.1.1:8080 -F socks5+ws://192.168.1.2:1080
	```

=== "配置文件"

    ```yaml hl_lines="6 10"
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

	```bash
	gost -L http://:8080 -F https://192.168.1.1:8080,192.168.1.1:8081,192.168.1.2:8082 -F socks5+ws://192.168.0.1:1080,192.168.0.1:1081,192.168.0.2:1082
	```

=== "配置文件"

    ```yaml hl_lines="14 20 26 34 40 46"
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

```yaml hl_lines="6 13 17 27"
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

在服务的监听器或处理器上也可以通过`chainGroup`参数来指定转发链组来使用多条转发链，同时也可以设置一个[选择器(selector)](selector.md)指定转发链使用方式，默认使用轮询策略。

```yaml hl_lines="6 7 8 9 10 11 12 13"
services:
- name: service-0
  addr: ":8080"
  handler:
    type: http
    chainGroup:
      chains:
      - chain: chain-0
      - chain: chain-1
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

### 匹配器(Matcher)

:material-tag: 3.3.0

每条链条目可以携带一个`matcher`匹配规则。只有匹配器与当前请求匹配的条目才有资格被选择。完整的DSL参考请参见 [匹配器](matcher.md)。

在转发链组层级，匹配器会看到请求的目标主机名（通过`Host()`匹配器）。

```yaml hl_lines="7 8 9"
services:
- name: service-0
  addr: ":8080"
  handler:
    type: http
    chainGroup:
      chains:
      - chain: chain-api
        matcher:
          rule: Host(`api.example.com`)
      - chain: chain-web
        matcher:
          rule: Host(`*.example.com`)
      - chain: chain-default
      selector:
        strategy: round
  listener:
    type: tcp
```

!!! note "向后兼容"
    链条目接受纯字符串（旧格式：`chains: [chain-0, chain-1]`）或带`chain`、`matcher`和`probe`字段的结构化对象。

### 探针(Probe)

:material-tag: 3.3.0

链条目可以设置`probe`对整个转发链进行端到端健康检查。探针通过转发链路由定期拨号到目标地址。如果探针失败，链条目的标记会被设置 — 组选择器中的`FailFilter`会将其排除在选择之外，直到恢复。

支持的探针类型：`tcp`、`http`、`cmd`。探针使用转发链的完整`Route.Dial()`路径，测试每一个跳跃点。

```yaml hl_lines="7 8 9 10 11"
services:
- name: service-0
  addr: ":8080"
  handler:
    type: http
    chainGroup:
      chains:
      - chain: chain-primary
        probe:
          type: tcp
          addr: 127.0.0.1:8081
          interval: 10s
      - chain: chain-fallback
        probe:
          type: http
          addr: 127.0.0.1:8082
          httpPath: /health
          interval: 5s
      selector:
        strategy: round
        maxFails: 1
        failTimeout: 30s
  listener:
    type: tcp
```

!!! note "探针标记的独立性"
    探针标记的是链条目自身的标记 — 与转发链内部的任何节点级别标记是独立的。节点级别的`failCodes`和链级别的探针不会互相干扰。

### 选择流程

1. **匹配器过滤** — 从匹配器匹配请求上下文（主机名、客户端IP等）的条目中构建候选池。未设置匹配器 = 始终有资格。
2. **选择器管道** — 应用`FailFilter`（排除被探针标记的条目）→ `BackupFilter` → 策略（轮询、随机等）→ 选择一个链条目。
3. **路由** — 委托给获胜条目的`Route()`方法，该方法从转发链的每个跳跃点中选择节点。

## 虚拟节点

如果服务不需要使用上级代理，可以使用一种特殊的虚拟节点(`connector.type`和`dialer.type`均为`virtual`)来直接连接目标地址，虚拟节点不需要对应的服务端，因此节点的`addr`参数无效。

=== "命令行"

    ```bash
    gost -L :8080 -F virtual://:0?interface=eth0
    ```

=== "配置文件"

    ```yaml hl_lines="17 18 19 20"
    services:
    - name: service-0
      addr: ":8080"
      handler:
        type: auto
        chain: chain-0
      listener:
        type: tcp
      chains:
      - name: chain-0
        hops:
        - name: hop-0
          nodes:
          - name: node-0
            interface: eth0
            connector:
              type: virtual
            dialer:
              type: virtual
          - name: node-1
            interface: eth1
            connector:
              type: virtual
              # metadata:
              #   action: reject
            dialer:
              type: virtual
	```

这里node-0和node-1为直连节点，当主机具有[多个网络出口](../tutorials/multi-homed.md)时，可以通过`interface`参数为每个节点指定不同的网络出口，从而达到网络出口级别的负载均衡。

也可以通过设置`connector.metadata.action`为`reject`来拒绝所有连接。

!!! caution "限制"
    如果节点的数据通道使用UDP协议，例如QUIC, KCP等，则此节点只能用于转发链第一层级。