# HTTP/3

名称: `http3`

状态： Alpha

HTTP3监听器根据服务配置，监听在指定UDP端口，并使用HTTP/3协议进行数据传输。

=== "命令行"
    ```
	gost -L http+http3://:8080
	```
=== "配置文件"
    ```yaml
	services:
	- name: service-0
	  addr: ":8080"
	  handler:
		type: http
	  listener:
		type: http3
	```

## 参数列表

`backlog` (int, default=128)
:    请求队列大小

`authorizePath` (string, default=/authorize)
:    用户授权接口URI

`pushPath` (string, default=/push)
:    数据发送URI

`pullPath` (string, default=/pull)
:   数据接收URI

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
