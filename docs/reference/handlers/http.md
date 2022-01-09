# HTTP

处理器名称: `http`

HTTP处理器使用标准HTTP代理协议进行数据交互，接收并处理客户端的HTTP请求。

=== "命令行"
    ```
	gost -L http://:8080
	```
=== "配置文件"
    ```yaml
	services:
	- name: service-0
	  addr: ":8080"
	  handler:
		type: http
	  listener:
		type: tcp
	```

## 参数列表

`header`
:    自定义HTTP响应头

`probeResistance`
:    探测防御配置

`knock`
:    探测防御配置

`udp`
:    是否开启UDP转发