# SOCKS5

名称： `socks`, `socks5`

状态： Stable

SOCKS5连接器使用标准SOCKSv5代理协议进行数据交互。

=== "命令行"
    ```
	gost -L :8000 -F socks5://192.168.1.1:1080?notls=true
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
			type: socks5
			metadata:
			  notls: true
		  dialer:
			type: tcp
	```

## 参数列表

`notls` (bool, default=false)
:    禁用TLS协商加密扩展协议
