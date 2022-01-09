# UDP透明代理

监听器名称: `redu`

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

`ttl`
:    传输通道超时时间，默认值: 60s

`readBufferSize`
:    读缓冲区字节大小, 默认值: 1024


!!! note "注意"
    redu监听器只能与[redu处理器](/components/handlers/redu/)一起使用，构建UDP透明代理。

    UDP透明代理仅支持Linux系统。
