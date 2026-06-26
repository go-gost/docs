# MASQUE

名称: `masque`

状态： Alpha

MASQUE处理器基于RFC 9298 (Proxying UDP in HTTP) 和 RFC 9297 (HTTP Datagrams) 协议，支持两种转发模式：

- **CONNECT-UDP**：通过HTTP/3的扩展CONNECT方法转发UDP数据（RFC 9298）。
- **CONNECT-TCP**：通过HTTP/3 Stream进行标准TCP隧道转发。

处理器根据请求的`:protocol`伪头部自动选择转发模式。

!!! tip "默认监听器"
    当不指定监听器时，MASQUE处理器默认使用HTTP/3作为监听器。由于MASQUE协议依赖HTTP/3的数据报(Datagram)功能，监听器需要开启`enableDatagrams`选项。

=== "命令行"
    ```
	gost -L masque://:8443
	```
	等同于
	```
	gost -L masque+h3://:8443
	```

=== "配置文件"
    ```yaml
	services:
	- name: service-0
	  addr: ":8443"
	  handler:
		type: masque
	  listener:
		type: h3
		enableDatagrams: true
	```

!!! note "限制"
    MASQUE处理器只能与[HTTP/3监听器](/reference/listeners/http3/)一起使用。CONNECT-UDP模式需要监听器开启`enableDatagrams`选项。

## 参数列表

`bufferSize` (int, default=4096)
:    UDP数据缓冲大小

`hash` (string)
:    访问密钥，当设置后将根据`hash`值进行简单的权限校验。客户端需要在请求路径中包含正确的hash值。

`authBasicRealm` (string)
:    基本认证域名

`observePeriod` (duration, default=5s)
:    观测周期，用于定期上报流量统计。

`observer.resetTraffic` (bool, default=false)
:    观测流量统计重置。

`limiter.refreshInterval` (duration)
:    限流器刷新间隔。

`limiter.cleanupInterval` (duration)
:    限流器清理间隔。

`idleTimeout` (duration)
:    TCP连接空闲超时。当TCP双向转发在此时长内无数据传输时，连接将被关闭。可通过`idleTimeout`或`readTimeout`指定。

TLS配置请参考[TLS配置说明](/tutorials/tls/)。
