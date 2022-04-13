# HTTP2

名称: `http2`

状态： GA

HTTP2处理器使用HTTP2协议进行数据交互，接收并处理客户端请求。

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

`header` (map)
:    自定义HTTP响应头

`probeResistance` (string)
:    探测防御配置

`knock` (string)
:    探测防御配置

!!! note "限制"
    HTTP2处理器只能与[HTTP2监听器](/reference/listeners/http2/)一起使用，构建标准HTTP2代理。


