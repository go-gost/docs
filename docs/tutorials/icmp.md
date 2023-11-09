# ICMP通道

[ICMP](https://en.wikipedia.org/wiki/Internet_Control_Message_Protocol)通道是利用ICMP协议的Echo类型报文(ping命令所采用)进行数据传输。由于ICMP类似于UDP，是一种不可靠的协议，存在丢包和乱序情况，因此不能直接用于流式数据传输。GOST在ICMP之上利用QUIC协议来实现安全可靠的数据传输，因此ICMP通道可以看作是QUIC-over-ICMP数据通道。

!!! note "ICMPv6"
    ICMP通道目前仅支持ICMPv4，不支持ICMPv6。

!!! tip "关闭系统默认Echo响应"
    在Linux系统中可以通过以下命令关闭系统本身的echo响应数据，减少不必要的数据传输。此为可选操作，GOST会自动丢弃无效数据包。
	```
	echo 1 > /proc/sys/net/ipv4/icmp_echo_ignore_all
	```

## 使用方法

服务端

```bash
gost -L relay+icmp://:0
```

客户端

```bash
gost -L :8080 -F "relay+icmp://server_ip:12345?keepalive=true&ttl=10s"
```

!!! note 权限
    执行以上命令需要root权限。

## 客户端标识

ICMP与通常的传输层协议，例如TCP，UDP不同，没有端口的概念，但为了区分不同的客户端，需要对客户端进行标识。GOST中采用IP+ID的方式来标识一个客户端，IP即客户端IP地址，ID是ICMP Echo报文中的Identifier字段值。

在客户端可以通过类似于指定端口的方式来指定ID，例如上面例子中的12345。也可以设置为0，GOST会自动生成一个随机ID。对于服务端这个值无效。