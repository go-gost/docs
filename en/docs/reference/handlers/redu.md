# UDP透明代理

名称: `redu`

状态： GA

REDU处理器用于构建基于tproxy的UDP透明代理。

=== "命令行"
	```bash
	gost -L redu://:8080
	```
=== "配置文件"
    ```yaml
	services:
	- name: service-0
	  addr: :8080
	  handler:
		type: redu
	  listener:
		type: redu
	```

## 参数列表

无

!!! note "限制"
    REDU处理器只能与[REDU监听器](/reference/listeners/redu/)一起使用，构建UDP透明代理。