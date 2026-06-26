# MASQUE

名称: `masque`

状态： Alpha

MASQUE处理器基于RFC 9298 (Proxying UDP in HTTP) 和 RFC 9297 (HTTP Datagrams) 协议，通过HTTP/3的扩展CONNECT方法(CONNECT-UDP)转发UDP数据。

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
    MASQUE处理器只能与[HTTP/3监听器](/reference/listeners/http3/)一起使用，且监听器必须开启`enableDatagrams`选项。此协议仅支持UDP转发。

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

TLS配置请参考[TLS配置说明](/tutorials/tls/)。
