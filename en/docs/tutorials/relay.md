---
comments: true
---

# Relay Protocol

The Relay protocol is a GOST proprietary protocol with both proxy and forwarding functions, which can process TCP and UDP data at the same time, and supports user authentication.

!!! note
	The Relay protocol itself does not have the encryption function. If the data needs to be encrypted, it can be used in conjunction with the encrypted tunnel (such as tls, wss, quic, etc.).

## Proxy

The Relay protocol can be used as a proxy protocol like HTTP/SOCKS5.

### Server

	```
	gost -L relay+tls://username:password@:12345
	```

### Client

	```
	gost -L :8080 -F relay+tls://username:password@:12345?nodelay=false
	```

!!! tip "Delayed Sending"
    By default, the relay protocol will wait for the request data, and when the request data is received, the protocol header information will be sent to the server together with the request data. When the `nodelay` option is set to `true`, the protocol header information will be sent to the server immediately without waiting for the client's request.

It can also be used with port forwarding to support simultaneous forwarding of TCP and UDP data

### Server

```
gost -L relay://:12345
```

### Client

```
gost -L udp://:1053/:53 -L tcp://:1053/:53 -F relay://:12345
```

## Port Forwarding

The Relay service itself can also act as a port forwarding service.

### Server

```
gost -L relay://:12345/:53
```

### Client

```
gost -L udp://:1053 -L tcp://:1053 -F relay://:12345
```

## Remote Port Forwarding

The Relay protocol implements the `BIND` function similar to SOCKS5 and can be used with remote port forwarding services.

The BIND function is not enabled by default and needs to be enabled by setting the `bind` option to `true`.

### Server

```
gost -L relay://:12345?bind=true
```

### Client

```
gost -L rtcp://:2222/:22 -L rudp://:10053/:53 -F relay://:12345
```