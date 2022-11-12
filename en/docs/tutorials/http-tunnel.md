# HTTP Tunnel

HTTP is the most widely used data exchange protocol on the Internet. With the development of the Internet, the protocol has undergone several major version upgrades, from the original HTTP/1 to HTTP/2, and then to the current QUIC-based protocol HTTP/3.

The original HTTP protocol is a request-response interaction method. The client initiates the request actively, and the server sends the processing result back to the client after receiving the request. This method cannot maintain a long connection between the client and the server, so it is difficult to achieve two-way real-time data transmission. In order to realize full-duplex communication, the HTTP protocol has been extended in various ways, such as adding CONNECT method, Websocket extension protocol, HTTP/2 server push and HTTP/3 WebTransport. GOST already supports most of the above functions.

!!! note
    The CONNECT method is used to establish a proxy connection for HTTP. Strictly speaking, it cannot be called a tunnel. However, its essence is to establish a long connection that can communicate in both directions, so it is uniformly regarded as a tunnel here.

## HTTP CONNECT MEthod

### Server

=== "CLI"
    ```
	gost -L http://user:pass@:8080
	```

=== "File (YAML)"

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

The above is a simplest HTTP proxy service with authentication function.

### Client

=== "CLI"
    ```
	gost -L http://:8000 -F http://user:pass@:8080
	```

=== "File (YAML)"

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

The client itself is also an HTTP proxy service and forwards the request to the up-stream HTTP proxy service through the forwarding chain.

## Plain HTTP Tunnel(pht)

The CONNECT method is not supported by all services. In order to be as general as possible, GOST uses the GET and POST methods in the original HTTP protocol to implement data tunnel, including encrypted phts and plaintext pht modes.

### Server

=== "CLI"
    ```
	gost -L relay+pht://:8080?authorizePath=/authorize&pushPath=/push&pullPath=/pull
	```
	or
    ```
	gost -L relay+phts://:8080
	```

=== "File (YAML)"

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

### Client

=== "CLI"
    ```
	gost -L http://:8000 -F relay+pht://:8080?authorizePath=/authorize&pushPath=/push&pullPath=/pull
	```
	or
    ```
	gost -L http://:8000 -F relay+phts://:8080
	```

=== "File (YAML)"

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

## Websocket

Websocket is an extension protocol added in HTTP/1 for establishing long connections.

### Server

=== "CLI"
    ```
	gost -L socks5+ws://user:pass@:1080
	```

=== "File (YAML)"

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

### Client

=== "CLI"
    ```
	gost -L http://:8000 -F socks5+ws://user:pass@:1080
	```

=== "File (YAML)"

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

!!! caution
	The authentication information here is set for SOCKS5 proxy, and websocket currently does not support authentication settings.

## HTTP/2

There are two ways to use HTTP/2 in GOST, proxy mode and tunnel mode.

### HTTP/2 CONNECT Method

HTTP/2 implements proxy mode using the same CONNECT method as HTTP.

### Server

=== "CLI"
    ```
	gost -L http2://user:pass@:8443
	```

=== "File (YAML)"

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

### Client

=== "CLI"
    ```
	gost -L http://:8000 -F http2://user:pass@:8443
	```

=== "File (YAML)"

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

### HTTP/2 Tunnel

HTTP/2 can use encrypted (h2) and plaintext (h2c) modes as a tunnel.

### Server

=== "CLI"
    ```
	gost -L socks5+h2://user:pass@:8443
	```
	or
    ```
	gost -L socks5+h2c://user:pass@:8443
	```

=== "File (YAML)"

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

### Client

=== "CLI"
    ```
	gost -L http://:8000 -F socks5+h2://user:pass@:8443
	```
	or
    ```
	gost -L http://:8000 -F socks5+h2c://user:pass@:8443
	```

=== "File (YAML)"

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

!!! tip "Server Push"
	GOST does not support the server push function of HTTP/2.

## gRPC

gRPC is based on HTTP/2, so it has the inherent advantages of HTTP/2 itself. In addition, gRPC naturally supports bidirectional streaming, so it is very suitable as a tunnel.

### Server

=== "CLI"
    ```
	gost -L relay+grpc://user:pass@:8443
	```
=== "File (YAML)"

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

### Client

=== "CLI"
    ```
	gost -L http://:8000 -F relay+grpc://user:pass@:8443
	```
=== "File (YAML)"

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

gRPC uses TLS encryption by default and can communicate in clear text by setting the `grpcInsecure` parameter.

### Server

=== "CLI"
    ```
	gost -L relay+grpc://user:pass@:8443?grpcInsecure=true
	```

=== "File (YAML)"

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

### Client

=== "CLI"
    ```
	gost -L http://:8000 -F relay+grpc://user:pass@:8443?grpcInsecure=true
	```

=== "File (YAML)"

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

The HTTP/3 protocol supports the CONNECT method and the WebTransport method to establish a tunnel.

GOST currently does not support the above two methods, but establishes a tunnel by using pht on top of HTTP/3

!!! note "WebTransport"
    [WebTransport](https://web.dev/webtransport/) is currently in the early draft stage, and GOST will add support for it when the time is right.

### Server

=== "CLI"
    ```
	gost -L h3://:8443?authorizePath=/authorize&pushPath=/push&pullPath=/pull
	```
=== "File (YAML)"

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

### Client

=== "CLI"
    ```
	gost -L http://:8000 -F h3://:8443?authorizePath=/authorize&pushPath=/push&pullPath=/pull
	```

=== "File (YAML)"

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