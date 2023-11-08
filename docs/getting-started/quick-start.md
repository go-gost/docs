# 快速开始

!!!tip "零配置"
    GOST可以通过命令行参数直接开启一个或多个服务，无需额外的配置文件。

## 代理模式

开启一个或多个代理服务，并可以设置转发链进行转发。

### 开启一个HTTP代理服务

=== "命令行"

    ```sh
	gost -L http://:8080
	```

=== "配置文件"

    ```yaml
	services:
	- name: service-0
	  addr: ":8080"
	  handler:
		type: http
	  listener:
		type: tcp
	```

启动一个监听在8080端口的HTTP代理服务。

### 开启多个代理服务

=== "命令行"

    ```bash
    gost -L http://:8080 -L socks5://:1080 
	```

=== "配置文件"

    ```yaml
	services:
	- name: service-0
	  addr: ":8080"
	  handler:
		type: http
	  listener:
		type: tcp
	- name: service-1
	  addr: ":1080"
	  handler:
		type: socks5
	  listener:
		type: tcp
	```

启动两个服务，一个监听在8080端口的HTTP代理服务，和一个监听在1080端口的SOCKS5代理服务。

### 使用转发

=== "命令行"

	```bash
	gost -L http://:8080 -F http://192.168.1.1:8080
	```

=== "配置文件"

    ```yaml
	services:
	- name: service-0
	  addr: ":8080"
	  handler:
		type: http
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
		  dialer:
		    type: tcp
	```

监听在8080端口的HTTP代理服务，使用192.168.1.1:8080做为上级代理进行转发。

### 使用多级转发(转发链)

=== "命令行"

	```bash
	gost -L :8080 -F http://192.168.1.1:8080 -F socks5://192.168.1.2:1080
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
		  addr: 192.168.1.1:8080
		  connector:
			type: http
		  dialer:
		    type: tcp
	  - name: hop-1
		nodes:
		- name: node-0
		  addr: 192.168.1.2:1080
		  connector:
			type: socks5
		  dialer:
		    type: tcp
	```

GOST按照`-F`设置的顺序将请求最终转发给192.168.1.2:1080处理。

## 转发模式

更详细的使用说明请参考[端口转发](../tutorials/port-forwarding/)。

### TCP本地端口转发

=== "命令行"

	```bash
	gost -L tcp://:8080/192.168.1.1:80
	```

=== "配置文件"

    ```yaml
	services:
	- name: service-0
	  addr: :8080
	  handler:
		type: tcp
	  listener:
		type: tcp
	  forwarder:
	    nodes:
		- name: target-0
		  addr: 192.168.1.1:80
	```

将本地的TCP端口8080映射到192.168.1.1的80端口，所有到本地8080端口的数据会被转发到192.168.1.1:80。

### UDP本地端口转发

=== "命令行"

	```bash
    gost -L udp://:10053/192.168.1.1:53
	```

=== "配置文件"

    ```yaml
	services:
	- name: service-0
	  addr: :10053
	  handler:
		type: udp
	  listener:
		type: udp
	  forwarder:
	    nodes:
		- name: target-0
		  addr: 192.168.1.1:53
	```

将本地的UDP端口10053映射到192.168.1.1的53端口，所有到本地10053端口的数据会被转发到192.168.1.1:53。

### TCP本地端口转发(转发链)

=== "命令行"

	```bash
    gost -L=tcp://:8080/192.168.1.1:80 -F socks5://192.168.1.2:1080
	```

=== "配置文件"

    ```yaml
	services:
	- name: service-0
	  addr: :8080
	  handler:
		type: tcp
		chain: chain-0
	  listener:
		type: tcp
	  forwarder:
	    nodes:
		- name: target-0
		  addr: 192.168.1.1:80
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

将本地的TCP端口8080通过转发链映射到192.168.1.1的80端口。

### TCP远程端口转发

=== "命令行"

	```sh
    gost -L=rtcp://:2222/:22 -F socks5://192.168.1.2:1080
	```

=== "配置文件"

    ```yaml
	services:
	- name: service-0
	  addr: :2222
	  handler:
		type: rtcp
	  listener:
		type: rtcp
		chain: chain-0
	  forwarder:
	    nodes:
		- name: target-0
		  addr: :22
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

在192.168.1.2上开启并监听TCP端口2222，并将192.168.1.2上的2222端口映射到本地TCP端口22，所有到192.168.1.2:2222的数据会被转发到本地端口22。

### UDP远程端口转发

=== "命令行"

	```sh
    gost -L=rudp://:10053/:53 -F socks5://192.168.1.2:1080
	```

=== "配置文件"

    ```yaml
	services:
	- name: service-0
	  addr: :10053
	  handler:
		type: rudp
	  listener:
		type: rudp
		chain: chain-0
	  forwarder:
	    nodes:
		- name: target-0
		  addr: :53
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

在192.168.1.2上开启并监听UDP端口10053，并将192.168.1.2上的10053端口映射到本地UDP端口53，所有到192.168.1.2:10053的数据会被转发到本地端口53。