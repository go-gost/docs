# TUN

监听器名称: `tun`

TUN监听器根据服务配置，监听在指定UDP端口，并创建和初始化TUN设备。

=== "命令行"
    ```
	gost -L tun://:8421?net=192.168.123.2/24
	```
=== "配置文件"
    ```yaml
	services:
	- name: service-0
	  addr: ":8421"
	  handler:
		type: tun
	  listener:
		type: tun
		metadata:
		  net: 192.168.123.2/24
	```

## 参数列表

`name`
:    指定TUN设备的名字，默认值为系统预设

`net`
:    必须，指定TUN设备的地址

`mtu`
:    设置TUN设备的MTU值，默认值: 1350

`routes`
:    路由列表

`gw`
:    默认网关IP

!!! note "注意"
    TUN监听器只能与[TUN处理器](/components/handlers/tun/)一起使用，构建基于TUN设备的VPN。