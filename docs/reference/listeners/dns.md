# DNS

监听器名称: `dns`

DNS监听器根据服务配置，监听在指定TCP或UDP端口，并使用DNS协议进行通讯。

=== "命令行"
    ```
	gost -L dns://:10053?mode=udp&dns=1.1.1.1:53
	```
=== "配置文件"
    ```yaml
	services:
	- name: service-0
	  addr: ":10053"
	  handler:
		type: dns
	  listener:
		type: dns
		metadata:
		  mode: udp
		  dns: 1.1.1.1:53
	```

## 参数列表

`backlog`
:    请求队列大小，默认值: 128

`mode`
:    运行模式, 可选值: `udp`, `tcp`, `tls`, `https`, 默认值: `udp`

`readBufferSize`
:    读缓冲区字节大小, 当mode=udp时有效, 默认值: 512

`readTimeout`
:    读数据超时时长, 默认值: 2s

`writeTimeout`
:    写数据超时时长, 默认值: 2s

!!! note "注意"
    DNS监听器只能与[DNS处理器](/components/handlers/dns/)一起使用，构建DNS代理服务。
