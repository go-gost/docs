# Node Selection

## Selector

在GOST中，节点组中节点的选择是通过节点选择器来完成的。选择器负责在一个节点组中使用节点选择策略选择出零个或一个节点。选择其可以应用于转发链，转发链中的跳跃点，和转发器上。节点选择器在GOST中用来实现负载均衡。

`strategy` (string, default=round)
:    指定节点选择策略。
    
     * `round` - 轮询
     * `rand` - 随机
     * `fifo` - 自上而下，主备模式

`maxFails` (int, default=1)
:    指定节点连接的最大失败次数，当与一个节点建立连接失败次数超过此设定值时，此节点会被标记为死亡节点(Dead)，死亡节点不会被选择使用。

`failTimeout` (duration, default=30s)
:    指定死亡节点的超时时长，当一个节点被标记为死亡节点后，在此设定的时间间隔内不会被选择使用，超过此设定时间间隔后，会再次参与节点选择。

## 转发链

转发链本身和其中的每一层级跳跃点上可以设置一个选择器，如果跳跃点上没有设置选择器，则使用转发链上的选择器，默认选择器使用轮询策略进行节点选择。

=== "命令行"
	```
	gost -L http://:8080 -F socks5://192.168.1.1:1080,192.168.1.2:1080?strategy=rand&maxFails=3&failTimeout=60s
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
	  # chain level selector
      selector:
        strategy: round
        maxFails: 1
        failTimeout: 30s
      hops:
      - name: hop-0
	    # hop level selector
        selector:
          strategy: rand
          maxFails: 3
          failTimeout: 60s
        nodes:
        - name: node-0
          addr: 192.168.1.1:1080
          connector:
            type: socks5
          dialer:
            type: tcp
        - name: node-1
          addr: 192.168.1.2:1080
          connector:
            type: socks5
          dialer:
            type: tcp
	```

## 转发器

转发器用于端口转发，其本身由一个节点组和一个节点选择器组成，当进行转发时，通过选择器在节点组中选择出零个或一个节点用于转发的目标地址。此时转发器类似于单跳跃点的转发链。

=== "命令行"
    ```
	gost -L "tcp://:8080/192.168.1.1:8081,192.168.1.2:8082?strategy=round&maxFails=1&failTimeout=30s
	```
=== "配置文件"
    ```yaml
	services:
	- name: service-0
	  addr: :8080
	  handler:
		type: tcp
	  listener:
		type: tcp
	  forwarder:
		targets:
		- 192.168.1.1:8081
		- 192.168.1.2:8082
		selector:
		  strategy: round
		  maxFails: 1
		  failTimeout: 30s
	```

## 负载均衡

通过节点组和选择器的组合使用，我们就可以在数据转发中实现负载均衡的功能。