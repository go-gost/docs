# DNS

名称: `dns`

状态： GA

DNS监听器根据服务配置，监听在指定TCP或UDP端口，并使用DNS协议进行通讯。

=== "命令行"
    ```
	gost -L dns://:10053?mode=udp
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
	```

## 参数列表

`backlog` (int, default=128)
:    请求队列大小

`mode` (string, default=udp)
:    运行模式:

     * `udp` - UDP协议
     * `tcp` - TCP协议
     * `tls` - DNS-over-TLS(DoT)
     * `https` - DNS-over-HTTPS(DoH)

`readBufferSize` (int, default=512)
:    读缓冲区字节大小, 当mode=udp时有效

`readTimeout` (duration, default=2s)
:    读数据超时时长

`writeTimeout` (duration, default=2s)
:    写数据超时时长

!!! note "限制"
    DNS监听器只能与[DNS处理器](/reference/handlers/dns/)一起使用，构建DNS代理服务。
