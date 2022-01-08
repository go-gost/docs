# Websocket

监听器名称: `ws`, `wss`

Websocket监听器根据服务配置，监听在指定TCP端口，并使用Websocket或Websocket Secure(Websocket Over TLS)协议进行通讯。

## Websocket

=== "命令行"
    ```
	gost -L http+ws://:8080?path=/ws
	```

=== "配置文件"
    ```yaml
	services:
	- name: service-0
	  addr: ":8080"
	  handler:
		type: http
	  listener:
		type: ws
		metadata:
		  path: /ws
		  header:
		    foo: bar
	```

## Websocket Over TLS

=== "命令行"
    ```
	gost -L http+wss://:8443?path=/ws
	```

=== "配置文件"
    ```yaml
	services:
	- name: service-0
	  addr: ":8443"
	  handler:
		type: http
	  listener:
		type: wss
		metadata:
		  path: /ws
		  header:
		    foo: bar
	```

## 参数列表

`path`
:    请求URI, 默认值: /ws

`backlog`
:    请求队列大小，默认值: 128

`header`
:    自定义HTTP响应头

`handshakeTimeout`
:    设置握手超时时长

`readHeaderTimeout`
:    设置请求头读取超时时长

`readBufferSize`
:    读缓冲区大小

`writeBufferSize`
:    写缓冲区大小

`enableCompression`
:    开启压缩, 默认值: false


TLS证书相关配置请参考[TLS配置说明](/components/tls/)。