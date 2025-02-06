# Shadowsocks UDP Relay

Name: `ssu`

状态： Stable

ssu处理器使用Shadowsocks UDP转发协议进行数据交互，用于转发UDP数据。

!!! tip "默认监听器"
    当不指定监听器时，SSU处理器默认使用UDP作为监听器。当然你也可以指定其他兼容类型的监听器(例如TCP, TLS等)。

=== "命令行"
    ```
	gost -L ssu://AEAD_CHACHA20_POLY1305:123456@:8338
	```
	等同于
	```
	gost -L ssu+udp://AEAD_CHACHA20_POLY1305:123456@:8338
	```
=== "配置文件"
    ```yaml
	services:
	- name: service-0
	  addr: ":8338"
	  handler:
		type: ssu
		auth:
		  username: AEAD_CHACHA20_POLY1305
		  password: "123456"
	  listener:
		type: udp
	```

## 参数列表

`bufferSize` (int, default=1500)
:    UDP数据缓冲大小

!!! note "认证信息"
    SSU理器只能使用单认证信息方式设置加密信息，不能支持认证器。