# gRPC

名称: `grpc`

状态： Alpha

GRPC监听器根据服务配置，监听在指定TCP端口，并使用gRPC协议进行通讯。

=== "命令行"
    ```
	gost -L http+grpc://:8443
	```
=== "配置文件"
    ```yaml
	services:
	- name: service-0
	  addr: ":8443"
	  handler:
		type: http
	  listener:
		type: grpc
	```

## 参数列表

`backlog` (int, default=128)
:    请求队列大小

`grpcInsecure` (bool, default=false)
:    开启明文gRPC传输(不使用TLS)

TLS配置请参考[TLS配置说明](/tutorials/tls/)。