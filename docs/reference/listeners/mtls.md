# 多路复用TLS

监听器名称: `mtls`

状态：Stable

多路复用TLS监听器根据服务配置，监听在指定TCP端口，使用TLS协议进行通讯，并建立多路复用会话和数据流通道。

=== "命令行"
    ```
	gost -L http+mtls://:8443
	```
=== "配置文件"
    ```yaml
	services:
	- name: service-0
	  addr: ":8443"
	  handler:
		type: http
	  listener:
	    tls:
		  cert: cert.pem
		  key: key.pem
		  ca: ca.pem
		type: mtls
	```

## 参数列表

`backlog` (int, default=128)
:    设置单个连接的数据流队大小

`muxKeepAliveDisabled` (bool, default=false)
:    多路复用会话设置。禁用心跳保活

`muxKeepAliveInterval` (duration, default=10s)
:    多路复用会话设置。心跳间隔

`muxKeepAliveTimeout` (duration, default=30s)
:    多路复用会话设置。心跳超时

`muxMaxFrameSize` (int, default=32768)
:    多路复用会话设置。最大数据帧大小(字节)

`muxMaxReceiveBuffer` (int, default=4194304)
:    多路复用会话设置。最大接收缓冲大小(字节)

`muxMaxStreamBuffer` (int, default=65536)
:    多路复用会话设置。最大流缓冲大小(字节)


TLS证书相关配置请参考[TLS配置说明](/components/tls/)。