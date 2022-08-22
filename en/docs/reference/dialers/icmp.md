# ICMP

名称: `icmp`

状态： Alpha

ICMP拨号器使用ICMP协议建立数据通道。

=== "命令行"
    ```
	gost -L :8080 -F http+icmp://:12345
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
		  addr: :12345
		  connector:
			type: http
		  dialer:
			type: icmp
	```

## 参数列表

`keepAlive` (bool, default=false)
:    enable keepalive.

`ttl` (duration, default=10s)
:    keepalive period.

`handshakeTimeout` (duration, default=5s)
:    handshake timeout

`maxIdleTimeout` (duration, default=30s)
:    max idle timeout
