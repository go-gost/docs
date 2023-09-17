# Serial Port Redirector

Serial port redirector can redirect the local serial port device to a TCP service or another serial port device. The forwarding chain is still valid in this scenario.

!!! caution "Limitation"
	When redirecting to a remote serial port, the last node at the end of the forwarding chain must be the `relay` protocol.

!!! tip "Port Format"
	The port name, baud rate, and parity check can be specified in the serial port address. The baud rate and parity check can be omitted: `port[,baud[,parity]]`

	The default baud rate is 9600.

	Parity type: `odd` - odd parity，`even` - even parity，`none` - no parity, the default is no parity.

	* Port name only
	```
	serial://COM1/COM2
	```

	* Port name and baud rate
	```
	serial://COM1,9600/COM2
	```

	* Port name, baud rate and parity
	```
	serial://COM1,9600,odd/COM2
	```

## Redirect to TCP service

Redirect the local serial port `COM1` to TCP service `192.168.1.1:80`.

=== "CLI"

	```bash
	gost -L serial://COM1/192.168.1.1:80
	```

=== "File (YAML)"

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

## Redirect To Another Local UDS Service

Redirect local serial port `COM1` to another local serial port `COM2`

=== "CLI"

	```bash
	gost -L serial://COM1,9600,odd/COM2
	```

=== "File (YAML)"

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

## Redirect To Remote Serial Port

Redirect local serial port `COM1` to the serial port `COM1` on the remote host `192.168.1.1` through forwarding chain. 

=== "CLI"

	```bash
	gost -L unix://COM1/COM2 -F relay://192.168.1.1:8420
	```

=== "File (YAML)"

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
