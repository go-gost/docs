# SOCKS4

名称: `socks4`

状态： GA

SOCKS4连接器使用标准SOCKSv4代理协议(同时兼容SOCKS4A协议)进行数据交互。

=== "命令行"
    ```
	gost -L :8000 -F socks4://192.168.1.1:1080
	```

=== "配置文件"
    ```yaml
	services:
	- name: service-0
	  addr: ":8000"
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
		  addr: 192.168.1.1:1080
		  connector:
			type: socks4
		  dialer:
			type: tcp
	```

## 参数列表

`disable4a` (bool, default=false)
:    禁用SOCKS4A协议
