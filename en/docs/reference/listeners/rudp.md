# UDP远程端口转发

名称: `udp`

状态： Stable

RUDP监听器根据服务配置，监听在指定的本地或远程(通过转发链)UDP端口。

## 不使用转发链

=== "命令行"
    ```
	gost -L=rudp://:10053/192.168.1.1:53
	```
=== "配置文件"
    ```yaml
	services:
	- name: service-0
	  addr: ":10053"
	  handler:
		type: rudp
	  listener:
		type: rudp
	  forwarder:
	    targets:
		- 192.168.1.1:53
	```

## 使用转发链

=== "命令行"
    ```
	gost -L=rtcp://:10053/192.168.1.1:53 -F socks5://192.168.1.2:1080
	```
=== "配置文件"
    ```yaml
	services:
	- name: service-0
	  addr: ":10053"
	  handler:
		type: rudp
	  listener:
		type: rudp
		chain: chain-0
	  forwarder:
	    targets:
		- 192.168.1.1:53
	chains:
	- name: chain-0
	  hops:
	  - name: hop-0
		nodes:
		- name: node-0
		  addr: 192.168.1.2:1080
		  connector:
			type: socks5
		  dialer:
			type: tcp
	```
	
## 参数列表

`backlog` (int, default=128)
:    请求队列长度

`ttl` (duration, default=5s)
:    每个客户端通道超时时长

`readQueueSize` (int, default=128)
:    数据读取队列长度

`readBufferSize` (int, default=1500)
:    数据读取缓冲区字节大小

!!! note "限制"
    RUDP监听器只能与[RUDP处理器](/components/handlers/rudp/)一起使用，构建UDP远程端口转发服务。
