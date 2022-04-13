# Fake TCP

名称: `ftcp`

状态： Alpha

FTCP使用[tcpraw](github.com/xtaci/tcpraw)模拟TCP协议建立数据通道。

=== "命令行"
    ```
	gost -L :8080 -F http+ftcp://:8443
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
			type: http
		  dialer:
			type: ftcp
	```

## 参数列表
无