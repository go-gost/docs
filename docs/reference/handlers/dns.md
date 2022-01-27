# DNS

处理器名称: `dns`

状态：Stable

DNS处理器使用接收DNS查询请求并返回DNS查询结果。

=== "命令行"
    ```
	gost -L dns://:10053?dns=1.1.1.1:53
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

`dns` (strings, default=udp://127.0.0.1:53)
:    上级DNS服务列表

`ttl` (duration, default=0s)
:    DNS缓存超时时长，默认使用DNS查询结果中的时长。如果设置为负值，则禁用缓存。

`clientIP` (string)
:    客户端IP，设置后会开启ECS(EDNS Client Subnet)扩展功能。

!!! note "限制"
    DNS处理器只能与[DNS监听器](/components/listeners/dns/)一起使用，构建DNS代理服务。



