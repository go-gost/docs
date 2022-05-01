# 多网络接口

当主机具有多个网络接口(Multi-homed host)时，可以根据需要对不同服务的路由指定不同的网络出口。

!!! note "系统限制"
    多网络接口配置仅支持Linux系统。

## `interface`参数

通过`interface`参数来指定所使用的网络出口。`interface`参数的值可以是网络接口名(例如`eth0`)，也可以是网络接口的IP地址(IPv4或IPv6)。

=== "命令行"
    ```
	gost -L :8080?interface=eth0
	```

=== "配置文件"
    ```yaml
	services:
	- name: service-0
	  addr: ":8080"
	  interface: eth0
	  # or use IP address
	  # interface: 192.168.0.123
	  handler:
		type: auto
	  listener:
		type: tcp
	```

## 转发链

如果使用了转发链，则需要在转发链的第一层级跳跃点上或其中的节点上设置网络出口。
如果节点上未设置`interface`参数，则使用跳跃点上的参数。
命令行中的`interface`参数对应于跳跃点上的参数。

=== "命令行"
    ```
	gost -L :8080 -F :8000?interface=192.168.0.1 
	```

=== "配置文件"
    ```yaml
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
	    # hop level interface
        interface: 192.168.0.1
        nodes:
        - name: node-0
          addr: :8000
		  # node level interface
		  interface: eth0
          connector:
            type: http
          dialer:
            type: tcp
	```
