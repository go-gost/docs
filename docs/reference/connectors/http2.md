# HTTP2

名称: `http2`

状态： GA

HTTP2连接器使用标准HTTP2代理协议与服务端进行数据交互。

=== "命令行"
    ```
	gost -L :8000 -F http2://192.168.1.1:8443
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
		  addr: 192.168.1.1:8443
		  connector:
			type: http2
			metadata:
			  header:
			    user-agent: gost/3.0
				foo: bar
		  dialer:
			type: http2
	```

## 参数列表

`header` (map)
:    自定义HTTP请求头

!!! note "限制"
    HTTP2连接器只能与[HTTP2拨号器](/reference/dialers/http2/)一起使用，构建标准HTTP2代理。
