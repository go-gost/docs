# 认证

## 服务端设置

=== "命令行"

	直接通过`username:password`方式设置

    ```
	gost -L http://user:pass@:8080
	```
	如果认证信息中包含特殊字符，也可以通过`auth`参数来设置，`auth`的值为`username:password`形式的base64编码值。

	```
	gost -L http://:8080?auth=dXNlcjpwYXNz
	```

=== "配置文件"

	通过`handler`的`auths`参数设置单个或多个认证信息。

    ```yaml
	services:
	- name: service-0
	  addr: ":8080"
	  handler:
		type: http
		auths:
		- username: user1
		  password: pass1
		- username: user2
		  password: pass2
	  listener:
		type: tcp
	```

## 客户端设置

=== "命令行"

	直接通过`username:password`方式设置

    ```
	gost -L http://:8080 -F socks5://user:pass@:1080
	```
	如果认证信息中包含特殊字符，也可以通过`auth`参数来设置，`auth`的值为`username:password`形式的base64编码值。

	```
	gost -L http://:8080 -F socks5://:1080?auth=dXNlcjpwYXNz
	```

=== "配置文件"

	通过`connector`的`auth`参数设置认证信息。

    ```yaml
	services:
	- name: service-0
	  addr: ":8080"
	  handler:
		type: http
		chain: chain-0
	  listener:
		type: tcp
	chains:
	- name: chain-0
	  hops:
	  - name: hop-0
		nodes:
		- name: node-0
		  addr: :1080
		  connector:
			type: socks5
			auth:
			  username: user
			  password: pass
		  dialer:
		    type: tcp
	```

!!! note "注意"
	通过命令行设置的认证信息仅会应用到处理器或连接器上。

    GOST会将命令行中的`auth`参数提取出来设置到`handler.auths`或`connector.auth`中，
	如果通过命令行自动生成配置文件，在metadata中不会出现此参数项。