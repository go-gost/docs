#UDP

监听器名称: `udp`

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

`ttl` (duration, default=5s)
:    UDP连接超时时长

`readBufferSize` (int, default=1024)
:    设置UDP读数据缓冲区大小(字节)

`readQueueSize` (int, default=128)
:    设置UDP连接读数据队列大小

!!! note "限制"
    UDP监听器目前只能够与[ssu处理器](/components/handlers/ssu/)组合使用，或与[UDP处理器](/components/handlers/udp/)组合用作UDP端口转发。