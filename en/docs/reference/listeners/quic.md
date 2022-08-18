# QUIC

名称: `quic`

状态： GA

QUIC监听器根据服务配置，监听在指定UDP端口，并使用[QUIC协议](https://github.com/lucas-clemente/quic-go)进行通讯。

=== "命令行"
    ```
	gost -L http+quic://:8443
	```
=== "配置文件"
    ```yaml
	services:
	- name: service-0
	  addr: ":8443"
	  handler:
		type: http
	  listener:
		type: quic 
	```

## 参数列表

`backlog` (int, default=128)
:    单个连接的数据流队大小

`keepAlive` (duration, default=0)
:    心跳间隔时长，默认发送心跳

`handshakeTimeout` (duration, default=5s)
:    握手超时时长

`maxIdleTimeout` (duration, default=30s)
:    最大空闲时长

TLS配置请参考[TLS配置说明](/tutorials/tls/)。