# UDP远程端口转发

处理器名称: `rudp`

状态： Stable

RUDP处理器根据服务中的转发器配置，将数据转发给指定的目标主机。

=== "命令行"
	```bash
	gost -L rudp://:10053/:53
	```
=== "配置文件"
    ```yaml
	services:
	- name: service-0
	  addr: :10053
	  handler:
		type: rudp
	  listener:
		type: rudp
	  forwarder:
		targets:
		- :53
	```

## 参数列表

无

!!! note "限制"
    rudp处理器只能与[rudp监听器](/reference/listeners/rudp/)一起使用，构建UDP远程端口转发服务。


