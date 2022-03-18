# 认证

GOST中可以通过设置单认证信息或认证器进行简单的身份认证。

!!! tip "动态配置"
    认证器支持通过Web API进行动态配置。

## 认证器

认证器包含一组或多组认证信息。服务通过认证器可以实现多用户认证功能。

认证器仅支持配置文件设置。

=== "配置文件"
    ```yaml
    services:
    - name: service-0
      addr: ":8080"
      handler:
        type: http
		auther: auther-0
      listener:
        type: tcp
	authers:
	- name: auther-0
	  auths:
	  - username: user1
	    password: pass1
	  - username: user2
        password: pass2
	```

服务的处理器或监听器上通过`auther`属性引用认证器名称(name)来使用指定的认证器。

## 单认证信息

如果不需要多用户认证，则可以通过直接设置单认证信息来进行单用户认证。

!!! caution "Shadowsocks处理器"
    Shadowsocks处理器无法使用认证器，仅支持通过设置单认证信息作为加密参数。

### 服务端

=== "命令行"

	直接通过`username:password`方式设置

    ```sh
	gost -L http://user:pass@:8080
	```
	如果认证信息中包含特殊字符，也可以通过`auth`参数来设置，`auth`的值为`username:password`形式的base64编码值。
	```sh
	echo -n user:pass | base64
	```

	```sh
	gost -L http://:8080?auth=dXNlcjpwYXNz
	```

=== "配置文件"

    ```yaml
	services:
	- name: service-0
	  addr: ":8080"
	  handler:
		type: http
		auth:
		  username: user
		  password: pass
	  listener:
		type: tcp
	```

    服务的处理器或监听器上通过`auth`属性设置单认证信息。

### 客户端

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
	节点的连接器或拨号器上通过`auth`属性设置单认证信息。

!!! note "注意"
	通过命令行设置的认证信息仅会应用到处理器或连接器上，对于sshd服务则会应用到监听器和拨号器上。

	如果通过命令行自动生成配置文件，在metadata中不会出现此参数项。

!!! caution "优先级"
    如果使用了认证器，则单认证信息会被忽略。

	如果设置了`auth`参数，则路径中直接设置的认证信息会被忽略。