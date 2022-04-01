# TCP透明代理

名称: `red`, `redir`, `redirect`

状态： GA

TCP透明代理基于REDIRECT和tproxy模块实现。

=== "命令行"
    ```
	gost -L red://:12345
	```
=== "配置文件"
    ```yaml
	services:
	- name: service-0
	  addr: ":12345"
	  handler:
		type: red
	  listener:
		type: red
	```

## 参数列表

`tproxy` (bool, default=false)
:   开启tproxy模式

!!! note "tproxy模式"
    tproxy模式需要`red`监听器和处理器同时开启。

!!! note "限制"
    red监听器只能与[red处理器](/reference/handlers/red/)一起使用，构建TCP透明代理。

    TCP透明代理仅支持Linux系统。
