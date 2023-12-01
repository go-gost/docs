---
comments: true
---

# ICMP Tunnel

The [ICMP](https://en.wikipedia.org/wiki/Internet_Control_Message_Protocol) tunnel uses the Echo type message of the ICMP protocol (used by the ping command) for data transmission. Since ICMP is similar to UDP, it is an unreliable protocol with packet loss and disorder, so it cannot be directly used for streaming data transmission. GOST uses the QUIC protocol on top of ICMP to achieve secure and reliable data transmission, so the ICMP tunnel can be regarded as a QUIC-over-ICMP data tunnel.

!!! note "ICMPv6"
	The ICMP tunnel currently only supports ICMPv4, not ICMPv6.

!!! tip "Turn off the system default Echo response"
	In the Linux system, you can use the following command to close the echo response data of the system itself to reduce unnecessary data transmission. This is optional, GOST will automatically drop invalid packets.
	```
	echo 1 > /proc/sys/net/ipv4/icmp_echo_ignore_all
	```

## Usage

### Server

```bash
gost -L relay+icmp://:0
```

### Client

```bash
gost -L :8080 -F "relay+icmp://server_ip:12345?keepalive=true&ttl=10s"
```

!!! note "root"
	Root privileges are required to execute the above commands.

## Client ID

Unlike common transport layer protocols, such as TCP and UDP, ICMP has no concept of ports, but in order to distinguish different clients, clients need to be identified. GOST uses IP+ID to identify a client. IP is the IP address of the client, and ID is the value of the Identifier field in the ICMP Echo packet.

The ID can be specified on the client side in a manner similar to specifying the port, such as 12345 in the above example. It can also be set to 0, GOST will automatically generate a random ID. This value is invalid for the server.