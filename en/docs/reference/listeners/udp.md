#UDP

名称: `udp`

状态： Stable

UDP监听器根据服务配置，监听在指定UDP端口。

=== "命令行"
	```
	gost -L ssu+udp://:8388?backlog=128&ttl=60s
	```
=== "配置文件"
    ```yaml
	services:
	- name: service-0
	  addr: ":8388"
	  handler:
		type: ssu
	  listener:
		type: udp
		metadata:
		  backlog: 128
		  ttl: 60s
	```

## 参数列表

`backlog` (int, default=128)
:    UDP连接队列大小

`keepAlive` (bool, default=false)
:    是否保持连接，默认当返回响应数据给客户端后立即断开连接。

`ttl` (duration, default=5s)
:    UDP连接超时时长，当`keepAlive`为`true`时有效。


`readBufferSize` (int, default=1500)
:    UDP读数据缓冲区字节大小

`readQueueSize` (int, default=128)
:    UDP连接读数据队列大小

!!! note "限制"
    UDP监听器目前只能够与[ssu处理器](/reference/handlers/ssu/)组合使用，或与[UDP处理器](/reference/handlers/udp/)组合用做UDP端口转发。