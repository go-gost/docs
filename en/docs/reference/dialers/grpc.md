# gRPC

名称: `grpc`

状态： Alpha

GRPC拨号器使用gRPC协议与gRPC服务建立数据通道。

=== "命令行"
    ```
	gost -L :8080 -F http+grpc://:8443
	```
=== "配置文件"
    ```yaml
	services:
	- name: service-0
	  addr: ":8080"
	  handler:
		type: auto
		chain: chain-0
	  listener:
		type: tcp
	chains:
	- name: chain-0
	  hops:
	  - name: hop-0
		nodes:
		- name: node-0
		  addr: :8443
		  connector:
			type: http
		  dialer:
			type: grpc
    ```

## 参数列表

`host` (string)
:    指定gRPC请求`:authority`头部字段值

`grpcInsecure` (bool, default=false)
:    开启明文gRPC传输(不使用TLS)

TLS配置请参考[TLS配置说明](/tutorials/tls/)。