# Forward

名称： `forward`

状态： Stable

forward连接器不做任何逻辑处理，用于配合数据转发通道使用。

=== "命令行"
    服务端
	```
	gost -L tls://:8443/192.168.1.1:80
	```
	客户端
    ```
	gost -L tcp://:8000 -F forward+tls://:8443
	```

=== "配置文件"
    ```yaml
	services:
	- name: service-0
	  addr: ":8000"
	  handler:
		type: tcp
		chain: chain-0
	  listener:
		type: tcp
	chains:
	- name: chain-0
	  hops:
	  - name: hop-0
		nodes:
		- name: node-0
		  addr: :8443
		  connector:
			type: forward
		  dialer:
			type: tls
	```

客户端将8000端口收到的数据通过TLS通道发送给服务端，再由服务端转发给192.168.1.1:80，数据中转目标地址由服务端控制。