# Relay协议

Relay协议是GOST特有的一个协议，同时具有代理和转发功能，可同时处理TCP和UDP的数据，并支持用户认证。

!!! note
    Relay协议本身不具备加密功能，如果需要对数据进行加密传输，可以配合具有加密功能的数据通道(例如tls，wss，quic等)使用。

## 代理

Relay协议可以像HTTP/SOCKS5一样用作代理协议。

### 服务端

```
gost -L relay+tls://username:password@:12345
```

### 客户端

```
gost -L :8080 -F relay+tls://username:password@:12345?nodelay=false
```

!!! tip "延迟发送"
    默认情况下relay协议会等待请求数据，当收到请求数据后会把协议头部信息与请求数据一起发给服务端。当此`nodelay`参数设为`true`后，协议头部信息会立即发给服务端，不再等待客户端的请求。

也可以配合端口转发支持同时转发TCP和UDP数据

### 服务端

```
gost -L relay://:12345
```

### 客户端

```
gost -L udp://:1053/:53 -L tcp://:1053/:53 -F relay://:12345
```

## 端口转发

Relay服务本身也可以作为端口转发服务。

### 服务端

```
gost -L relay://:12345/:53
```

### 客户端

```
gost -L udp://:1053 -L tcp://:1053 -F relay://:12345
```

## 远程端口转发

Relay协议实现了类似于SOCKS5的BIND功能，可以配合远程端口转发服务使用。

BIND功能默认未开启，需要通过设置`bind`参数为true来开启。

### 服务端

```
gost -L relay://:12345?bind=true
```

### 客户端

```
gost -L rtcp://:2222/:22 -L rudp://:10053/:53 -F relay://:12345
```