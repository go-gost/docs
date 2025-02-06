# TCP端口转发

Name: `tcp`

Status： Stable

TCP处理器仅做纯TCP数据转发工作。根据服务中的转发器配置，将数据转发给指定的目标主机。

=== "命令行"

	```bash
	gost -L tcp://:8080/192.168.1.1:80
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
	    nodes:
		- name: target-0
		  addr: 192.168.1.1:80
	```

## 参数列表

无


