# SSHD

Name: `sshd`

Status： GA

sshd处理器使用SSH协议进行数据交互，接收并处理客户端请求。

!!! note "认证信息"
    在这里的认证信息是设置在sshd监听器上。

=== "CLI"
    ```
	gost -L sshd://gost:gost@:2222
	```
=== "File (YAML)"
    ```yaml
	services:
	- name: service-0
	  addr: ":2222"
	  handler:
		type: sshd
	  listener:
		type: sshd
		auth:
		  username: gost
		  password: gost
	```
## 参数列表

无

!!! note "限制"
    SSHD处理器只能与[SSHD监听器](/reference/listeners/sshd/)一起使用，构建基于SSH协议的标准端口转发服务。

