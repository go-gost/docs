# SOCKSv4(a)

Name: `socks4`

Status： GA

SOCKS4处理器使用标准SOCKSv4代理协议(同时兼容SOCKS4A协议)进行数据交互，接收并处理客户端请求。

=== "CLI"
    ```
	gost -L socks4://:8080
	```
=== "File (YAML)"
    ```yaml
	services:
	- name: service-0
	  addr: ":8080"
	  handler:
		type: socks4
	  listener:
		type: tcp
	```

## 参数列表

无