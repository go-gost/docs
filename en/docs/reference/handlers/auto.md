# Auto

Name: `auto`

Status： Stable

Auto处理器可以被看作一个路由处理器，将HTTP, SOCKS4和SOCKS5处理器组合在一起，根据请求头自动判断请求类型，并转发到对应处理器处理。

=== "CLI"
    ```
	gost -L :8080
	```
	等同于
    ```
	gost -L auto://:8080
	```
=== "File (YAML)"
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