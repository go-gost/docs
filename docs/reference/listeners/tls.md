# TLS

名称: `tls`

状态： Stable

TLS监听器根据服务配置，监听在指定TCP端口，并使用TLS协议进行通讯。

=== "命令行"
    ```
	gost -L http+tls://:8443
	```
=== "配置文件"
    ```yaml
	services:
	- name: service-0
	  addr: ":8443"
	  handler:
		type: http
	  listener:
		type: tls
	```

## 参数列表

无

TLS配置请参考[TLS配置说明](/tutorials/tls/)。