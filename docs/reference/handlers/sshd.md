# SSHD

处理器名称: `sshd`

状态：GA

sshd处理器使用SSH协议进行数据交互，接收并处理客户端请求。

=== "命令行"
    ```
	gost -L sshd://:2222
	```
=== "配置文件"
    ```yaml
	services:
	- name: service-0
	  addr: ":2222"
	  handler:
		type: sshd
	  listener:
		type: sshd
	```

## 参数列表

无

!!! note "限制"
    SSHD处理器只能与[SSHD监听器](/components/listeners/sshd/)一起使用，构建基于SSH协议的标准端口转发服务。

