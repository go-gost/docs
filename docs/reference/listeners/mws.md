# 多路复用Websocket

监听器名称: `mws`, `mwss`

状态：Stable

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

`path` (string, default=/ws)
:    请求URI

`backlog` (int, default=128)
:    请求队列大小

`header` (map)
:    自定义HTTP响应头

`handshakeTimeout` (duration)
:    设置握手超时时长

`readHeaderTimeout` (duration)
:    设置请求头读取超时时长

`readBufferSize` (int)
:    读缓冲区大小

`writeBufferSize` (int)
:    写缓冲区大小

`enableCompression` (bool, default=false)
:    开启压缩

`muxKeepAliveDisabled` (bool, default=false)
:    多路复用会话设置。禁用心跳保活

`muxKeepAliveInterval` (duration, default=10s)
:    多路复用会话设置。心跳间隔，默认值: 10s

`muxKeepAliveTimeout` (duration, default=30s)
:    多路复用会话设置。心跳超时

`muxMaxFrameSize` (int, default=32768)
:    多路复用会话设置。最大数据帧大小(字节)

`muxMaxReceiveBuffer` (int, default=4194304)
:    多路复用会话设置。最大接收缓冲大小(字节)

`muxMaxStreamBuffer` (int, default=65536)
:    多路复用会话设置。最大流缓冲大小(字节)

TLS证书相关配置请参考[TLS配置说明](/components/tls/)。