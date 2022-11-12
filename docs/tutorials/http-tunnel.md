# HTTP数据通道

HTTP是目前互联网上使用最广泛的一种数据交换协议，随着互联网的发展，协议也进行了几次重大的版本升级，从最原始的HTTP/1到HTTP/2，再到现在的基于QUIC协议的HTTP/3。

原始HTTP协议是一种请求响应式的交互方式，由客户端主动发起请求，服务端收到请求后再将处理结果发送回客户端，这种方式无法在客户端和服务端之间保持长连接，因此很难做到双向实时数据传输。为了实现全双工通信，HTTP协议又进行了多种扩展，例如增加CONNECT方法，Websocket扩展协议，HTTP/2的服务端推送和HTTP/3的WebTransport等。GOST已经支持了以上大部分的功能。

!!! note "注意"
    CONNECT方法用于HTTP建立代理连接，严格来说不能称之为数据通道，然而其本质都是建立了可以双向通讯的长连接，所以在这里统一被当作数据通道。

## HTTP CONNECT方法

### 服务端

=== "命令行"
    ```
	gost -L http://user:pass@:8080
	```

=== "配置文件"
    ```yaml
	services:
	- name: service-0
	  addr: ":8080"
	  handler:
		type: http
		auth:
		  username: user
		  password: pass
	  listener:
		type: tcp
	```

以上是一个最简单的带有认证功能的HTTP代理服务。

### 客户端

=== "命令行"
    ```
	gost -L http://:8000 -F http://user:pass@:8080
	```

=== "配置文件"
    ```yaml
	services:
	- name: service-0
	  addr: ":8000"
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
		  addr: :8080
		  connector:
			type: http
			auth:
			  username: user
			  password: pass
		  dialer:
			type: tcp
	```

客户端本身也是一个HTTP代理服务，并通过转发链将请求转发给上面的HTTP代理服务。

## Plain HTTP Tunnel(pht)

CONNECT方法并不是所有服务都支持，为了尽可能通用，GOST利用原始HTTP协议中的GET和POST方法来实现数据通道，包括加密的phts和明文的pht两种模式。

### 服务端

=== "命令行"
    ```
	gost -L relay+pht://:8080?authorizePath=/authorize&pushPath=/push&pullPath=/pull
	```
	或
    ```
	gost -L relay+phts://:8080
	```

=== "配置文件"
    ```yaml
	services:
	- name: service-0
	  addr: ":8080"
	  handler:
		type: relay
	  listener:
		type: pht
		# type: phts
		metadata:
          authorizePath: /authorize
          pullPath: /pull
          pushPath: /push
	```

### 客户端

=== "命令行"
    ```
	gost -L http://:8000 -F relay+pht://:8080?authorizePath=/authorize&pushPath=/push&pullPath=/pull
	```
	或
    ```
	gost -L http://:8000 -F relay+phts://:8080
	```

=== "配置文件"
    ```yaml
	services:
	- name: service-0
	  addr: ":8000"
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
		  addr: :8080
		  connector:
			type: relay
		  dialer:
			type: pht
			# type: phts
		    metadata:
              authorizePath: /authorize
              pullPath: /pull
              pushPath: /push
	```

!!! caution
    PHT是一个实验性功能，还在不断完善中。

## Websocket

Websocket是HTTP/1中为了建立长连接而增加的扩展协议。

### 服务端

=== "命令行"
    ```
	gost -L socks5+ws://user:pass@:1080
	```

=== "配置文件"
    ```yaml
	services:
	- name: service-0
	  addr: ":1080"
	  handler:
		type: socks5
		auth:
		  username: user
		  password: pass
	  listener:
		type: ws
	```

### 客户端

=== "命令行"
    ```
	gost -L http://:8000 -F socks5+ws://user:pass@:1080
	```

=== "配置文件"
    ```yaml
	services:
	- name: service-0
	  addr: ":8000"
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
		  addr: :1080
		  connector:
			type: socks5
			auth:
			  username: user
			  password: pass
		  dialer:
			type: ws
	```

!!! caution "注意"
    这里的认证信息设置的是SOCKS5代理的认证，Websocket暂不支持认证设置。

## HTTP/2

GOST中HTTP/2有两种使用方式，代理模式和标准数据通道模式。

### HTTP/2 CONNECT方法

HTTP/2使用与HTTP相同的CONNECT方法实现代理模式。

### 服务端

=== "命令行"
    ```
	gost -L http2://user:pass@:8443
	```

=== "配置文件"
    ```yaml
	services:
	- name: service-0
	  addr: ":8443"
	  handler:
		type: http2
		auth:
		  username: user
		  password: pass
	  listener:
		type: http2
	```

### 客户端

=== "命令行"
    ```
	gost -L http://:8000 -F http2://user:pass@:8443
	```

=== "配置文件"
    ```yaml
	services:
	- name: service-0
	  addr: ":8000"
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
		  addr: :8443
		  connector:
			type: http2
			auth:
			  username: user
			  password: pass
		  dialer:
			type: http2
	```

### HTTP/2数据通道

HTTP/2做为数据通道可以使用加密(h2)和明文(h2c)两种模式。

### 服务端

=== "命令行"
    ```
	gost -L socks5+h2://user:pass@:8443
	```
	或
    ```
	gost -L socks5+h2c://user:pass@:8443
	```

=== "配置文件"
    ```yaml
	services:
	- name: service-0
	  addr: ":8443"
	  handler:
		type: socks5
		auth:
		  username: user
		  password: pass
	  listener:
		type: h2
		# type: h2c
	```

### 客户端

=== "命令行"
    ```
	gost -L http://:8000 -F socks5+h2://user:pass@:8443
	```
	或
    ```
	gost -L http://:8000 -F socks5+h2c://user:pass@:8443
	```

=== "配置文件"
    ```yaml
	services:
	- name: service-0
	  addr: ":8000"
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
		  addr: :8443
		  connector:
			type: socks5
			auth:
			  username: user
			  password: pass
		  dialer:
			type: h2
			# type: h2c
	```

!!! tip "服务端推送"
    GOST不支持HTTP/2的服务端推送功能。

## gRPC

gRPC是基于HTTP/2，因此具有HTTP/2本身固有的优点，另外gRPC天然的支持双向流传输，因此很适合作为数据通道。

### 服务端

=== "命令行"
    ```
	gost -L relay+grpc://user:pass@:8443
	```
=== "配置文件"
    ```yaml
	services:
	- name: service-0
	  addr: ":8443"
	  handler:
		type: relay 
		auth:
		  username: user
		  password: pass
	  listener:
		type: grpc
	```

### 客户端

=== "命令行"
    ```
	gost -L http://:8000 -F relay+grpc://user:pass@:8443
	```
=== "配置文件"
    ```yaml
	services:
	- name: service-0
	  addr: ":8000"
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
		  addr: :8443
		  connector:
			type: relay
			auth:
			  username: user
			  password: pass
		  dialer:
			type: grpc
	```

gRPC默认使用TLS加密，可以通过设置`grpcInsecure`参数使用明文进行通讯。

### 服务端

=== "命令行"
    ```
	gost -L relay+grpc://user:pass@:8443?grpcInsecure=true
	```
=== "配置文件"
    ```yaml
	services:
	- name: service-0
	  addr: ":8443"
	  handler:
		type: relay 
		auth:
		  username: user
		  password: pass
	  listener:
		type: grpc
		metadata:
		  grpcInsecure: true
	```

### 客户端

=== "命令行"
    ```
	gost -L http://:8000 -F relay+grpc://user:pass@:8443?grpcInsecure=true
	```
=== "配置文件"
    ```yaml
	services:
	- name: service-0
	  addr: ":8000"
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
		  addr: :8443
		  connector:
			type: relay
			auth:
			  username: user
			  password: pass
		  dialer:
			type: grpc
		    metadata:
		      grpcInsecure: true
	```

## HTTP/3

HTTP/3协议规范中支持CONNECT方法和WebTransport两种方式建立数据通道。

GOST目前不支持以上两种方式，而是通过在HTTP/3之上利用pht来建立数据通道。

!!! note "WebTransport"
    [WebTransport](https://web.dev/webtransport/)目前处在早期草案阶段，待时机成熟后GOST会添加对其的支持。

### 服务端

=== "命令行"

    ```bash
	gost -L "h3://:8443?authorizePath=/authorize&pushPath=/push&pullPath=/pull"
	```

=== "配置文件"

    ```yaml
	services:
	- name: service-0
	  addr: ":8443"
	  handler:
		type: auto
	  listener:
		type: h3
		metadata:
          authorizePath: /authorize
          pullPath: /pull
          pushPath: /push
	```

### 客户端

=== "命令行"
    ```
	gost -L http://:8000 -F h3://:8443?authorizePath=/authorize&pushPath=/push&pullPath=/pull
	```

=== "配置文件"

    ```yaml
	services:
	- name: service-0
	  addr: ":8000"
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
		  addr: :8443
		  connector:
			type: http
		  dialer:
			type: h3
		    metadata:
              authorizePath: /authorize
              pullPath: /pull
              pushPath: /push
	```