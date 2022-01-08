# TLS

监听器名称: `tls`

TLS监听器根据服务配置，监听在指定TCP端口，并使用TLS协议进行通讯。

=== "命令行"
    ```
	gost -L http+tls://:8443?cert=cert.pem&key=key.pem&ca=ca.pem
	```
=== "配置文件"
    ```yaml
	services:
	- name: service-0
	  addr: ":8443"
	  handler:
		type: http
	  listener:
	    tls:
		  cert: cert.pem
		  key: key.pem
		  ca: ca.pem
		type: tls
	```

TLS配置请参考[TLS配置说明](/components/tls/)。