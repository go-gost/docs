---
comments: true
---

#  TUN2SOCKS 

:material-tag: 3.2.0

GOST对tun2socks的支持依赖于[xjasonlyu/tun2socks](https://github.com/xjasonlyu/tun2socks)库。

在之前的TUN相关教程中([TUN/TAP设备](tuntap.md)和[路由隧道](routing-tunnel.md))TUN是被用来建立点对点隧道，通过TUN设备接收到网络层IP数据包，一般不会对数据包再做处理，直接通过隧道透传到对端从而实现组网功能。

而tun2socks则在TUN设备之上又完整的实现了网络协议栈，对接收到的IP数据包又通过协议栈处理，最终解析出传输层TCP/UDP数据包。从使用角度上讲，tun2socks与[透明代理](redirect.md)的功能类似，但通用性和使用便利性上要比后者好很多。

!!! note "系统限制"
    TUNGO目前支持Linux，Windows，MacOS系统。

!!! note "Windows系统"
    Windows需要下载[wintun](https://www.wintun.net/)。

## TUNGO - TUN2SOCKS for GOST

GOST中的tun2socks模块称为TUNGO，在原tun2socks基础之上，利用GOST现有的功能模块，例如转发链，流量嗅探，分流等可以对流量做更精准的控制。

这里假设系统的主网络接口为`eth0`，网关为192.168.1.1。

### Linux

=== "命令行"

    ```sh
    gost -L "tungo://:0?name=tungo&net=192.168.123.1/24&mtu=1420&dns=1.1.1.1" \
         -F "relay+wss://SERVER_IP:443?interface=eth0"
    ```
    
    更新路由表：

    ```sh
    # 删除默认网关
    ip route delete default
    # 将eth0设为备用网关
    ip route add default via 192.168.1.1 dev eth0 metric 10
    # 将tungo设为主网关。如果eht0的metric大于1，则以上两条命令可以不执行。
    ip route add default dev tungo metric 1
    # IPv6
    # ip -6 route add default dev tungo metric 1
    ```

=== "配置文件"

    ```yaml
    services:
    - name: service-0
      addr: :0
      handler:
        type: tungo
        chain: chain-0
        metadata:
          udpTimeout: 30s   # UDP会话超时时长
      listener:
        type: tungo
        metadata:
          name: tungo    # default name is tungo
          net: 192.168.123.1/24
          mtu: 1420      # default mtu is 1420
          dns: 1.1.1.1   # dns server
      metadata:
        postUp:   # 通过service的postUp自动更新路由表
        - ip route delete default
        - ip route add default via 192.168.1.1 dev eth0 metric 10
        - ip route add default dev tungo metric 1
        # - ip -6 route add default dev tungo metric 1

    chains:
    - name: chain-0
      hops:
      - name: hop-0
        metadata:
          interface: eth0
        nodes:
        - name: node-0
          addr: SERVER_IP:443
          connector:
            type: relay
          dialer:
            type: wss
    ```

### Windows

=== "命令行"

    ```sh
    gost -L "tungo://:0?name=tungo&net=192.168.123.1/24&mtu=1420&dns=1.1.1.1" \
         -F "relay+wss://SERVER_IP:443?interface=eth0"
    ```
    
    更新路由表：

    ```sh
    netsh interface ipv4 add route 0.0.0.0/0 tungo 192.168.123.1 metric=1
    ```

=== "配置文件"

    ```yaml
    services:
    - name: service-0
      addr: :0
      handler:
        type: tungo
        chain: chain-0
        metadata:
          udpTimeout: 30s   # UDP会话超时时长
      listener:
        type: tungo
        metadata:
          name: tungo    # default name is tungo
          net: 192.168.123.1/24
          mtu: 1420      # default mtu is 1420
          dns: 1.1.1.1   # dns server
      metadata:
        postUp: # 通过service的postUp自动更新路由表
        - netsh interface ipv4 add route 0.0.0.0/0 tungo 192.168.123.1 metric=1

    chains:
    - name: chain-0
      hops:
      - name: hop-0
        metadata:
          interface: eth0
        nodes:
        - name: node-0
          addr: SERVER_IP:443
          connector:
            type: relay
          dialer:
            type: wss
    ```

### MacOS

=== "命令行"

    ```sh
    gost -L "tungo://:0?name=tungo&net=192.168.123.1/24&mtu=1420&route=1.0.0.0/8,2.0.0.0/8" \
         -F "relay+wss://SERVER_IP:443?interface=eth0"
    ```

=== "配置文件"

    ```yaml
    services:
    - name: service-0
      addr: :0
      handler:
        type: tungo
        chain: chain-0
        metadata:
          udpTimeout: 30s   # UDP会话超时时长
      listener:
        type: tungo
        metadata:
          name: tungo    # default name is tungo
          net: 192.168.123.1/24
          mtu: 1420      # default mtu is 1420
          dns: 1.1.1.1   # dns server
      metadata:
        postUp: # 通过service的postUp自动更新路由表
        - route add -net 1.0.0.0/8 192.168.123.1
        - route add -net 2.0.0.0/8 192.168.123.1

    chains:
    - name: chain-0
      hops:
      - name: hop-0
        metadata:
          interface: eth0
        nodes:
        - name: node-0
          addr: SERVER_IP:443
          connector:
            type: relay
          dialer:
            type: wss
    ```

## 流量嗅探与分流

与[透明代理](redirect.md)类似，tungo处理的数据包为原始TCP/UDP数据，如果需要对流量做分流，转发或代理会比较麻烦。通过组合使用[流量嗅探](sniffing.md)和[分流器](../concepts/bypass.md)功能，可以更方便的对流量做处理。


=== "命令行"

    ```sh
    gost -L "tungo://:0?name=tungo&net=192.168.123.1/24&mtu=1420&dns=1.1.1.1&interface=eth0&sniffing=true" \
         -F "relay+wss://SERVER_IP:443?interface=eth0&bypass=example.com"
    ```

=== "配置文件"

    ```yaml hl_lines="8-11 20 26 28"
    services:
    - name: service-0
      addr: :0
      handler:
        type: tungo
        chain: chain-0
        metadata:
          sniffing: true
          sniffing.udp: true
          sniffing.timeout: 1s
          sniffing.fallback: true
      listener:
        type: tungo
        metadata:
          name: tungo    # default name is tungo
          net: 192.168.123.1/24
          mtu: 1420      # default mtu is 1420
          dns: 1.1.1.1   # dns server
      metadata:
        interface: eth0

    chains:
    - name: chain-0
      hops:
      - name: hop-0
        bypass: bypass-0
        metadata:
          interface: eth0
        nodes:
        - name: node-0
          addr: SERVER_IP:443
          connector:
            type: relay
          dialer:
            type: wss

    bypasses:
    - name: bypass-0
      matchers:
      - example.com
    ```

通过`sniffing`选项开启流量嗅探，目前支持对HTTP，TLS，DNS(sniffing.udp=true)流量的嗅探。通过设置bypass，对于example.com的请求会直接通过service中`metadata.interface`选项所指定的接口`eth0`发出，其他流量则使用转发链进行转发。