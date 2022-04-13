# ICMP

名称: `icmp`

状态： Alpha

ICMP监听器采用ICMP协议进行数据传输。

=== "命令行"
    ```
	gost -L http+icmp://:0?keepAlive=true
	```
=== "配置文件"
    ```yaml
	services:
	- name: service-0
	  addr: ":8443"
	  handler:
		type: http
	  listener:
		type: icmp
		metadata:
		  keepAlive: true
	```

## 参数列表

`backlog` (int, default=128)
:    单个连接的数据流队大小

`keepAlive` (bool, default=false)
:    是否开启心跳

`handshakeTimeout` (duration, default=5s)
:    握手超时时长

`maxIdleTimeout` (duration, default=30s)
:    最大空闲时长
