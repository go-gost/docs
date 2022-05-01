# Port Forwarding

Port forwarding is divided into TCP and UDP port forwarding according to the protocol type, and local forwarding and remote forwarding according to the forwarding type. There are four combinations in total.

## Local Port Forwarding

### TCP

You can set a single forwarding destination address for one-to-one port forwarding:

=== "CLI"
	```bash
	gost -L tcp://:8080/192.168.1.1:80
	```
=== "File (YAML)"

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

Map the local TCP port 8080 to port 80 of 192.168.1.1, and all data to the local port 8080 will be forwarded to 192.168.1.1:80.

You can also set multiple destination addresses for one-to-many port forwarding:

=== "CLI"
	```bash
	gost -L tcp://:8080/192.168.1.1:80,192.168.1.2:80,192.168.1.3:8080?strategy=round&maxFails=1&failTimeout=30s
	```
=== "File (YAML)"

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

After each forwarding request is received, the node selector in the forwarder will be used to select a node in the target address list as the target address of this forwarding.

### UDP

Similar to TCP port forwarding, single and multiple destination forwarding addresses can also be specified.

=== "CLI"
	```bash
	gost -L udp://:10053/192.168.1.1:53,192.168.1.2:53,192.168.1.3:53?ttl=5s
	```
=== "File (YAML)"

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
	```
	gost -L http://:8080?udp=true
	```
	* GOST SOCKS5代理服务并开启了UDP转发功能，采用UDP-over-TCP方式。
	```
	gost -L socks5://:1080?udp=true
	```
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
		auth:
		  username: user
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
	```
	gost -L socks5://:1080?bind=true
	```
	* Relay服务并开启了BIND功能，采用UDP-over-TCP方式。
	```
	gost -L socks5://:8421?bind=true
	```

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

## 服务端转发

以上的转发方式可以看作是客户端转发，由客户端来控制转发的目标地址。目标地址也可以由服务端指定。

### 服务端

=== "命令行"
	```bash
	gost -L tls://:8443/192.168.1.1:80
	```
=== "配置文件"
    ```yaml
	services:
	- name: service-0
	  addr: :8080
	  handler:
		type: forward
	  listener:
		type: tls
	  forwarder:
		targets:
		- 192.168.1.1:80
	```
### 客户端

=== "命令行"
	```bash
    gost -L=tcp://:8080 -F forward+tls://:8443
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
		chain: chain-0
	chains:
	- name: chain-0
	  hops:
	  - name: hop-0
		nodes:
		- name: node-0
		  addr: :8443
		  connector:
			type: forward
		  dialer:
			type: tls
	```

!!! note "forward连接器和处理器"
    这里服务的处理器和转发链的连接器必须为`forward`类型，由于目标地址由服务端指定，因此客户端无需指定目标地址。`forward`连接器不做任何逻辑处理。
	
	这里的`tcp://:8080`等同于`tcp://:8080/:0`，转发目标地址`:0`在这里作为占位符。仅当配合`forward`连接器使用时，这种用法才是有效的。