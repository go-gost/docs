# OBFS-TLS

监听器名称: `otls`

OBFS监听器根据服务配置，监听在指定TCP端口，并使用TLS协议进行握手。

=== "命令行"
    ```
	gost -L http+otls://:8443
	```
=== "配置文件"
    ```yaml
	services:
	- name: service-0
	  addr: ":8443"
	  handler:
		type: http
	  listener:
		type: otls
	```

## 参数列表

无
