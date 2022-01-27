# Shadowsocks UDP Relay

处理器名称: `ssu`

状态：Stable

ssu处理器使用Shadowsocks UDP转发协议进行数据交互，用于转发UDP数据。

=== "命令行"
    ```
	gost -L ssu://AEAD_CHACHA20_POLY1305:123456@:8338
	```
=== "配置文件"
    ```yaml
	services:
	- name: service-0
	  addr: ":8338"
	  handler:
		type: ssu
		auths:
		- username: AEAD_CHACHA20_POLY1305
		  password: "123456"
	  listener:
		type: udp
	```

## 参数列表

`bufferSize` (int, default=1024)
:    UDP数据缓冲大小