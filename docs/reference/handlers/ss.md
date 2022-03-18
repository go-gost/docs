# Shadowsocks

处理器名称: `ss`

状态： Stable

SS处理器使用Shadowsocks协议进行数据交互，接收并处理客户端请求。

=== "命令行"
    ```
	gost -L ss://AEAD_CHACHA20_POLY1305:123456@:8338
	```
=== "配置文件"
    ```yaml
	services:
	- name: service-0
	  addr: ":8338"
	  handler:
		type: ss
		auth:
		  username: AEAD_CHACHA20_POLY1305
		  password: "123456"
	  listener:
		type: tcp
	```

## 参数列表

`readTimeout` (duration)
:    请求数据读取超时时长


!!! note "认证信息"
    SS理器只能使用单认证信息方式设置加密信息，不能支持认证器。