# Fake TCP

监听器名称: `ftcp`

状态： Alpha

FTCP使用[tcpraw](github.com/xtaci/tcpraw)模拟TCP协议。

=== "命令行"
    ```
	gost -L http+ftcp://:8443
	```
=== "配置文件"
    ```yaml
	services:
	- name: service-0
	  addr: ":8443"
	  handler:
		type: http
	  listener:
		type: ftcp
	```

## 参数列表

`backlog` (int, default=128)
:    请求队列大小

`ttl` (duration, default=5s)
:    UDP连接超时时长

`readBufferSize` (int, default=1500)
:    UDP读数据缓冲区字节大小

`readQueueSize` (int, default=128)
:    UDP连接读数据队列大小

