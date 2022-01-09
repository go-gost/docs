# QUIC

监听器名称: `quic`

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

`backlog`
:    单个连接的数据流队大小，默认值: 128

`keepAlive`
:    是否开启心跳, 默认值: false

`handshakeTimeout`
:    握手超时时长, 默认值: 5s

`maxIdleTimeout`
:    最大空闲时长, 默认值: 30s

TLS配置请参考[TLS配置说明](/components/tls/)。