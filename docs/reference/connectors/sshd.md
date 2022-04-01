# SSH Forward

名称： `sshd`

状态： GA

sshd处理器使用SSH协议进行数据交互，用于SSH端口转发。

!!! note "认证信息"
    在这里的认证信息是设置在sshd拨号器上。
	
=== "命令行"
    ```
	gost -L=tcp://:8080/192.168.1.1:80 -F sshd://gost:gost@192.168.1.2:22
	```

=== "配置文件"
    ```yaml
	services:
	- name: service-0
	  addr: :8080
	  handler:
		type: tcp
		chain: chain-0
	  listener:
		type: tcp
	  forwarder:
		targets:
		- 192.168.1.1:80
	chains:
	- name: chain-0
	  hops:
	  - name: hop-0
		nodes:
		- name: node-0
		  addr: 192.168.1.2:22
		  connector:
			type: sshd
		  dialer:
			type: sshd
			auth:
			  username: gost
			  password: gost
	```

这里的192.168.1.2:22服务可以是系统本身的标准SSH服务，也可以是GOST的sshd类型服务

## 参数列表

无

!!! note "限制"
    SSHD连接器只能与[SSHD拨号器](/reference/dialers/sshd/)一起使用，构建基于SSH协议的标准端口转发服务。
