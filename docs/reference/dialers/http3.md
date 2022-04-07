# HTTP/3

名称: `http3`

状态： Alpha

HTTP3拨号器使用HTTP/3协议与HTTP3服务建立数据通道。

=== "命令行"
    ```
	gost -L :8080 -F http+http3://:8443
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
			type: http3
	```

## 参数列表

`host` (string)
:    指定HTTP请求`Host`头部字段值

`authorizePath` (string, default=/authorize)
:    用户授权接口URI

`pushPath` (string, default=/push)
:    数据发送URI

`pullPath` (string, default=/pull)
:   数据接收URI

TLS配置请参考[TLS配置说明](/tutorials/tls/)。
