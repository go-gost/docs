# HTTP/2

名称: `http2`

状态： GA

HTTP2监听器根据服务配置，监听在指定TCP端口，并使用HTTP2协议进行通讯。

=== "命令行"
    ```
	gost -L http2://:8443
	```
=== "配置文件"
    ```yaml
	services:
	- name: service-0
	  addr: ":8443"
	  handler:
		type: http2
	  listener:
		type: http2
	```

## 参数列表

`backlog` (int, default=128)
:    单个连接的数据流队大小

TLS配置请参考[TLS配置说明](/tutorials/tls/)。

!!! note "限制"
    HTTP2监听器只能与[HTTP2处理器](/components/handlers/http2/)一起使用，构建标准HTTP2代理服务。
