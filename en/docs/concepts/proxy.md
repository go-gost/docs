# Proxy, Forwarding and Tunnel

The two most commonly used functions in GOST are proxy and forwarding, and both functions require a carrier, which is a tunnel, or a data channel. These three concepts are different from each other, and there are similarities, and even the three can be converted into each other.

## Proxy

Generally speaking, it refers to a proxy protocol, such as HTTP, SOCKS5, etc., which is an application-layer data exchange protocol. Unlike general protocols, the server acts as an intermediary or a proxy here, and the client's request destination address is not A proxy service, but a third-party service negotiated through a proxy protocol. After establishing a connection with a third-party service, the proxy service is just a data forwarding role here.

Because the proxy uses a specific protocol, it can achieve many additional functions, such as identity authentication, permission control, etc.

## Forwarding

Generally it refers to port forwarding or port mapping, which establishes a connection between two different ports, usually a one-way mapping. The data sent to one port will eventually be sent to the other port intact, but the reverse is infeasible. Forwarding can be performed without any application protocol (pure TCP forwarding), or a specific forwarding protocol such as relay can be used. Forwarding can also be regarded as a kind of directional transparent proxy, the client cannot specify the target address, and even does not need to distinguish the forwarding service from the actual target service.

## Tunnel

Tunnel or data channel refers to a data stream that can be transmitted in both directions. Both ends of the tunnel can send and receive data at the same time to achieve full-duplex communication.

Any communication protocol that can implement this function can be used as a tunnel, such as TCP/UDP protocol, Websocket, HTTP/2, QUIC, etc. Even proxy and forwarding can be used as a channel by some means.

## Logical Layering

Although they are closely related, a slightly strict division is made in GOST. A GOST service or node is divided into two layers, the data channel layer and the data processing layer. The data channel layer corresponds to the dialer and the listener, and the data processing layer corresponds to the connector, the handler and the forwarder. Proxy mode or forward mode is distinguished according to whether a forwarder is used or not.

It is a logical division, specific protocols do not have these restrictions. For example, the HTTP/2 protocol can be used as both a data channel and a proxy, the Relay protocol has both proxy and forwarding functions, and even HTTP can be used as a data channel (pht).

=== "Relay Proxy Mode"

    Server
    ```
    gost -L relay+wss://gost:gost@:8420
    ```

	Client
    ```
    gost -L http://:8080 -F relay+wss://gost:gost@:8420
    ```

	The client uses the TCP data channel to receive the request through the HTTP proxy protocol, uses the Websocket data channel to forward it to the server through the relay protocol for processing, and enables authentication. Here data is transferred between two layers of proxies (HTTP proxy and Relay proxy).

=== "Relay Forwarding Mode"

    Server
    ```
    gost -L relay+wss://:8420/:18080
    ```

    Client
    ```
    gost -L tcp://:8080 -F relay+wss://:8420
    ```

	The client uses the TCP data channel to forward, and then uses the Websocket data channel to forward through the relay protocol, and the server finally sends the data to port 18080. Two-layer forwarding is used here, and finally the 8080 port of the client is mapped to the 18080 port of the server. There is no difference between accessing the 8080 port of the client and directly accessing the 18080 port of the server.

## Collaboration

Both proxy and forwarding can work individually, but using them in combination can have some different effects.

### Port Forwarding Using a Proxy

In some cases, a direct connection cannot be established between the two ports in port forwarding, which can be achieved through a forwarding chain.

```
gost -L tcp://:8080/192.168.1.1:80 -F http://192.168.1.2:8080
```

Port 8080 is indirectly mapped to 192.168.1.1:80 through the 192.168.1.2:8080 proxy node in the forwarding chain.

### Adding a Data Channel

Data channel can be dynamically added to existing services through forwarding.

#### HTTP-over-TLS

```
gost -L tls://:8443/:8080 -L http://:8080
```

Added a TLS encrypted data channel to the HTTP proxy service on port 8080 by using port forwarding of the TLS data channel.

Service on port 8443 is equivalent to:

```
gost -L https://:8443
```

#### Shadowsocks-over-KCP

```
gost -L kcp://:8338/:8388 -L ss://:8388
```

By using port forwarding of the KCP data channel, a KCP data channel is added to the shadowsocks proxy service on port 8388.

Service on port 8338 is equivalent to:

```
gost -L ss+kcp://:8338
```

### Remove a Data Channel

Contrary to the above example, the data channel of an existing service can also be removed by forwarding.

#### HTTPS to HTTP

Convert HTTPS proxy service to HTTP proxy service:

```
gost -L https://:8443
```

```
gost -L tcp://:8080 -F forward+tls://:8443
```

Service on port 8080 is equivalent to:

```
gost -L http://:8080
```

#### Shadowsocks-over-KCP to Shadowsocks

```
gost -L ss+kcp://:8338
```

```
gost -L ss://:8388 -F forward+kcp://:8338
```

Service on port 8388 is equivalent to:

```
gost -L ss://:8388
```

