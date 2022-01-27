# Auto

处理器名称: `auto`

状态：Stable

Auto处理器可以被看作一个路由处理器，将HTTP, SOCKS4, SOCKS5和Relay处理器组合在一起，根据请求头自动判断请求类型，并转发到对应处理器处理。

=== "命令行"
    ```
	gost -L auto://:8080
	```
=== "配置文件"
    ```yaml
	services:
	- name: service-0
	  addr: ":8080"
	  handler:
		type: auto
	  listener:
		type: tcp
	```

## 参数列表

无