# TUN

名称: `tun`

状态： GA

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

`name` (string)
:    指定TUN设备的名字，默认值为系统预设

`net` (string, required)
:    指定TUN设备的地址

`mtu` (int, default=1350)
:    设置TUN设备的MTU值

`routes` (strings)
:    路由列表

`gw` (string)
:    默认网关IP

`peer` (string)
:    对端IP地址，仅MacOS系统有效

!!! note "限制"
    TUN监听器只能与[TUN处理器](/reference/handlers/tun/)一起使用，构建基于TUN设备的VPN。