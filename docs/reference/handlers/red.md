# TCP Redirect

处理器名称: `red`

状态： GA

RED处理器用于构建TCP透明代理。

=== "命令行"
	```bash
	gost -L red://:8080
	```
=== "配置文件"
    ```yaml
	services:
	- name: service-0
	  addr: :8080
	  handler:
		type: red
	  listener:
		type: tcp
	```

## 参数列表

无

!!! note "限制"
    RED处理器只能与[TCP监听器](/reference/listeners/tcp/)一起使用，构建TCP透明代理。

