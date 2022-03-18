# UDP透明代理

监听器名称: `redu`

状态： GA

UDP透明代理基于iptables的tproxy模块实现。

=== "命令行"
    ```
	gost -L redu://:12345
	```
=== "配置文件"
    ```yaml
	services:
	- name: service-0
	  addr: ":12345"
	  handler:
		type: redu
	  listener:
		type: redu
	```

## 参数列表

`ttl` (duration, default=60s)
:    传输通道超时时长

`readBufferSize` (duration, default=1024)
:    读缓冲区字节大小


!!! note "限制"
    redu监听器只能与[redu处理器](/reference/handlers/redu/)一起使用，构建UDP透明代理。

    UDP透明代理仅支持Linux系统。
