# HTTP

名称: `http`

状态： Stable

HTTP处理器使用标准HTTP代理协议进行数据交互，接收并处理客户端的HTTP请求。

=== "命令行"
    ```
	gost -L http://:8080
	```
=== "配置文件"
    ```yaml
	services:
	- name: service-0
	  addr: ":8080"
	  handler:
		type: http
		metadata:
		  header:
		    foo: bar
	  listener:
		type: tcp
	```

## 参数列表

`readTimeout` (time.Duration, default=15s):
:    上游HTTP响应头读取超时时间。默认值0表示使用15秒超时，设置为负值禁用超时。

`idleTimeout` (time.Duration, default=0):
:    CONNECT隧道转发管道的空闲读超时。CONNECT隧道建立后，数据在客户端与上游之间双向转发。当`idleTimeout`设置为正值时，每个方向都会应用读截止时间：如果在超时时间内没有应用层数据流动，连接将被终止，以防止静默断开的对端导致资源泄漏。设置为0或负值禁用超时，允许长时间空闲的长连接（如WebSocket、长轮询HTTP、慢速响应等场景）。

`header` (map):
:    自定义HTTP响应头。

`keepalive` (bool):
:    是否启用HTTP长连接。设置为`true`启用持久连接。

`compression` (bool):
:    是否启用HTTP响应压缩（gzip）。设置为`true`启用压缩。

`probeResist` (string):
:    探测防御配置，格式为`"type:value"`。支持的类型：`"code"`（HTTP状态码，如`"code:404"`）、`"web"`（代理目标URL）、`"host"`（主机地址）、`"file"`（响应体文件路径）。当认证失败时，返回伪装响应而非`407 Proxy-Auth-Required`，使端口看起来运行的是其他服务。

`knock` (string):
:    逗号分隔的探测防御豁免主机名列表。仅当与`probeResist`一起使用时有效，匹配的主机名将绕过探测防御。

`udp` (bool, default=false):
:    是否开启UDP转发（UDP-over-TCP）。设置为`true`允许通过HTTP代理转发UDP流量。

`udpBufferSize` (int):
:    UDP中继缓冲区字节大小。

`authBasicRealm` (string, default="gost"):
:    HTTP基本认证的`WWW-Authenticate`响应头中的Realm值。

`proxyAgent` (string, default="gost/3.0"):
:    HTTP处理器发送的`Proxy-Agent`响应头的值。

`hash` (string):
:    节点选择策略。设置为`"host"`时使用基于请求主机名的一致性哈希，确保同一主机名选择同一上游节点。

`observePeriod` (time.Duration, default=5s):
:    流量观测统计上报间隔。默认5秒，最小值为1秒。

`observer.resetTraffic` (bool):
:    是否在每次观测后重置流量计数器。

`sniffing` (bool):
:    启用CONNECT隧道协议嗅探，检测隧道内的HTTP或TLS流量进行协议感知转发。

`sniffing.timeout` (time.Duration):
:    CONNECT隧道初始嗅探读取的超时时间。

`sniffing.websocket` (bool):
:    是否在嗅探时启用WebSocket帧记录。

`sniffing.websocket.sampleRate` (float64):
:    每秒最多记录的WebSocket帧数。

`mitm.certFile` / `mitm.keyFile` (string):
:    用于TLS中间人解密的CA证书和私钥文件路径。两者均需提供才能启用MITM模式。

`mitm.alpn` (string):
:    MITM TLS终止时协商的ALPN协议。

`mitm.bypass` (string):
:    用于跳过MITM解密的旁路匹配器名称。

`limiterRefreshInterval` (time.Duration):
:    限速器条目刷新间隔。

`limiterCleanupInterval` (time.Duration):
:    已过期限速器条目的清理间隔。