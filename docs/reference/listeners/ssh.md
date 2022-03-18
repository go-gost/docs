# SSH数据通道

监听器名称: `ssh`

状态： GA

SSH监听器根据服务配置，监听在指定TCP端口，并使用SSH协议进行通讯。

SSH监听器支持简单用户名+密码认证和公钥认证。

## 用户名+密码认证

=== "命令行"
    ```
	gost -L http+ssh://gost:gost@:8443
	```
=== "配置文件"
    ```yaml
	services:
	- name: service-0
	  addr: ":8443"
	  handler:
		type: http
		auth:
		  username: gost 
		  password: gost
	  listener:
		type: ssh
	```

!!! caution "认证信息"
    认证信息默认作用于处理器，如果需要对监听器设置认证可以通过配置文件指定
	```yaml
	services:
	- name: service-0
	  addr: ":8443"
	  handler:
		type: http
	  listener:
		type: ssh
		auth:
		  username: gost 
		  password: gost
		# or use auther
		# auther: auther-0
	```

## 公钥认证

=== "命令行"
    ```
	gost -L http+ssh://gost@:8443?authorizedKeys=/path/to/authorized_keys
	```
=== "配置文件"
    ```yaml
	services:
	- name: service-0
	  addr: ":8443"
	  handler:
		type: http
		auth:
		  username: gost
	  listener:
		type: ssh
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