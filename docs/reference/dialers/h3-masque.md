# H3-MASQUE

名称: `h3-masque`

状态： Alpha

H3-MASQUE拨号器使用QUIC协议建立HTTP/3连接，并通过HTTP/3的数据报(Datagram)功能进行UDP数据转发。

H3-MASQUE拨号器支持多路复用，通过连接池复用QUIC连接以提升性能。

!!! note "限制"
    H3-MASQUE拨号器只能与[MASQUE连接器](/reference/connectors/masque/)一起使用，构建基于MASQUE协议(RFC 9298)的UDP代理服务。

=== "命令行"
    ```
	gost -L :8080 -F masque+h3-masque://:8443
	```

=== "配置文件"
    ```yaml
	services:
	- name: service-0
	  addr: ":8080"
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
		  addr: :8443
		  connector:
			type: masque
		  dialer:
			type: h3-masque
	```

## 参数列表

`host` (string)
:    指定HTTP请求`Host`头部字段值

`keepAlive` (bool, default=false)
:    开启心跳检测。

`ttl` (duration, default=10s)
:    心跳间隔时长，当`keepAlive`为true时有效。

`handshakeTimeout` (duration, default=5s)
:    握手超时时长

`maxIdleTimeout` (duration, default=30s)
:    最大空闲时长

`maxStreams` (int, default=100)
:    最大并发stream数量

TLS配置请参考[TLS配置说明](/tutorials/tls/)。
