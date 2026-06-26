# SSHD

名称: `sshd`

状态： GA

SSHD拨号器使用SSH协议建立数据通道。

SSH拨号器支持简单用户名/密码认证和公钥认证。

## 用户名/密码认证

=== "命令行"
    ```
	gost -L :8080 -F sshd://gost:gost@:8443
	```
=== "配置文件"
	```yaml
	services:
	- name: service-0
	  addr: ":8080"
	  handler:
		type: auto
		chain: chain-0
	  listener:
		type: tcp
	chains:
	- name: chain-0
	  hops:
	  - name: hop-0
		nodes:
		- name: node-0
		  addr: :8443
		  connector:
			type: sshd
		  dialer:
			type: sshd
			auth:
			  username: gost 
			  password: gost
	```

!!! caution "认证信息"
    认证信息作用于拨号器，如果需要对连接器设置认证可以通过配置文件指定
    ```yaml
    services:
	- name: service-0
	  addr: ":8080"
      handler:
        type: auto
        chain: chain-0
      listener:
        type: tcp
    chains:
    - name: chain-0
      hops:
      - name: hop-0
        nodes:
        - name: node-0
          addr: :8443
          connector:
            type: sshd
		    auth:
		      username: gost 
		      password: gost
          dialer:
            type: sshd
    ```

## 公钥认证

SSHD拨号器支持多种公钥认证方式：通过`privateKeyFile`指定私钥文件、通过`SSH_AUTH_SOCK`环境变量使用SSH Agent、或通过密钥环读取密码。

通过设置`SSH_AUTH_SOCK`环境变量，GOST会自动连接本地的SSH Agent进行公钥认证，无需在配置文件中指定私钥文件路径。

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
:    证书私钥文件。路径支持`~`前缀进行家目录扩展（例如`~/.ssh/id_rsa`）

`passphrase` (string)
:    证书密码

`passphraseFromKeyring` (bool, default=false)
:    从系统密钥环中读取证书密码。启用此选项后，`passphrase`参数将被忽略，GOST会通过密钥环读取`SSH <privateKeyFile>`对应的密码

`authorizedKeys` (string)
:    客户端公钥列表文件

!!! note "限制"
    SSHD监听器只能与[SSHD处理器](/reference/handlers/sshd/)一起使用，构建基于SSH协议的标准端口转发服务。