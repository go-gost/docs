# UDP端口转发

Name: `udp`

状态： Stable

UDP处理器仅做纯UDP数据转发工作。根据服务中的转发器配置，将数据转发给指定的目标主机。

=== "命令行"

	```bash
	gost -L udp://:10053/192.168.1.1:53
	```

=== "配置文件"

    ```yaml
	services:
	- name: service-0
	  addr: :10053
	  handler:
		type: udp
	  listener:
		type: udp 
	  forwarder:
	    nodes:
		- name: target-0
		  addr: 192.168.1.1:53
	```

## 参数列表

无


