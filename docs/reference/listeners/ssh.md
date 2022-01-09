# SSH

监听器名称: `ssh`

SSH监听器根据服务配置，监听在指定TCP端口，并使用SSH协议进行通讯。

SSH监听器支持简单用户名+密码认证和公钥认证。

## 用户名+密码认证

=== "命令行"
    ```
	gost -L http+ssh://user:pass@:8443
	```
=== "配置文件"
    ```yaml
	services:
	- name: service-0
	  addr: ":8443"
	  handler:
		type: http
		auths:
		- username: user1
		  password: pass1
	  listener:
		type: ssh
	```

## 公钥认证

=== "命令行"
    ```
	gost -L http+ssh://:8443?authorizedKeys=/path/to/authorized_keys
	```
=== "配置文件"
    ```yaml
	services:
	- name: service-0
	  addr: ":8443"
	  handler:
		type: http
		auths:
		- username: user1
		  password: pass1
	  listener:
		type: ssh
		metadata:
		  authorizedKeys: /path/to/authorized_keys
	```

## 参数列表

`backlog`
:    单个连接的数据流队大小，默认值: 128

`privateKeyFile`
:    证书私钥文件

`passphrase`
:    证书密码

`authorizedKeys`
:    客户端公钥列表文件