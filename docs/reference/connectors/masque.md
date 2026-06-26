# MASQUE

名称： `masque`

状态： Alpha

MASQUE连接器使用MASQUE协议进行数据转发，支持通过CONNECT-UDP (RFC 9298)转发UDP数据，以及通过标准CONNECT转发TCP数据。此连接器必须与[H3-MASQUE拨号器](/reference/dialers/h3-masque/)一起使用。

!!! note "限制"
    MASQUE连接器只能与[H3-MASQUE拨号器](/reference/dialers/h3-masque/)一起使用，构建基于MASQUE协议的UDP/TCP代理服务。

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

`connectTimeout` (duration)
:    连接超时时长。可通过`timeout`或`connectTimeout`指定。
