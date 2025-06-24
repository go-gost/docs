---
comments: true
---

# TUN/TAP设备

## TUN

TUN的实现依赖于[wireguard-go](https://git.zx2c4.com/wireguard-go)。

!!! note "Windows系统"
    Windows需要下载[wintun](https://www.wintun.net/)。

关于TUN设备更详细的使用示例可以参考这篇[博文](https://gost.run/blog/2022/tun/)。

### 使用说明

```bash
gost -L="tun://[local_ip]:port[/remote_ip:port]?net=192.168.123.2/24&name=tun0&mtu=1420&route=10.100.0.0/16&gw=192.168.123.1"
```

`local_ip:port` (string, required)
:    本地监听的UDP隧道地址。

`remote_ip:port` (string)
:    目标UDP地址。本地TUN设备收到的IP包会通过UDP转发到此地址。

`net` (string, required)
:    指定TUN设备的地址(net=192.168.123.1/24)，也可以是逗号(,)分割的多地址(net=192.168.123.1/24,fd::1/64)。

`name` (string)
:    指定TUN设备的名字，默认值为系统预设。

`mtu` (int, default=1420)
:    设置TUN设备的MTU值。

`gw` (string)
:    设置TUN设备路由默认网关IP。

`route` (string)
:    逗号分割的路由列表，例如：10.100.0.0/16,172.20.1.0/24,1.2.3.4/32

`routes` (list)
:    特定网关路由列表，列表每一项为空格分割的CIDR地址和网关，例如：`10.100.0.0/16 192.168.123.2`

`peer` (string)
:    对端IP地址，仅MacOS系统有效

`keepalive` (bool)
:    开启心跳，仅客户端有效

`ttl` (duration)
:    心跳间隔时长，默认10s

`passphrase` (string)
:     客户端认证码，最多16个字符，仅客户端有效

`p2p` (bool)
:    点对点隧道，当开启后路由将被忽略，仅服务端有效

`dns` (string)
:    :material-tag: 3.1.0 

     设置tun接口的DNS服务器(Windows，Linux)

### 使用示例

**服务端**

=== "命令行"

    ```bash
    gost -L=tun://:8421?net=192.168.123.1/24
    ```

=== "配置文件"

    ```yaml
    services:
    - name: service-0
      addr: :8421
      handler:
        type: tun
      listener:
        type: tun
        metadata:
          name: tun0
          net: 192.168.123.1/24
          mtu: 1420
          dns: 192.168.1.1,192.168.100.1
    ```

**客户端**

=== "命令行(Linux/Windows)"

    ```bash
    gost -L=tun://:0/SERVER_IP:8421?net=192.168.123.2/24/64
    ```

=== "命令行(MacOS)"

    ```bash
    gost -L="tun://:0/SERVER_IP:8421?net=192.168.123.2/24&peer=192.168.123.1"
    ```

=== "配置文件"

    ```yaml
    services:
    - name: service-0
      addr: :0
      handler:
        type: tun
        metadata:
          keepAlive: true
          ttl: 10s
      listener:
        type: tun
        metadata:
          net: 192.168.123.2/24
          # peer: 192.168.123.1 # MacOS only
      forwarder:
        nodes:
        - name: target-0
          addr: SERVER_IP:8421
    ```

### 服务端路由

服务端可以通过设置路由表和网关，来访问客户端所在的网络。

#### 默认网关

服务端可以通过`gw`参数设置默认网关，来指定`route`参数的路由路径。

=== "命令行"

    ```bash
    gost -L="tun://:8421?net=192.168.123.1/24&gw=192.168.123.2&route=172.10.0.0/16,10.138.0.0/16"
    ```

=== "配置文件"

    ```yaml
    services:
    - name: service-0
      addr: :8421
      handler:
        type: tun
      listener:
        type: tun
        metadata:
          net: 192.168.123.1/24
          gw: 192.168.123.2
          route: 172.10.0.0/16,10.138.0.0/16
    ```

发往172.10.0.0/16和10.138.0.0/16网络的数据会通过TUN隧道转发给IP为192.168.123.2的客户端。

#### 特定网关路由

如果要针对每个路由设置特定的网关，可以通过`routes`参数来指定。

=== "配置文件"

    ```yaml hl_lines="10 11 12"
    services:
    - name: service-0
      addr: :8421
      handler:
        type: tun
      listener:
        type: tun
        metadata:
          net: 192.168.123.1/24
          routes:
          - 172.10.0.0/16 192.168.123.2
          - 10.138.0.0/16 192.168.123.3
    ```

发往172.10.0.0/16网络的数据会通过TUN隧道转发给IP为192.168.123.2的客户端。发往10.138.0.0/16网络的数据会通过TUN隧道转发给IP为192.168.123.3的客户端。

#### 路由器

服务端也可以使用[路由器](../concepts/router.md)模块来路由。

```yaml hl_lines="10"
services:
- name: service-0
  addr: :8421
  handler:
    type: tun
  listener:
    type: tun
    metadata:
      net: 192.168.123.1/24
      router: router-0
routers:
- name: router-0
  routes:
  - dst: 172.10.0.0/16
    gateway: 192.168.123.2
  - dst: 192.168.1.0/24
    gateway: 192.168.123.3
```

### 认证

服务端可以使用[认证器](../concepts/auth.md)来对客户端进行认证。

**服务端**

```yaml hl_lines="6"
services:
- name: service-0
  addr: :8421
  handler:
    type: tun
    auther: tun
  listener:
    type: tun
    metadata:
      net: 192.168.123.1/24

authers:
- name: tun
  auths:
  - username: 192.168.123.2
    password: userpass1
  - username: 192.168.123.3
    password: userpass2
```

认证器的用户名为给客户端分配的IP。

**客户端**

=== "命令行"

    ```bash
    gost -L "tun://:0/SERVER_IP:8421?net=192.168.123.2/24&passphrase=userpass1"
    ```

=== "配置文件"

    ```yaml hl_lines="10"
    services:
    - name: service-0
      addr: :8421
      handler:
        type: tun
        metadata:
          keepAlive: true
          ttl: 10s
          passphrase: "userpass1"
      listener:
        type: tun
        metadata:
          net: 192.168.123.2/24
      forwarder:
        nodes:
        - name: target-0
          addr: SERVER_IP:8421
    ```

客户端通过`passphrase`选项指定认证码。

!!! tip "认证与心跳"
    当使用认证时，建议客户端开启心跳，认证信息会在心跳包中一起发送给服务端。当服务端重启后，心跳包会让连接恢复。

!!! note "认证码长度限制"
    认证码最长支持16个字符，当客户端超过此长度限制时只会使用前16个字符。

!!! note "多IP与认证"
    如果客户端通过`net`参数指定了多个网络，例如`net=192.168.123.2/24,fd::2/64`，当服务端开启认证后，客户端的所有IP均通过认证(使用相同的passphrase)才认为是认证通过。

!!! caution "安全传输"
    TUN隧道的数据均为明文传输，包括认证信息。可以使用转发链利用加密隧道来使数据传输更安全。


### 构建基于TUN设备的VPN (Linux)

!!! tip
    `net`所指定的地址可能需要根据实际情况进行调整。

#### 创建TUN设备并建立UDP隧道

**服务端**

=== "命令行"

    ```bash
    gost -L=tun://:8421?net=192.168.123.1/24
    ```

=== "配置文件"

    ```yaml
    services:
    - name: service-0
      addr: :8421
      handler:
        type: tun
      listener:
        type: tun
        metadata:
          net: 192.168.123.1/24
    ```

**客户端**

=== "命令行"

    ```bash
    gost -L=tun://:0/SERVER_IP:8421?net=192.168.123.2/24
    ```

=== "配置文件"

    ```yaml
    services:
    - name: service-0
      addr: :8421
      handler:
        type: tun
      listener:
        type: tun
        metadata:
          net: 192.168.123.1/24
      forwarder:
        nodes:
        - name: target-0
          addr: SERVER_IP:8421
    ```

当以上命令运行正常后，可以通过`ip addr`命令来查看创建的TUN设备：

```
$ ip addr show tun0
2: tun0: <POINTOPOINT,MULTICAST,NOARP,UP,LOWER_UP> mtu 1420 qdisc pfifo_fast state UNKNOWN group default qlen 500
    link/none 
    inet 192.168.123.2/24 scope global tun0
       valid_lft forever preferred_lft forever
    inet6 fe80::d521:ad59:87d0:53e4/64 scope link flags 800 
       valid_lft forever preferred_lft forever
```

可以通过在客户端执行`ping`命令来测试一下隧道是否连通：

```
$ ping 192.168.123.1
64 bytes from 192.168.123.1: icmp_seq=1 ttl=64 time=9.12 ms
64 bytes from 192.168.123.1: icmp_seq=2 ttl=64 time=10.3 ms
64 bytes from 192.168.123.1: icmp_seq=3 ttl=64 time=7.18 ms
```

如果能ping通，说明隧道已经成功建立。


#### iperf3测试

**服务端**

```bash
iperf3 -s
```

**客户端**

```bash
iperf3 -c 192.168.123.1
```

#### 路由规则和防火墙设置

如果想让客户端访问到服务端的网络，还需要根据需求设置相应的路由和防火墙规则。例如可以将客户端的所有外网流量转发给服务端处理

**服务端**

开启IP转发并设置防火墙规则

```bash
sysctl -w net.ipv4.ip_forward=1

iptables -t nat -A POSTROUTING -s 192.168.123.0/24 ! -o tun0 -j MASQUERADE
iptables -A FORWARD -i tun0 ! -o tun0 -j ACCEPT
iptables -A FORWARD -o tun0 -j ACCEPT
```

**客户端**

设置路由规则

!!! caution "谨慎操作"
    以下操作会更改客户端的网络环境，除非你知道自己在做什么，请谨慎操作！

```bash
ip route add SERVER_IP/32 dev eth0   # 请根据实际情况替换SERVER_IP和eth0
ip route del default   # 删除默认的路由
ip route add default via 192.168.123.2  # 使用新的默认路由
```

## TAP

TAP的实现依赖于[songgao/water](https://github.com/songgao/water)库。

!!! note "Windows系统"
    Windows下需要安装tap驱动后才能使用，可以选择安装[OpenVPN/tap-windows6](https://github.com/OpenVPN/tap-windows6)或[OpenVPN client](https://github.com/OpenVPN/openvpn)，也可以直接从[这里](https://build.openvpn.net/downloads/releases/)下载安装包。

!!! note "注意"
    TAP目前不支持MacOS。

### 使用说明

```bash
gost -L="tap://[local_ip]:port[/remote_ip:port]?net=192.168.123.2/24&name=tap0&mtu=1420&route=10.100.0.0/16&gw=192.168.123.1"
```

`local_ip:port` (string, required)
:    本地监听的UDP隧道地址。

`remote_ip:port` (string)
:    目标UDP地址。本地TAP设备收到的数据会通过UDP转发到此地址。

`net` (string)
:    指定TAP设备的地址。

`name` (string)
:    指定TAP设备的名字，默认值为系统预设。

`mtu` (int, default=1420)
:    设置TAP设备的MTU值。

`gw` (string)
:    设置TAP设备路由默认网关IP。

`route` (string)
:    逗号分割的路由列表，例如：10.100.0.0/16,172.20.1.0/24,1.2.3.4/32

`routes` (list)
:    特定网关路由列表，列表每一项为空格分割的CIDR地址和网关，例如：`10.100.0.0/16 192.168.123.2`

### 使用示例

**服务端**

=== "命令行"

    ```bash
    gost -L=tap://:8421?net=192.168.123.1/24
    ```

=== "配置文件"

    ```yaml
    services:
    - name: service-0
      addr: :8421
      handler:
        type: tap
      listener:
        type: tap
        metadata:
          name: tap0
          net: 192.168.123.1/24
          mtu: 1420
    ```

**客户端**

=== "命令行"

    ```bash
    gost -L=tap://:0/SERVER_IP:8421?net=192.168.123.2/24
    ```

=== "配置文件"

    ```yaml
    services:
    - name: service-0
      addr: :0
      handler:
        type: tap
      listener:
        type: tap
        metadata:
          net: 192.168.123.2/24
      forwarder:
        nodes:
        - name: target-0
          addr: SERVER_IP:8421
    ```

## 基于TCP的TUN/TAP隧道

GOST中的TUN/TAP隧道默认是基于UDP协议进行数据传输。

如果想使用TCP传输，可以选择采用以下几种方式：

### 转发链

可以通过使用转发链进行转发，用法与UDP本地端口转发类似。

此方式比较灵活通用，推荐使用。

**服务端**

=== "命令行"

    ```bash
    gost -L=tun://:8421?net=192.168.123.1/24 -L relay+wss://:8443?bind=true
    ```

=== "配置文件"

    ```yaml
    services:
    - name: service-0
      addr: :8421
      handler:
        type: tun
      listener:
        type: tun
        metadata:
          net: 192.168.123.1/24
    - name: service-1
      addr: :8443
      handler:
        type: relay
        metadata:
          bind: true
      listener:
        type: wss
    ```

**客户端**

=== "命令行"

    ```bash
    gost -L=tun://:0/:8421?net=192.168.123.2/24 -F relay+wss://SERVER_IP:8443
    ```

=== "配置文件"

    ```yaml
    services:
    - name: service-0
      addr: :8421
      handler:
        type: tun
        chain: chain-0
      listener:
        type: tun
        metadata:
          net: 192.168.123.2/24
      forwarder:
        nodes:
        - name: target-0
          addr: :8421
    chains:
    - name: chain-0
      hops:
      - name: hop-0
        nodes:
        - name: node-0
          addr: SERVER_IP:8443
          connector:
            type: relay
          dialer:
            type: wss
    ```

### 第三方转发工具

[udp2raw-tunnel](https://github.com/wangyu-/udp2raw-tunnel)。