# TAP

处理器名称: `tap`

状态： GA

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
		metadata:
		  bufferSize: 1024
	  listener:
		type: tap
		metadata:
		  net: 192.168.123.2/24
	```

## 参数列表

`bufferSize` (int, default=1024)
:   数据读写缓冲区字节大小 

!!! note "限制"
    TAP处理器只能与[TAP监听器](/components/listeners/tap/)一起使用，构建基于TAP设备的VPN。