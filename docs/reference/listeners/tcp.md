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
:    在接受的新连接上启用TCP保活探测。当客户端连接后静默断开（如网络分区、主机崩溃），操作系统级别的TCP keep-alive机制能够检测到死连接并关闭，释放服务端资源。设置为`true`启用。这是防止长连接CONNECT隧道中死连接泄漏的主要手段。

`keepalive.idle` (time.Duration):
:    在接受连接上发送第一个保活探测前的空闲时间。对应Linux上的`TCP_KEEPIDLE`。仅在`keepalive`为`true`时有效。

`keepalive.interval` (time.Duration):
:    连续保活探测之间的时间间隔。对应Linux上的`TCP_KEEPINTVL`。仅在`keepalive`为`true`时有效。

`keepalive.count` (int):
:    连接被判定为断开前未确认的保活探测次数。对应Linux上的`TCP_KEEPCNT`。仅在`keepalive`为`true`时有效。

`reuseport` (bool, default=false):
:    启用`SO_REUSEPORT`套接字选项，允许多个监听器绑定到同一端口，实现多进程负载分发。

`mptcp` (bool, default=false):
:    启用多路径TCP（Multipath TCP），允许连接同时使用多个网络路径传输数据，提升吞吐量和可靠性。

