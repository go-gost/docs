# 多路复用Websocket

监听器名称: `mws`, `mwss`

多路复用Websocket监听器根据服务配置，监听在指定TCP端口，使用Websocket或Websocket Secure(Websocket Over TLS)协议进行通讯，并建立多路复用会话和数据流通道。

## Websocket

=== "命令行"
    ```
	gost -L http+mws://:8080?path=/ws
	```

=== "配置文件"
    ```yaml
	services:
	- name: service-0
	  addr: ":8080"
	  handler:
		type: http
	  listener:
		type: mws
		metadata:
		  path: /ws
		  header:
		    foo: bar
	```

## Websocket Over TLS

=== "命令行"
    ```
	gost -L http+mwss://:8443?path=/ws
	```

=== "配置文件"
    ```yaml
	services:
	- name: service-0
	  addr: ":8443"
	  handler:
		type: http
	  listener:
		type: mwss
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

`muxKeepAliveDisabled`
:    多路复用会话设置。禁用心跳保活，默认值: false

`muxKeepAliveInterval`
:    多路复用会话设置。心跳间隔，默认值: 10s

`muxKeepAliveTimeout`
:    多路复用会话设置。心跳超时，默认值: 30s

`muxMaxFrameSize`
:    多路复用会话设置。最大数据帧大小(字节)，默认值: 32768

`muxMaxReceiveBuffer`
:    多路复用会话设置。最大接收缓冲大小(字节)，默认值: 4194304

`muxMaxStreamBuffer`
:    多路复用会话设置。最大流缓冲大小(字节)，默认值: 65536

TLS证书相关配置请参考[TLS配置说明](/components/tls/)。