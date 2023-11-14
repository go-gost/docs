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
	    nodes:
		- name: target-0
		  addr: 192.168.1.1:80
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
	    nodes:
		- name: target-0
		  addr: 192.168.1.1:80
		- name: target-1
		  addr: 192.168.1.2:80
		- name: target-2
		  addr: 192.168.1.3:8080
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
	gost -L udp://:10053/192.168.1.1:53,192.168.1.2:53,192.168.1.3:53?keepAlive=true&ttl=5s
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
		  keepAlive: true
		  ttl: 5s
	  forwarder:
	    nodes:
		- name: target-0
		  addr: 192.168.1.1:53
		- name: target-1
		  addr: 192.168.1.2:53
		- name: target-2
		  addr: 192.168.1.3:53
	```

Each client corresponds to a forwarding channel. When the `keepAlive` option is set to `false`, the channel will be closed immediately after the requested response data is returned to the client.

When the `keepAlive` option is set to `true`, the forwarding service does not receive data from the forwarding target host within a certain period of time, and the forwarding channel will be marked as idle. The forwarding service internally checks whether the forwarding channel is idle according to the period specified by the `ttl` option (default value is 5 seconds). If it is idle, the channel will be closed. An idle channel will be closed for at most two check cycles.

### Forwarding Chain

Port forwarding can be used in conjunction with forwarding chains to perform indirect forwarding.

=== "CLI"
	```bash
    gost -L=tcp://:8080/192.168.1.1:80 -F socks5://192.168.1.2:1080
	```
=== "File (YAML)"

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

Map the local TCP port 8080 to port 80 of 192.168.1.1 through the forwarding chain.

=== "CLI"
	```bash
    gost -L=udp://:10053/192.168.1.1:53 -F socks5://192.168.1.2:1080
	```
=== "File (YAML)"

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
	    nodes:
		- name: target-0
		  addr: 192.168.1.1:53
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

Map the local UDP port 10053 to port 53 of 192.168.1.1 through the forwarding chain.

!!! caution "Limitation"
	When forwarding chains are used in UDP local port forwarding, the last node at the end of the forwarding chain must be of the following type:

	* GOST HTTP proxy service and enable UDP forwarding function, using UDP-over-TCP method.
	```
	gost -L http://:8080?udp=true
	```
	* GOST SOCKS5 proxy service and enable UDP forwarding function, using UDP-over-TCP method.
	```
	gost -L socks5://:1080?udp=true
	```
	* Relay service, using UDP-over-TCP method.
	* SSU service.

!!! tip "UDP-over-TCP"
	UDP-over-TCP refers to using a TCP connection to transmit UDP datagrams. In GOST, this statement may not be accurate. For example, SOCKS5 is used for UDP port forwarding. SOCKS5 services can be based on TCP type transport channels (TLS, Websocket, etc.) or UDP type transport channels (KCP, QUIC, etc.), it is more appropriate to use UDP-over-Stream here (as opposed to the unreliable datagram transmission of UDP), any reliable streaming protocol can be used here.

### SSH

TCP port forwarding can be indirectly forwarded by means of the port forwarding function of the standard SSH protocol

=== "CLI"
	```bash
    gost -L=tcp://:8080/192.168.1.1:80 -F sshd://user:pass@192.168.1.2:22
	```
=== "File (YAML)"

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
		  addr: 192.168.1.2:22
		  connector:
			type: sshd
		  dialer:
			type: sshd
			auth:
			  username: user
			  password: pass
	```

The 192.168.1.2:22 service here can be the standard SSH service of the system itself, or the sshd type service of GOST

=== "CLI"
    ```
	gost -L sshd://user:pass@:22
	```
=== "File (YAML)"

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

## Remote Port Forwarding

### TCP

=== "CLI"
	```bash
	gost -L rtcp://:8080/192.168.1.1:80
	```
=== "File (YAML)"

    ```yaml
	services:
	- name: service-0
	  addr: :8080
	  handler:
		type: rtcp
	  listener:
		type: rtcp
	  forwarder:
	    nodes:
		- name: target-0
		  addr: 192.168.1.1:80
	```

Map the local TCP port 8080 to port 80 of 192.168.1.1, and all data to the local port 8080 will be forwarded to 192.168.1.1:80.

### UDP

=== "CLI"
	```bash
	gost -L rudp://:10053/192.168.1.1:53,192.168.1.2:53,192.168.1.3:53?ttl=5s
	```
=== "File (YAML)"

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
	    nodes:
		- name: target-0
		  addr: 192.168.1.1:53
		- name: target-1
		  addr: 192.168.1.2:53
		- name: target-2
		  addr: 192.168.1.3:53
	```

!!! note 
	Remote port forwarding is no different from local port forwarding without the use of forwarding chains.

### Forwarding Chain

=== "CLI"
	```bash
    gost -L=rtcp://:8080/192.168.1.1:80 -F socks5://192.168.1.2:1080
	```
=== "File (YAML)"

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

According to the address specified by the rtcp service, listen on the 8080 TCP port on the host 192.168.1.2 through the forwarding chain. After receiving the request, it forwards the data to the rtcp service through the forwarding chain, and the rtcp service forwards the request to port 192.168.1.1:80.

=== "CLI"
	```bash
    gost -L=rudp://:10053/192.168.1.1:53 -F socks5://192.168.1.2:1080
	```
=== "File (YAML)"

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
		  addr: 192.168.1.1:53
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

According to the address specified by the rudp service, listen on port 10053 on the host 192.168.1.2 through the forwarding chain. After receiving the request, it forwards the data to the rudp service through the forwarding chain, and the rudp service forwards the request to port 192.168.1.1:53.

!!! note 
	The forwarding chain on remote port forwarding is set on the listener by default, and another forwarding chain can also be set on the handler at the same time.

	The listening address in the remote port forwarding service will listen on the host where the service of the last node at the end of the forwarding chain is located when using the forwarding chain.


!!! caution "Limitation"
	When forwarding chains are used in remote port forwarding, the last node at the end of the forwarding chain must be of the following type:

	* GOST SOCKS5 proxy service and enable BIND function, using UDP-over-TCP method.
	```
	gost -L socks5://:1080?bind=true
	```
	* Relay service and enable BIND function, using UDP-over-TCP method.
	```
	gost -L relay://:8421?bind=true
	```

### SSH

TCP remote port forwarding can be indirectly forwarded by means of the remote port forwarding function of the standard SSH protocol:

=== "CLI"
	```bash
    gost -L=rtcp://:8080/192.168.1.1:80 -F sshd://user:pass@192.168.1.2:22
	```
=== "File (YAML)"

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
	    nodes:
		- name: target-0
		  addr: 192.168.1.1:80
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

The 192.168.1.2:22 service here can be the standard SSH service of the system itself, or the sshd type service of GOST.

## Port Range

The target node addresses in forwarder are supported using the port range format.

=== "CLI"

	```bash
	gost -L tcp://:8080/192.168.1.1:8000-8003
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
	    nodes:
		- name: target-0
		  addr: 192.168.1.1:8000-8003
	```

It is equivalent to:

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
    	addr: 192.168.1.1:8000
      - name: target-1
    	addr: 192.168.1.1:8001
      - name: target-2
    	addr: 192.168.1.1:8002
      - name: target-3
    	addr: 192.168.1.1:8003
```

## Server-side Forwarding

The above forwarding method can be regarded as client forwarding, and the client controls the forwarding target address. The target address can also be specified by the server.

### Server

=== "CLI"
	```bash
	gost -L tls://:8443/192.168.1.1:80
	```
=== "File (YAML)"

    ```yaml
	services:
	- name: service-0
	  addr: :8080
	  handler:
		type: forward
	  listener:
		type: tls
	  forwarder:
	    nodes:
		- name: target-0
		  addr: 192.168.1.1:80
	```
### Client

=== "CLI"
	```bash
    gost -L=tcp://:8080 -F forward+tls://:8443
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

!!! note "forward type connector and handler"
	The handler of this service and the connector of the forwarding chain must be of type `forward`. Since the target address is specified by the server, the client does not need to specify the target address. The `forward` connector does not do any logic processing.
	
	Here `tcp://:8080` is equivalent to `tcp://:8080/:0`, and the forwarding destination address `:0` is here as a placeholder. This usage is only valid when used with the `forward` connector.