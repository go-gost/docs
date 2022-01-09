# HTTP2

监听器名称: `http2`

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

`backlog`
:    单个连接的数据流队大小，默认值: 128

TLS配置请参考[TLS配置说明](/components/tls/)。

!!! note "注意"
    HTTP2监听器只能与[HTTP2处理器](/components/handlers/http2/)一起使用，构建标准HTTP2代理。
