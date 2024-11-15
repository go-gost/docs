---
comments: true
---

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

## Redirect Types

### Redirect to TCP service

Redirect the local serial port `COM1` to TCP service `192.168.1.1:8080`.

=== "CLI"

	```bash
	gost -L serial://COM1 -F tcp://192.168.1.1:8080
	```

=== "File (YAML)"

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

### Redirect TCP Service To Local Serial Port Device

Redirect local TCP service `localhost:8080` to local serial port `COM1`.

=== "CLI"

	```bash
	gost -L tcp://localhost:8080 -F serial://COM1
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
		  addr: COM1
		  connector:
		    type: serial
		  dialer:
		    type: serial
	```

### Redirect To Another Local UDS Service

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

### Redirect To Remote Serial Port

Redirect local serial port `COM1` to the serial port `COM1` on the remote host `192.168.1.1` through forwarding chain. 

=== "CLI"

	```bash
	gost -L serial://COM1/COM1 -F relay://192.168.1.1:8420
	```

=== "File (YAML)"

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

## Data Record

The data sent and received by serial port can be recorded by [Recorder](../concepts/recorder.md).

=== "File (YAML)"

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

Record data to file `C:\serial.data`:

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

### Data Record Format

When recording data, you can set the format.

`direction` (bool, default=false)
:    Mark the data direction, `>` represents the data sent by the source port, and `<` represents the data received by the source port.

`timestampFormat` (string)
:    Timestamp format. When set, a timestamp will be added before each piece of data.

`hexdump` (bool, default=false)
:    The format of the data matches the output of `hexdump -C` on the command line.