# HTTP

名称: `http`

状态： Stable

HTTP连接器使用标准HTTP代理协议与服务端进行数据交互。

!!! tip "提示"
	HTTP连接器是GOST中默认的连接器，当不指定连接器类型时，默认使用此连接器。

=== "命令行"
    ```
	gost -L :8000 -F 192.168.1.1:8080
	```
	等同于
	```
	gost -L :8000 -F http://192.168.1.1:8080
	```

=== "配置文件"
    ```yaml
	services:
	- name: service-0
	  addr: ":8000"
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
		  addr: 192.168.1.1:8080
		  connector:
			type: http
			metadata:
			  header:
			    user-agent: gost/3.0
				foo: bar
		  dialer:
			type: tcp
	```

## 参数列表

`header` (map)
:    自定义HTTP请求头