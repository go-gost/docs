# 串口重定向

串口重定向可以将本地的串口设备重定向到一个TCP服务或另外一个串口设备，转发链在这种场景下依然有效。

!!! caution "限制"
	当重定向到远程串口设备时，转发链末端最后一个节点必须使用`relay`协议。

!!! tip "串口地址格式"
    串口地址中可以指定端口名，波特率，奇偶校验，其中波特率和奇偶校验可以省略：`port[,baud[,parity]]`

	波特率默认值为9600。

	奇偶校验类型：`odd` - 奇校验，`even` - 偶校验，`none` - 无校验，默认为无校验。

	* 仅指定端口名
	```
	serial://COM1/COM2
	```

	* 指定端口名和波特率
	```
	serial://COM1,9600/COM2
	```

	* 指定端口名，波特率和奇偶校验
	```
	serial://COM1,9600,odd/COM2
	```

## 重定向到TCP服务

将本地串口设备`COM1`重定向到192.168.1.1:80服务。

=== "命令行"

	```bash
	gost -L serial://COM1/192.168.1.1:80
	```

=== "配置文件"

    ```yaml
	services:
	- name: service-0
	  addr: COM1
	  handler:
		type: serial
	  listener:
		type: serial
	  forwarder:
	    nodes:
		- name: target-0
		  addr: 192.168.1.1:80
	```

## 重定向到本地另外串口设备

将本地串口设备`COM1`重定向到本地的另外一个串口设备`COM2`。

=== "命令行"

	```bash
	gost -L serial://COM1,9600,odd/COM2
	```

=== "配置文件"

    ```yaml
	services:
	- name: service-0
	  addr: COM1,9600,odd
	  handler:
		type: serial
	  listener:
		type: serial
	  forwarder:
	    nodes:
		- name: target-0
		  addr: COM2
	```

## 重定向到远程串口设备

将本地串口设备`COM1`通过转发链重定向到远程主机`192.168.1.1`上的串口设备`COM1`。

=== "命令行"

	```bash
	gost -L unix://COM1/COM2 -F relay://192.168.1.1:8420
	```

=== "配置文件"

    ```yaml
	services:
	- name: service-0
	  addr: COM1
	  handler:
		type: serial
	  listener:
		type: serial
	  forwarder:
	    nodes:
		- name: target-0
		  addr: COM1
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
