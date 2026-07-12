---
authors:
  - ginuerzh
categories:
  - Serial
readtime: 15
date: 2023-10-13
comments: true
---

# Serial Port Redirector

[Serial ports](https://en.wikipedia.org/wiki/Serial_port) are largely absent from modern personal computers, but can still be found on industrial devices and embedded systems. Since serial communication differs significantly from TCP/IP, debugging and analyzing serial-based protocols requires different approaches.

GOST added [serial port redirector](https://gost.run/tutorials/serial/) functionality after v3.0.0-rc8. This enables forwarding local serial port data to a TCP service, or TCP service data to a local serial port, or even forwarding between remote serial ports. Serial forwarding enables two use cases: remote serial communication and serial data monitoring.

<!-- more -->

!!! tip "Virtual Serial Ports"

    Virtual serial ports allow software to communicate via serial ports even without physical hardware.

    On Windows, use [Null-modem emulator](https://com0com.sourceforge.net/).

    On Linux, create virtual serial ports with socat:
    ```sh
    socat -d -d pty,raw,echo=0 pty,raw,echo=0
    ```

## Remote Serial Communication

Serial communication is point-to-point and requires physical proximity. Serial forwarding allows accessing serial ports like internet services. Two approaches: forward to a TCP service, or forward to a remote serial device.

### Forwarding to a TCP Service

Since serial data transmission is similar to TCP (stream-based), serial data can be forwarded to a TCP service, effectively converting serial communication to network communication.

```sh
gost -L serial://COM1 -F tcp://192.168.1.1:8080
```

### Forwarding to a Remote Serial Device

Normally, software communicates with a serial device through a local serial port. On Windows, this is typically `COM1`, `COM2`, etc. On Linux, it's `/dev/ttyS*` (e.g., `/dev/ttyS0`) or `/dev/ttyUSB0` for USB-to-serial adapters.

When the device is not physically nearby, serial forwarding can relay the serial port from the connected host to any remote host.

Assume device-connected host A (`192.168.1.1`) has a physical serial port `COM1`. Remote host B (`192.168.1.2`) has virtual serial ports `COM1` and `COM2`. We want software on host B to communicate with the device via virtual port `COM2`.

First, start a relay service on host A:

```sh
gost -L relay://:8420
```

Then, on host B, map COM1 to host A's COM1:

```sh
gost -L serial://COM1/COM1 -F relay://192.168.1.1:8420
```

Data sent through host B's COM2 is now forwarded via the relay service to host A's COM1, enabling remote serial communication.

## Serial Data Monitoring

For TCP/IP networks, tools like [Wireshark](https://www.wireshark.org/) and [tcpdump](https://www.tcpdump.org/) can capture and analyze data in real time, but these don't support serial ports. Serial monitoring typically requires specialized tools.

Serial ports have another peculiarity: a port can only be opened by one process at a time. This makes it difficult to capture communication data between software and a device. [Serial Port Monitor](https://www.com-port-monitoring.com/) is one of the few tools that can monitor an occupied serial port.

Instead of direct monitoring, serial forwarding can achieve the same goal indirectly. Using virtual serial ports, assume host A has a physical serial port `COM1` connected to a device, and virtual ports `COM3` and `COM4`. Configure the software to use `COM4`, and forward `COM1` to `COM3`, capturing data during forwarding:

```yaml
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
      addr: COM3
recorders:
- name: recorder-0
  file:
    path: 'C:\serial.data'
```

The recorder logs all communication data to `C:\serial.data`. The output format:

```text
>2023-09-18 10:16:25.117
00000000  60 02 a0 01 70 02 b0 01  c0 01 c0 01 40 02 30 01  |`...p.......@.0.|
...
<2023-09-18 10:16:25.120
00000000  d0 00 d0 00 10 01 10 02  50 01 e0 00 00 01 d0 01  |........P.......|
...
```

`>` indicates data sent from the source port (COM1 → COM3), `<` indicates data received by the source port (COM1 ← COM3).
