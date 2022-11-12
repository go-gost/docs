# KCP

KCP是GOST中的一种数据通道类型。KCP的实现依赖于[xtaci/kcp-go](https://github.com/xtaci/kcp-go)库。

## 示例

=== "命令行"

    ```
	gost -L http+kcp://:8443?c=/path/to/config/file
	```

=== "配置文件"

    ```yaml
	services:
	- name: service-0
	  addr: ":8443"
	  handler:
		type: http
	  listener:
		type: kcp
		metadata:
		  c: /path/to/config/file
	```