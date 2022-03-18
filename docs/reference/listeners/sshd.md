# SSHD

监听器名称: `sshd`

状态： GA

SSHD监听器根据服务配置，监听在指定TCP端口，并使用SSH协议进行通讯。

SSH监听器支持简单用户名+密码认证和公钥认证。

## 用户名+密码认证

=== "命令行"
    ```
	gost -L sshd://gost:gost@:2222
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
		auth:
		  username: gost
		  password: gost
	```

!!! caution "认证信息"
    认证信息作用于监听器，如果需要对处理器设置认证可以通过配置文件指定
	```yaml
	services:
	- name: service-0
	  addr: ":8443"
	  handler:
		type: sshd
		auth:
		  username: gost 
		  password: gost
		# or use auther
		# auther: auther-0
	  listener:
		type: sshd
	```

## 公钥认证

=== "命令行"
    ```
	gost -L sshd://gost@:2222?authorizedKeys=/path/to/authorized_keys
	```
=== "配置文件"
    ```yaml
	services:
	- name: service-0
	  addr: ":2222"
	  handler:
		type: sshd
		auth:
		  username: gost
	  listener:
		type: sshd
		metadata:
		  authorizedKeys: /path/to/authorized_keys
	```

## 参数列表

`backlog` (int, default=128)
:    单个连接的数据流队大小

`privateKeyFile` (string)
:    证书私钥文件

`passphrase` (string)
:    证书密码

`authorizedKeys` (string)
:    客户端公钥列表文件

!!! note "限制"
    SSHD监听器只能与[SSHD处理器](/reference/handlers/sshd/)一起使用，构建基于SSH协议的标准端口转发服务。