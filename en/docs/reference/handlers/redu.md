# UDP透明代理

Name: `redu`

Status： GA

REDU处理器用于构建基于tproxy的UDP透明代理。

=== "CLI"
	```bash
	gost -L redu://:8080
	```
=== "File (YAML)"
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