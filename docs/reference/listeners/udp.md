#UDP

监听器名称: `udp`

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

`backlog`
:    UDP连接队列大小，默认值: 128

`ttl`
:    UDP连接超时时间，默认值: 5s

`readBufferSize`
:    设置UDP读数据缓冲区大小(字节), 默认值: 1024

`readQueueSize`
:    设置UDP连接读数据队列大小, 默认值: 128

!!! note "注意"
    UDP监听器的使用有一定的限制，目前只能够与[ssu处理器](/components/handlers/ssu/)组合使用，或用作UDP端口转发。