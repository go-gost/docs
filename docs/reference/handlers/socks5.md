# SOCKSv5

处理器名称: `socks`, `socks5`

SOCKS5处理器使用标准SOCKSv5代理协议进行数据交互，接收并处理客户端请求。

=== "命令行"
    ```
	gost -L socks://:1080
	```
=== "配置文件"
    ```yaml
	services:
	- name: service-0
	  addr: ":1080"
	  handler:
		type: socks
	  listener:
		type: tcp
	```

## 参数列表

`readTimeout` (time.Duration)
:    请求数据读取超时时长

`notls` (bool)
:    禁用TLS协商加密扩展协议

`bind` (bool)
:    启用BIND功能，默认不启用

`udp` (bool)
:    启用UDP转发，默认不启用

`udpBufferSize` (int)
:    UDP数据缓冲区字节大小，默认值: 1024

`comp` (bool)
:   兼容模式，当开启后，BIND功能将兼容GOST v2。默认值: false
