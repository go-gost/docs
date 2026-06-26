# TCP

名称: `tcp`

状态： Stable

TCP监听器根据服务配置，监听在指定TCP端口。

!!! tip "提示"
    TCP监听器是GOST中默认的监听器，当不指定监听器类型时，默认使用此监听器。

=== "命令行"
    ```
	gost -L http://:8080
	```
	等价于
	```
	gost -L http+tcp://:8080
	```
=== "配置文件"
    ```yaml
	services:
	- name: service-0
	  addr: ":8080"
	  handler:
		type: http
	  listener:
		type: tcp
	```

## 参数列表

`keepalive` (bool, default=false):
:    Enable TCP keep-alive probes on accepted connections. When a client connects and then silently disappears (e.g. network partition, host crash), the OS-level TCP keep-alive mechanism detects the dead connection and closes it, freeing server-side resources. Set to `true` to enable. This is the primary defense against connection leaks from dead peers in long-lived CONNECT tunnels.

`keepalive.idle` (time.Duration):
:    The idle time before the first keep-alive probe is sent on accepted connections. Equivalent to `TCP_KEEPIDLE` on Linux. Only effective when `keepalive` is `true`.

`keepalive.interval` (time.Duration):
:    The interval between successive keep-alive probes. Equivalent to `TCP_KEEPINTVL` on Linux. Only effective when `keepalive` is `true`.

`keepalive.count` (int):
:    The number of unacknowledged keep-alive probes before the connection is declared dead. Equivalent to `TCP_KEEPCNT` on Linux. Only effective when `keepalive` is `true`.

`reuseport` (bool, default=false):
:    Enable `SO_REUSEPORT` socket option, allowing multiple listeners to bind to the same port for load distribution across processes.

`mptcp` (bool, default=false):
:    Enable Multipath TCP (MPTCP) on the listener, allowing connections to use multiple network paths simultaneously for improved throughput and resilience.

