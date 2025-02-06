# Relay

Name: `relay`

状态： GA

Relay处理器使用GOST Relay协议进行数据交互，接收并处理客户端请求。

=== "命令行"
    ```
	gost -L relay://:8421
	```
=== "配置文件"
    ```yaml
	services:
	- name: service-0
	  addr: ":8421"
	  handler:
		type: relay
	  listener:
		type: tcp
	```

## 参数列表

`readTimeout` (time.Duration)
:    请求数据读取超时时长

`bind` (bool, default=false)
:    启用BIND功能，默认不启用

`udpBufferSize` (int, default=1500)
:    UDP数据缓冲区字节大小

`nodelay` (bool, default=false)
:    默认情况下relay协议会等待客户端的请求数据，当收到请求数据后会把协议头部信息与请求数据一起发给服务端。当此参数设为true后，协议头部信息会立即发给服务端，不再等待客户端的请求。
