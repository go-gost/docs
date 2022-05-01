# SNI

名称： `sni`

状态： GA

=== "命令行"
    ```
	gost -L :8000 -F sni://:8080
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
		  addr: :8080
		  connector:
			type: sni
		  dialer:
			type: tcp
	```

## 参数列表

`host` (string)
:    Host别名

## Host混淆

SNI客户端可以通过`host`参数来指定Host别名

```
gost -L :8000 -F sni://:8080?host=example.com
```

SNI客户端会将TLS握手或HTTP请求头中的Host替换为`host`参数指定的内容。
