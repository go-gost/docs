# HTTP

Name: `http`

Status： Stable

HTTP处理器使用标准HTTP代理协议进行数据交互，接收并处理客户端的HTTP请求。

=== "CLI"
    ```
	gost -L http://:8080
	```
=== "File (YAML)"
    ```yaml
	services:
	- name: service-0
	  addr: ":8080"
	  handler:
		type: http
		metadata:
		  header:
		    foo: bar
	  listener:
		type: tcp
	```

## 参数列表

`header` (map)
:    自定义HTTP响应头

`probeResistance` (string)
:    探测防御配置

`knock` (string)
:    探测防御配置

`udp` (bool, default=false)
:    是否开启UDP转发
