# TCP Redirect

Name: `red`, `redir`, `redirect`

Status： GA

RED处理器用于构建TCP透明代理。

=== "CLI"
	```bash
	gost -L red://:8080
	```
=== "File (YAML)"
    ```yaml
	services:
	- name: service-0
	  addr: :8080
	  handler:
		type: red
	  listener:
		type: red
	```

## 参数列表

`sniffing` (bool, default=false)
:    开启流量嗅探，开启后对HTTP和TLS流量进行识别，识别后将使用HTTP `Host`头部信息或TLS的SNI扩展信息作为目标访问地址。

`sniffing.dialOriginalDst` (bool, default=false) :material-tag: 3.3.0
:    Dial the original transparent-redirect destination address instead of the sniffed hostname. The sniffed hostname is still used for routing decisions such as bypass matching, but the actual connection is made to the original destination. Useful when the resolved address of the SNI differs from the original destination.

`tproxy` (bool, default=false)
:   开启tproxy模式

!!! note "tproxy模式"
    tproxy模式需要`red`监听器和处理器同时开启。

!!! note "限制"
    RED处理器只能与[RED监听器](/reference/listeners/red/)一起使用，构建TCP透明代理。

