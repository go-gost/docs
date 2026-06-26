# TCP

名称: `tcp`

状态： Stable

TCP拨号器使用TCP建立数据通道。

!!! tip "提示"
    TCP拨号器是GOST中默认的拨号器，当不指定拨号器类型时，默认使用此拨号器。

=== "命令行"
    ```
	gost -L :8000 -F http://:8080
	```
	等价于
	```
	gost -L :8000 -F http+tcp://:8080
	```
=== "配置文件"
    ```yaml
    services:
   	- name: service-0
      addr: ":8000"
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
          addr: :8080
          connector:
            type: http
          dialer:
            type: tcp
    ```

## 参数列表

`keepalive` (bool, default=false):
:    启用TCP保活探测。当对端静默断开（如网络分区、主机崩溃）而未发送TCP RST或FIN时，操作系统级别的TCP keep-alive机制能够检测到死连接并关闭，防止静默断开的连接导致资源泄漏。设置为`true`启用。

`keepalive.idle` (time.Duration):
:    发送第一个保活探测前的空闲时间。对应Linux上的`TCP_KEEPIDLE`。仅在`keepalive`为`true`时有效。

`keepalive.interval` (time.Duration):
:    连续保活探测之间的时间间隔。对应Linux上的`TCP_KEEPINTVL`。仅在`keepalive`为`true`时有效。

`keepalive.count` (int):
:    连接被判定为断开前未确认的保活探测次数。对应Linux上的`TCP_KEEPCNT`。仅在`keepalive`为`true`时有效。

