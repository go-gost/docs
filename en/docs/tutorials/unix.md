# Unix Domain Socket Redirector

UDS(Unix Domain Socket) redirector can redirect the local UDS service to a TCP service or another UDS service. The forwarding chain is still valid in this scenario.

!!! caution "Limitation"
	When redirecting to a remote UDS service, the last node at the end of the forwarding chain must be the `relay` protocol.

## Redirect to TCP service

Redirect the local UDS service `gost.sock` to TCP service `192.168.1.1:8080`.

=== "CLI"

	```bash
	gost -L unix://gost.sock -F tcp://192.168.1.1:8080
	```

=== "File (YAML)"

    ```yaml
	services:
	- name: service-0
	  addr: gost.sock
	  handler:
		type: unix
		chain: chain-0
	  listener:
		type: unix
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

### Redirect TCP Service To Local UDS Service

Redirect local TCP service `localhost:8080` to local UDS service `gost.sock`.

=== "CLI"

	```bash
	gost -L tcp://localhost:8080 -F unix://gost.sock 
	```

=== "File (YAML)"

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
		  addr: gost.sock
		  connector:
		    type: unix
		  dialer:
		    type: unix
	```

## Redirect To Another Local UDS Service

Redirect local UDS service `gost.sock` to another local UDS serivce `gost2.sock`

=== "CLI"

	```bash
	gost -L unix://gost.sock/gost2.sock
	```

=== "File (YAML)"

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

## Redirect To Remote UDS Service

Redirect local UDS service `gost.sock` to the UDS service `gost.sock` on the remote host `192.168.1.1` through forwarding chain. 

=== "CLI"

	```bash
	gost -L unix://gost.sock/gost.sock -F relay://192.168.1.1:8420
	```

=== "File (YAML)"

    ```yaml
	services:
	- name: service-0
	  addr: gost.sock
	  handler:
		type: unix
		chain: chain-0
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
