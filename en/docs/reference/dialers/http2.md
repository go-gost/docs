# HTTP/2

名称: `http2`

状态： GA

HTTP2拨号器使用HTTP/2协议与HTTP2服务建立数据通道。

=== "命令行"
    ```
	gost -L :8080 -F http2://:8443
	```
=== "配置文件"
    ```yaml
	services:
	- name: service-0
	  addr: ":8000"
	  handler:
		type: auto
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
			type: http2
		  dialer:
			type: http2
	```

## 参数列表
无

!!! note "限制"
    HTTP2拨号器只能与[HTTP2连接器](/reference/connectors/http2/)一起使用，构建标准HTTP2代理。
