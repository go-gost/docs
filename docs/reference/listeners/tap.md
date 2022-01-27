# TAP

监听器名称: `tap`

状态： GA

TAP监听器根据服务配置，监听在指定UDP端口，并创建和初始化TAP设备。

=== "命令行"
    ```
	gost -L tap://:8421?net=192.168.123.2/24
	```
=== "配置文件"
    ```yaml
	services:
	- name: service-0
	  addr: ":8421"
	  handler:
		type: tap
	  listener:
		type: tap
		metadata:
		  net: 192.168.123.2/24
	```

## 参数列表

`name` (string)
:    指定TAP设备的名字，默认值为系统预设

`net` (string, required)
:    指定TAP设备的地址

`mtu` (int, default=1350)
:    设置TAP设备的MTU值

`routes` (strings)
:    路由列表

`gw` (string)
:    默认网关IP

!!! note "限制"
    TAP监听器只能与[TAP处理器](/components/handlers/tap/)一起使用，构建基于TAP设备的VPN。