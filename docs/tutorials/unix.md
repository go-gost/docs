# Unix Domain Socket重定向

UDS(Unix Domain Socket)重定向可以将本地的UDS服务重定向到一个TCP服务或另外一个UDS服务，转发链在这种场景下依然有效。

!!! caution "限制"
	当重定向到远程UDS服务时，转发链末端最后一个节点必须使用`relay`协议。

## 重定向类型

### 重定向到TCP服务

本地启动UDS服务`gost.sock`，并重定向到192.168.1.1:80服务。

=== "命令行"

	```bash
	gost -L unix://gost.sock/192.168.1.1:80
	```

=== "配置文件"

    ```yaml
	services:
	- name: service-0
	  addr: gost.sock
	  handler:
		type: unix
	  listener:
		type: unix
	  forwarder:
	    nodes:
		- name: target-0
		  addr: 192.168.1.1:80
	```

### 重定向到本地另外一个UDS服务

本地启动UDS服务`gost.sock`，并重定向到本地的另外一个UDS服务`gost2.sock`。

=== "命令行"

	```bash
	gost -L unix://gost.sock/gost2.sock
	```

=== "配置文件"

    ```yaml
	services:
	- name: service-0
	  addr: gost.sock
	  handler:
		type: unix
	  listener:
		type: unix
	  forwarder:
	    nodes:
		- name: target-0
		  addr: gost2.sock
	```

### 重定向到远程UDS服务

本地启动UDS服务`gost.sock`，通过转发链重定向到远程主机`192.168.1.1`上的UDS服务`gost.sock`。

=== "命令行"

	```bash
	gost -L unix://gost.sock/gost.sock -F relay://192.168.1.1:8420
	```

=== "配置文件"

    ```yaml
	services:
	- name: service-0
	  addr: gost.sock
	  handler:
		type: unix
	  listener:
		type: unix
	  forwarder:
	    nodes:
		- name: target-0
		  addr: gost.sock
	chains:
	- name: chain-0
	  hops:
	  - name: hop-0
		nodes:
		- name: node-0
		  addr: 192.168.1.1:8420
		  connector:
			type: relay
		  dialer:
			type: tcp
	```
