# 端口转发

端口转发根据协议类型分为TCP和UDP端口转发，根据转发类型又分为本地转发和远程转发，总共有四种组合。

## 本地端口转发

### TCP

可以设置单一的转发目标地址进行一对一端口转发

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
		targets:
		- 192.168.1.1:80
	```

将本地的TCP端口8080映射到192.168.1.1的80端口，所有到本地8080端口的数据会被转发到192.168.1.1:80。

也可以设置多个目标地址进行一对多端口转发

=== "命令行"
	```bash
	gost -L tcp://:8080/192.168.1.1:80,192.168.1.2:80,192.168.1.3:8080?strategy=round&maxFails=1&failTimeout=30s
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
		targets:
		- 192.168.1.1:80
		- 192.168.1.2:80
		- 192.168.1.3:8080
		selector:
          strategy: round
          maxFails: 1
          failTimeout: 30s
	```

在每次收到转发请求后，会利用转发器中的节点选择器在目标地址列表中选择一个节点作为本次转发的目标地址。

### UDP

和TCP端口转发类似，也可以指定单个和多个目标转发地址。

=== "命令行"
	```bash
	gost -L udp://:10053/192.168.1.1:53,192.168.1.2:53,192.168.1.3:53?ttl=5s
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
		metadata:
		  ttl: 5s
	  forwarder:
		targets:
		- 192.168.1.1:53
		- 192.168.1.2:53
		- 192.168.1.3:53
	```

每一个客户端对应一条转发通道，当转发服务一定时间内收不到转发目标主机数据时，此转发通道会被标记为空闲状态。转发服务内部会按照`ttl`参数指定的周期检查转发通道是否空闲，如果空闲则此通道将被关闭。一个空闲通道最多会在两个检查周期内被关闭。

### 转发链

端口转发可以配合转发链进行间接转发。

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
		targets:
		- 192.168.1.1:80
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

=== "命令行"
	```bash
    gost -L=udp://:10053/192.168.1.1:53 -F socks5://192.168.1.2:1080
	```
=== "配置文件"
    ```yaml
	services:
	- name: service-0
	  addr: :10053
	  handler:
		type: udp
		chain: chain-0
	  listener:
		type: udp
	  forwarder:
		targets:
		- 192.168.1.1:53
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

将本地的UDP端口10053通过转发链映射到192.168.1.1的53端口。

!!! caution "限制"
	当UDP本地端口转发中使用转发链时，转发链末端最后一个节点必须是以下类型：

	* GOST HTTP代理服务并开启了UDP转发功能，采用UDP-over-TCP方式。
	* GOST SOCKS5代理服务并开启了UDP转发功能，采用UDP-over-TCP方式。
	* Relay服务，采用UDP-over-TCP方式。
	* SSU服务。

!!! tip "UDP-over-TCP"
    UDP-over-TCP是指使用TCP连接来传输UDP数据包。在GOST中这个说法可能并不太准确，例如使用SOCKS5进行UDP端口转发，SOCKS5服务可以是基于TCP类型的传输通道(TLS, Websocket等)，也可以是基于UDP类型的传输通道(KCP, QUIC等)，这里使用UDP-over-Stream更合适一些(相对于UDP不可靠的数据报式传输来说)，任何可靠的流式传输协议均可以用在此处。

### SSH

TCP端口转发可以借助于标准SSH协议的端口转发功能进行间接转发

=== "命令行"
	```bash
    gost -L=tcp://:8080/192.168.1.1:80 -F sshd://user:pass@192.168.1.2:22
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
		targets:
		- 192.168.1.1:80
	chains:
	- name: chain-0
	  hops:
	  - name: hop-0
		nodes:
		- name: node-0
		  addr: 192.168.1.2:22
		  connector:
			type: sshd
		  dialer:
			type: sshd
			auth:
			  username: user
			  password: pass
	```

这里的192.168.1.2:22服务可以是系统本身的标准SSH服务，也可以是GOST的sshd类型服务

=== "命令行"
    ```
	gost -L sshd://user:pass@:22
	```
=== "配置文件"
    ```yaml
	services:
	- name: service-0
	  addr: :22
	  handler:
		type: sshd
	  listener:
		type: sshd
		auths:
		- username: user
		  password: pass
	```

## 远程端口转发

### TCP

=== "命令行"
	```bash
	gost -L rtcp://:8080/192.168.1.1:80
	```
=== "配置文件"
    ```yaml
	services:
	- name: service-0
	  addr: :8080
	  handler:
		type: rtcp
	  listener:
		type: rtcp
	  forwarder:
		targets:
		- 192.168.1.1:80
	```

将本地的TCP端口8080映射到192.168.1.1的80端口，所有到本地8080端口的数据会被转发到192.168.1.1:80。

### UDP

=== "命令行"
	```bash
	gost -L rudp://:10053/192.168.1.1:53,192.168.1.2:53,192.168.1.3:53?ttl=5s
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
		metadata:
		  ttl: 5s
	  forwarder:
		targets:
		- 192.168.1.1:53
		- 192.168.1.2:53
		- 192.168.1.3:53
	```

!!! note "注意"
    在不使用转发链的情况下，远程端口转发与本地端口转发没有区别。

### 转发链

=== "命令行"
	```bash
    gost -L=rtcp://:8080/192.168.1.1:80 -F socks5://192.168.1.2:1080
	```
=== "配置文件"
    ```yaml
	services:
	- name: service-0
	  addr: :8080
	  handler:
		type: rtcp
	  listener:
		type: rtcp
		chain: chain-0
	  forwarder:
		targets:
		- 192.168.1.1:80
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

根据rtcp服务指定的地址，通过转发链在主机192.168.1.2上监听8080TCP端口。当收到请求后再通过转发链将数据转发给rtcp服务，rtcp服务再将请求转发到192.168.1.1:80端口。

=== "命令行"
	```bash
    gost -L=rudp://:10053/192.168.1.1:53 -F socks5://192.168.1.2:1080
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
		targets:
		- 192.168.1.1:53
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

根据rudp服务指定的地址，通过转发链在主机192.168.1.2上监听10053端口。当收到请求后再通过转发链将数据转发给rudp服务，rudp服务再将请求转发到192.168.1.1:53端口。

!!! note "注意"
    远程端口转发上的转发链默认设置在监听器上，此时处理器上也可以再设置另外的转发链。

	远程端口转发服务中的监听地址，在使用转发链时将监听在转发链末端最后一个节点服务所在的主机上。


!!! caution "限制"
	当远程端口转发中使用转发链时，转发链末端最后一个节点必须是以下类型：

	* GOST SOCKS5代理服务并开启了BIND功能，采用UDP-over-TCP方式。
	* Relay服务并开启了BIND功能，采用UDP-over-TCP方式。

### SSH

TCP远程端口转发可以借助于标准SSH协议的远程端口转发功能进行间接转发

=== "命令行"
	```bash
    gost -L=rtcp://:8080/192.168.1.1:80 -F sshd://user:pass@192.168.1.2:22
	```
=== "配置文件"
    ```yaml
	services:
	- name: service-0
	  addr: :8080
	  handler:
		type: rtcp
	  listener:
		type: rtcp
		chain: chain-0
	  forwarder:
		targets:
		- 192.168.1.1:80
	chains:
	- name: chain-0
	  hops:
	  - name: hop-0
		nodes:
		- name: node-0
		  addr: 192.168.1.2:22
		  connector:
			type: sshd
		  dialer:
			type: sshd
			auth:
			  username: user
			  password: pass
	```

这里的192.168.1.2:22服务可以是系统本身的标准SSH服务，也可以是GOST的sshd类型服务。