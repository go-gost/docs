# TCP远程端口转发

处理器名称: `rtcp`

状态：Stable

RTCP处理器根据服务中的转发器配置，将数据转发给指定的目标主机。

=== "命令行"
	```bash
	gost -L rtcp://:2222/:22
	```
=== "配置文件"
    ```yaml
	services:
	- name: service-0
	  addr: :2222
	  handler:
		type: rtcp
	  listener:
		type: rtcp
	  forwarder:
		targets:
		- 192.168.1.1:80
	```

## 参数列表

无

!!! note "限制"
    rtcp处理器只能与[rtcp监听器](/components/listeners/rtcp/)一起使用，构建TCP远程端口转发服务。

