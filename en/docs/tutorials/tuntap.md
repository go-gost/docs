# TUN/TAP Device

!!! note "Windows"
    You need to install the tap driver [OpenVPN/tap-windows6](https://github.com/OpenVPN/tap-windows6) or [OpenVPN client](https://github.com/OpenVPN/openvpn) for Windows.


## TUN

### Usage

```
gost -L="tun://[method:password@][local_ip]:port[/remote_ip:port]?net=192.168.123.2/24&name=tun0&mtu=1350&route=10.100.0.0/16&gw=192.168.123.1"
```

`method:password` (string)
:    encryption method and password for UDP tunnel. Supported methods are the same as [shadowsocks/go-shadowsocks2](https://github.com/shadowsocks/go-shadowsocks2).

`local_ip:port` (string, required)
:    Local UDP tunnel listen address.

`remote_ip:port` (string)
:    Remote UDP server address, IP packets received by the local TUN device will be forwarded to the remote server via UDP tunnel.

`net` (string, required)
:    CIDR IP address of the TUN device, such as: 192.168.123.1/24.

`name` (string)
:    TUN device name.

`mtu` (int, default=1350)
:    MTU for TUN device.

`routes` (string)
:    Comma-separated routing table, such as: 10.100.0.0/16,172.20.1.0/24,1.2.3.4/32.

`gw` (string)
:    Default routing gateway.


### Server Side Routing

The server can access the client network by setting up routing table and gateway.

#### Default gateway

The server can set the default gateway through the `gw` option to specify the gateway of the routes in route parameter.

```
gost -L="tun://:8421?net=192.168.123.1/24&gw=192.168.123.2&route=172.10.0.0/16,10.138.0.0/16"
```

Packets send to network 172.10.0.0/16 and 10.138.0.0/16 will be forwarded to the client with the IP 192.168.123.2 through the TUN tunnel.

### TUN-based VPN (Linux)

!!! tip
    The value specified by `net` option may need to be adjusted according to your actual situation.

#### Create a TUN Device and Establish a UDP Tunnel

##### Server

```
gost -L tun://:8421?net=192.168.123.1/24
```

##### Client

```
gost -L tun://:8421/SERVER_IP:8421?net=192.168.123.2/24
```

When no error occurred, you can use the `ip addr` command to inspect the created TUN device:

```
$ ip addr show tun0
2: tun0: <POINTOPOINT,MULTICAST,NOARP,UP,LOWER_UP> mtu 1350 qdisc pfifo_fast state UNKNOWN group default qlen 500
    link/none 
    inet 192.168.123.2/24 scope global tun0
       valid_lft forever preferred_lft forever
    inet6 fe80::d521:ad59:87d0:53e4/64 scope link flags 800 
       valid_lft forever preferred_lft forever
```

Now you can `ping` the server address:

```
$ ping 192.168.123.1
64 bytes from 192.168.123.1: icmp_seq=1 ttl=64 time=9.12 ms
64 bytes from 192.168.123.1: icmp_seq=2 ttl=64 time=10.3 ms
64 bytes from 192.168.123.1: icmp_seq=3 ttl=64 time=7.18 ms
```

#### iperf3 Testing

##### Server

```
$ iperf3 -s
```

##### Client

```
$ iperf3 -c 192.168.123.1
```

#### IP Routing and Firewall Rules

If you want the client to access the server network, you need to set the corresponding routing table and firewall rules according to your needs. For example, all the client external network traffic can be forwarded to the server.

##### Server

Enable IP forwarding and set up firewall rules

```
$ sysctl -w net.ipv4.ip_forward=1

$ iptables -t nat -A POSTROUTING -s 192.168.123.0/24 ! -o tun0 -j MASQUERADE
$ iptables -A FORWARD -i tun0 ! -o tun0 -j ACCEPT
$ iptables -A FORWARD -o tun0 -j ACCEPT
```

##### Client

Set up firewall rules

!!! caution
    The following operations will change the client's network environment, unless you know what you are doing, please be careful!

```
$ ip route add SERVER_IP/32 dev eth0   # replace the SERVER_IP and eth0
$ ip route del default   # delete the default route
$ ip route add default via 192.168.123.2  # add new default route
```

## TAP

!!! note "Limitation"
    TAP devices are not supported by macOS.

### Usage

```
gost -L="tap://[method:password@][local_ip]:port[/remote_ip:port]?net=192.168.123.2/24&name=tap0&mtu=1350&route=10.100.0.0/16&gw=192.168.123.1"
```

## TUN/TAP tunnel over TCP

The TUN/TAP tunnel in GOST is based on the UDP protocol by default.

If you want to use TCP, you can choose the following methods:

### Forwarding Chain

You can add a forwarding chain to forward UDP data, analogous to UDP port forwarding.

This method is more flexible and general, and is recommended.

##### Server

```
gost -L tun://:8421?net=192.168.123.1/24 -L relay://:1080?bind=true
```

##### Client

```
gost -L tun://:0/:8421?net=192.168.123.2/24 -F relay://SERVER_IP:1080
```

### Port Forwarding

Based on UDP port forwarding and forwarding chain.

##### Server

```
gost -L tun://:8421?net=192.168.123.1/24 -L relay://:1080
```

##### Client

```
gost -L tun://:8421/:8420?net=192.168.123.2/24 -L udp://:8420/:8421?keepAlive=true -F relay://server_ip:1080
```

### Third-party tools

[udp2raw-tunnel](https://github.com/wangyu-/udp2raw-tunnel).