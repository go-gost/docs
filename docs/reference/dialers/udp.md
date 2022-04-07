#UDP

名称: `udp`

状态： Stable

UDP拨号器使用UDP协议建立数据通道。

=== "命令行"
	```
	gost -L :8080 -F ssu+udp://AEAD_CHACHA20_POLY1305:123456@:8338
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
		  addr: :8338
		  connector:
			type: ssu
			auth:
              username: AEAD_CHACHA20_POLY1305
              password: "123456"
		  dialer:
			type: udp
	```

## 参数列表
无

!!! note "限制"
    UDP拨号器目前只能够与[ssu连接器](/reference/connectors/ssu/)组合使用。