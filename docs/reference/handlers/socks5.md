# SOCKSv5

处理器名称: `socks`, `socks5`

状态：Stable

SOCKS5处理器使用SOCKSv5代理协议进行数据交互，接收并处理客户端请求。

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

`readTimeout` (duration)
:    请求数据读取超时时长

`notls` (bool, default=false)
:    禁用TLS协商加密扩展协议

`bind` (bool, default=false)
:    启用BIND功能

`udp` (bool, default=false)
:    启用UDP转发

`udpBufferSize` (int, default=1024)
:    UDP数据缓冲区字节大小

`comp` (bool, default=false)
:   兼容模式，当开启后，BIND功能将兼容GOSTv2
