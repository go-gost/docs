# TCP远程端口转发

器Name: `rtcp`

Status： Stable

RTCP处理器根据服务中的转发器配置，将数据转发给指定的目标主机。

=== "CLI"
	```bash
	gost -L rtcp://:2222/:22
	```
=== "File (YAML)"

    ```yaml
	services:
	- name: service-0
	  addr: :2222
	  handler:
		type: rtcp
	  listener:
		type: rtcp
	  forwarder:
	    nodes:
		- name: target-0
		  addr: :22
	```

## 参数列表

无

!!! note "限制"
    RTCP处理器只能与[rtcp监听器](/reference/listeners/rtcp/)一起使用，构建TCP远程端口转发服务。

