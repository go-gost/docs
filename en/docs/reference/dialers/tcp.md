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
:    Enable TCP keep-alive probes on the dialed connection. When enabled, the OS-level TCP keep-alive mechanism detects genuinely dead peers that disappear without sending a TCP RST or FIN, preventing resource leaks from silently-broken connections. Set to `true` to enable.

`keepalive.idle` (time.Duration):
:    The idle time before the first keep-alive probe is sent. Equivalent to `TCP_KEEPIDLE` on Linux. Only effective when `keepalive` is `true`.

`keepalive.interval` (time.Duration):
:    The interval between successive keep-alive probes. Equivalent to `TCP_KEEPINTVL` on Linux. Only effective when `keepalive` is `true`.

`keepalive.count` (int):
:    The number of unacknowledged keep-alive probes before the connection is declared dead. Equivalent to `TCP_KEEPCNT` on Linux. Only effective when `keepalive` is `true`.

