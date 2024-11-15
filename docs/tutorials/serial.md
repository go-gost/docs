---
comments: true
---

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

## 重定向类型

### 重定向到TCP服务

将本地串口设备`COM1`重定向到`192.168.1.1:8080`TCP服务。

=== "命令行"

	```bash
	gost -L serial://COM1 -F tcp://192.168.1.1:8080
	```

=== "配置文件"

    ```yaml
	services:
	- name: service-0
	  addr: COM1
	  handler:
		type: serial
		chain: chain-0
	  listener:
		type: serial
	chains:
	- name: chain-0
	  hops:
	  - name: hop-0
	    nodes:
		- name: node-0
		  addr: 192.168.1.1:8080
		  connector:
		    type: tcp
		  dialer:
		    type: tcp
	```

### TCP服务重定向到本地串口设备

本地启动TCP服务`localhost:8080`并重定向到本地串口设备`COM1`。

=== "命令行"

	```bash
	gost -L tcp://localhost:8080 -F serial://COM1
	```

=== "配置文件"

    ```yaml
	services:
	- name: service-0
	  addr: localhost:8080
	  handler:
		type: tcp
		chain: chain-0
	  listener:
		type: tcp
	chains:
	- name: chain-0
	  hops:
	  - name: hop-0
	    nodes:
		- name: node-0
		  addr: COM1
		  connector:
		    type: serial
		  dialer:
		    type: serial
	```

### 重定向到本地另外串口设备

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

### 重定向到远程串口设备

将本地串口设备`COM1`通过转发链重定向到远程主机`192.168.1.1`上的串口设备`COM1`。

=== "命令行"

	```bash
	gost -L serial://COM1/COM1 -F relay://192.168.1.1:8420
	```

=== "配置文件"

    ```yaml
	services:
	- name: service-0
	  addr: COM1
	  handler:
		type: serial
		chain: chain-0
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

## 记录数据

可以通过[记录器](../concepts/recorder.md)来记录串口收发的数据。

=== "配置文件"

    ```yaml hl_lines="5 6 7 8 9 10"
	services:
	- name: service-0
	  addr: COM1
	  recorders:
	  - name: recorder-0
	    record: recorder.service.handler.serial
		metadata:
		  direction: true
		  timestampFormat: '2006-01-02 15:04:05.000'
		  hexdump: true
	  handler:
		type: serial
	  listener:
		type: serial
	  forwarder:
	    nodes:
		- name: target-0
		  addr: COM2
	recorders:
	- name: recorder-0
	  file:
	    path: 'C:\\serial.data'
	```

将串口数据记录到`C:\serial.data`文件中，记录的数据格式如下：

```text
>2023-09-18 10:16:25.117
00000000  60 02 a0 01 70 02 b0 01  c0 01 c0 01 40 02 30 01  |`...p.......@.0.|
00000010  e0 00 30 01 50 02 60 01  40 01 30 01 10 02 f0 00  |..0.P.`.@.0.....|
00000020  20 01 60 01 b0 01 f0 00  10 01 f0 00 c0 01 a0 01  | .`.............|
00000030  40 02 b0 01 10 02 60 02  00 00 00 01 50 01 70 01  |@.....`.....P.p.|
00000040  a0 01 30 01 e0 00 e0 01  40 01 00 01 e0 00 c0 01  |..0.....@.......|
00000050  40 01 e0 00 f0 00 20 02  50 01 10 02 10 01 10 02  |@..... .P.......|
00000060  80 01 20 02 30 01 10 02  30 01 00 01 20 01 10 02  |.. .0...0... ...|
<2023-09-18 10:16:25.120
00000000  d0 00 d0 00 10 01 10 02  50 01 e0 00 00 01 d0 01  |........P.......|
00000010  f0 00 10 01 c0 01 40 02  80 01 00 01 20           |......@..... |
```

### 数据记录格式

在记录数据时可以设置记录的数据格式：

`direction` (bool, default=false)
:    标记数据方向，`>`表示源端口发出的数据，`<`表示源端口接收到的数据。

`timestampFormat` (string)
:    指定时间戳格式，当设置后会在每条数据前增加时间戳。

`hexdump` (bool, default=false)
:    以`hexdump -C`命令输出的格式记录数据，默认记录原始字节流。