---
comments: true
---

# 多网络接口

当主机具有多个网络接口(Multi-homed host)时，可以根据需要对不同服务的路由指定不同的网络出口。

!!! note "系统限制"
    多网络接口配置仅支持Linux/Windows/Darwin系统。

## `interface`选项

通过`interface`选项来指定所使用的网络出口。`interface`选项的值可以是网络接口名(例如`eth0`)，也可以是网络接口的IP地址(IPv4或IPv6)，或`,`分割的IP地址列表。

=== "命令行"

    ```bash
    gost -L :8080?interface=eth0
    ```

=== "配置文件"

    ```yaml hl_lines="4 6"
    services:
    - name: service-0
      addr: ":8080"
      metadata:
        interface: eth0
        # or use IP address
        # interface: 192.168.0.123
        # or IP address list
        # interface: fd::1,192.168.0.123
      handler:
        type: auto
      listener:
        type: tcp
    ```

!!! note "严格模式"
    当指定接口列表时，可以在每一项后面添加`!`来标记为严格模式，
    例如`interface=192.168.0.100,192.168.0.101!,192.168.0.102`，如果通过192.168.0.101建立连接失败则不会继续尝试192.168.0.102。

## 转发链

如果使用了转发链，则需要在转发链的第一层级跳跃点上或其中的节点上设置网络出口。
如果节点上未设置`interface`参数，则使用跳跃点上的参数。
命令行中的`interface`参数对应于跳跃点上的参数。

=== "命令行"

    ```bash
    gost -L :8080 -F :8000?interface=192.168.0.1 
    ```

=== "配置文件"

    ```yaml hl_lines="14 19 27"
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
        - name: node-1
          addr: :8001
          # node level interface
          interface: eth1
          connector:
            type: http
          dialer:
            type: tcp
    ```

## 直连模式

如果不使用上级代理，则可以通过[虚拟节点](../concepts/chain.md)让服务使用多网口进行负载均衡。

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
        nodes:
        - name: node-0
          addr: :0
          interface: eth0
          connector:
            type: virtual
          dialer:
            type: virtual
        - name: node-1
          addr: :0
          interface: eth1
          connector:
            type: virtual
          dialer:
            type: virtual
	```
