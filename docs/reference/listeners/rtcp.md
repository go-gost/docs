# TCP远程端口转发

名称: `rtcp`

状态： Stable

RTCP监听器根据服务配置，监听在指定的本地或远程(通过转发链)TCP端口。

## 不使用转发链

=== "命令行"
    ```
	gost -L=rtcp://:2222/:22
	```
=== "配置文件"
    ```yaml
	services:
	- name: service-0
	  addr: ":2222"
	  handler:
		type: rtcp
	  listener:
		type: rtcp
	  forwarder:
	    nodes:
		- name: target-0
		  addr: :22
	```

## 使用转发链

=== "命令行"
    ```
	gost -L=rtcp://:2222/192.168.1.1:22 -F socks5://192.168.1.2:1080
	```
=== "配置文件"
    ```yaml
	services:
	- name: service-0
	  addr: ":2222"
	  handler:
		type: rtcp
	  listener:
		type: rtcp
		chain: chain-0
	  forwarder:
	    nodes:
		- name: target-0
		  addr: 192.168.1.1:22
	chains:
	- name: chain-0
	  hops:
	  - name: hop-0
		nodes:
		- name: node-0
		  addr: 192.168.1.2:1080
		  connector:
			type: socks5
		  dialer:
			type: tcp
	```
	
## 参数列表

无

!!! note "限制"
    RTCP监听器只能与[RTCP处理器](/reference/handlers/rtcp/)一起使用，构建TCP远程端口转发服务。
