# Quick Start

!!!tip "Zero Configuration"
    You can run GOST directly from the command line without additional configuration files.
    
## Proxy Mode

Start one or more proxy services, and can be forwarded through the forwarding chain. 

### HTTP Proxy

Start an HTTP proxy service listening on port 8080:

=== "CLI"
    ```sh
	gost -L http://:8080
	```
=== "File (YAML)"
    ```yaml
	services:
	- name: service-0
	  addr: ":8080"
	  handler:
		type: http
	  listener:
		type: tcp
	```

### Multiple Services

Start two services, an HTTP proxy service listening on port 8080, and a SOCKS5 proxy service listening on port 1080:

=== "CLI"
    ```
    gost -L http://:8080 -L socks5://:1080 
	```
=== "File (YAML)"
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

### Forwading

Start an HTTP proxy service listening on port 8080, and use 192.168.1.1:8080 as the upper-level proxy for forwarding:

=== "CLI"
	```
	gost -L http://:8080 -F http://192.168.1.1:8080
	```
=== "File (YAML)"
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

### Multi-level Forwarding Chain

GOST finally forwards the request to 192.168.1.2:1080 through the forwarding chain in the order set by `-F`:

=== "CLI"
	```
	gost -L :8080 -F http://192.168.1.1:8080 -F socks5://192.168.1.2:1080
	```
=== "File (YAML)"
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

## Forwarding Mode

### TCP Local Port Forwarding

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

Map local TCP port 8080 to port 80 of 192.168.1.1, all data sent to the local port 8080 will be forwarded to 192.168.1.1:80.

### UDP Local Port Forwarding

=== "CLI"
	```bash
    gost -L udp://:10053/192.168.1.1:53
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
	  forwarder:
	    nodes:
		- name: target-0
		  addr: 192.168.1.1:53
	```

Map local UDP port 10053 to port 53 of 192.168.1.1, all data sent to the local port 10053 will be forwarded to 192.168.1.1:53.

### TCP Local Port Forwarding (With Chain)

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

Map local TCP port 8080 to port 80 of 192.168.1.2 through the forwarding chain `chain-0`.

### TCP Remote Port Forwarding

=== "CLI"
	```sh
    gost -L=rtcp://:2222/:22 -F socks5://192.168.1.2:1080
	```
=== "File (YAML)"
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

Listen on TCP port 2222 on 192.168.1.2, and map it to local TCP port 22, all data sent to 192.168.1.2:2222 will be forwarded to local port 22.

### UDP Remote Port Forwarding

=== "CLI"
	```sh
    gost -L=rudp://:10053/:53 -F socks5://192.168.1.2:1080
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

Listen on UDP port 10053 on 192.168.1.2, and map it to local UDP port 53, all data sent to 192.168.1.2:10053 will be forwarded to local port 53.
