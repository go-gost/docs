---
template: blog.html
author: ginuerzh
author_gh_user: ginuerzh
read_time: 30min
publish_date: 2022-10-21 22:00
---

GOST最初是在v2.9版本中引入对TUN(和TAP)设备的支持，在v3版本(beta.4)中又将实现方式由[songgao/water](https://github.com/songgao/water)库(TAP未变化)改为了[wireguard-go](https://git.zx2c4.com/wireguard-go)，并且增加了心跳和认证机制。

GOST中TUN设备的设计思想是简单轻量，因此没有添加过于复杂的配置，对数据也没有做过多的处理。只要能够满足一些特定的使用场景就达到目的了，如果需要更加复杂的应用完全可以通过wireguard来实现。

TUN设备可以有很多的用处，比较多的可能是用来构建VPN，这里就以讲一下基于GOST的TUN设备VPN组网方案。

## VPN组网

这个应该是所有VPN方案最常见的应用场景，通过VPN将多个局域网连接在一起互相可以访问。
例如在家可以访问到公司的内部网络或在公司能够访问到家里的网络，或者在外面出差可以同时访问到公司和家里的网络。

GOST中的TUN是客户端-服务器模式，必须要有一个服务器作为中转来连接和路由客户端。因此以上的组网方式需要有一台公网服务器，让家庭网络和公司网络都能够访问到。

这里假如公司网络中的一台机器C1(所在网络为192.168.100.0/24)，家庭网络中的一台机器C2(所在网络为192.168.101.0/24)和外面的另外一台机器C3(所在网络为192.168.102.0/24)均可以访问公网的服务器S(所在网络为192.168.1.0/24，公网IP为1.2.3.4)。首先在服务器S上运行TUN服务端(确保服务器的UDP端口8421开放):

=== "命令行"

    ```
    gost -L "tun://:8421?net=192.168.123.1/24"
    ```

=== "配置文件"

    ```yaml
    services:
    - name: tun
      addr: :8421
      handler:
        type: tun
      listener:
        type: tun
        metadata:
          net: 192.168.123.1/24
    ```

这里服务器S上TUN设备的IP为192.168.123.1。

再分别在C1，C2，C3机器上运行客户端。

### 客户端C1 - 192.168.123.2

=== "命令行"

    ```
    gost -L "tun://:0/1.2.3.4:8421?net=192.168.123.2/24&keepAlive=true&route=192.168.101.0/24"
    ```

=== "配置文件"

    ```yaml
    services:
    - name: tun
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
		  route: 192.168.101.0/24
      forwarder:
        nodes:
        - name: target-0
          addr: 1.2.3.4:8421
    ```

### 客户端C2 - 192.168.123.3

=== "命令行"

    ```
    gost -L "tun://:0/1.2.3.4:8421?net=192.168.123.3/24&keepAlive=true&route=192.168.100.0/24"
    ```

=== "配置文件"

    ```yaml
    services:
    - name: tun
      addr: :0
      handler:
        type: tun
        metadata:
          keepAlive: true
          ttl: 10s
      listener:
        type: tun
        metadata:
          net: 192.168.123.3/24
		  route: 192.168.100.0/24
      forwarder:
        nodes:
        - name: target-0
          addr: 1.2.3.4:8421
    ```

### 客户端C3 - 192.168.123.4

=== "命令行"

    ```
    gost -L "tun://:0/1.2.3.4:8421?net=192.168.123.4/24&keepAlive=true&route=192.168.100.0/24,192.168.101.0/24"
    ```

=== "配置文件"

    ```yaml
    services:
    - name: tun
      addr: :0
      handler:
        type: tun
        metadata:
          keepAlive: true
          ttl: 10s
      listener:
        type: tun
        metadata:
          net: 192.168.123.4/24
		  route: 192.168.100.0/24,192.168.101.0/24
      forwarder:
        nodes:
        - name: target-0
          addr: 1.2.3.4:8421
    ```

这里比较关键的是客户端的路由配置(route参数)：

在C1上设置路由为家庭网络192.168.101.0/24让C1可以访问到C2所在的网络，

在C2上设置路由为公司网络192.168.100.0/24让C2可以访问到C1所在网络，

在C3上设置路由为公司网络192.168.100.0/24和家庭网络192.168.101.0/24让C3可以同时访问到C1和C2所在的网络。

### iptables配置

经过以上配置后，各个TUN设备之间可以相互通讯，但要访问彼此所在的网络仅配置路由是不够的，还需要通过iptables来配置IP转发。

```
iptables -t nat -A POSTROUTING -s 192.168.123.0/24 ! -o tun0 -j MASQUERADE
```

当客户端添加了以上iptables规则后，此客户端所在的网络才能被其他的客户端访问。

## 心跳

上面的客户端均通过`keepAlive`参数开启心跳机制，这也是推荐的做法。心跳在这里有两方面的作用：

* GOST中TUN客户端和服务端使用UDP协议进行数据传输，通过心跳可以让客户端感知到网络的连通性。当心跳超时后(3个心跳周期时长)，客户端会重新初始化连接。
* 服务端通过维护一个动态路由表来进行客户端之间的数据包路由(客户端的TUN设备IP与客户端的UDP连接IP:PORT映射)，服务端通过客户端的心跳更新路由规则，当服务端重启后路由表会清除，客户端的心跳会让服务端重新添加到此客户端的路由规则，确保路由正常。

## 认证

以上的配置基本上就可以工作了，但这里面可能会存在一个问题，由于客户端TUN设置的IP是由客户端任意指定，当两个客户端使用同一个IP时就会出现冲突。为了更好的控制客户端的使用，可以在服务端开启认证机制。

```yaml hl_lines="6"
services:
- name: tun
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
  - username: 192.168.123.4
    password: userpass3
```

服务端通过使用认证器给每个客户端分配TUN设备IP和对应的认证码，这样控制权就交给了服务端，客户端必须使用服务端分配的IP(net参数)和认证码(passphrase参数)才能连接到网络中。

=== "命令行"

    ```
    gost -L "tun://:0/1.2.3.4:8421?net=192.168.123.2/24&keepAlive=true&route=192.168.101.0/24&passphrase=userpass1"
    ```

=== "配置文件"

    ```yaml
    services:
    - name: tun
      addr: :0
      handler:
        type: tun
        metadata:
          keepAlive: true
          ttl: 10s
		  passphrase: userpass1
      listener:
        type: tun
        metadata:
          net: 192.168.123.2/24
          route: 192.168.101.0/24
      forwarder:
        nodes:
        - name: target-0
          addr: 1.2.3.4:8421
    ```

## 安全传输

GOST中的TUN数据目前是明文传输的，如果需要加密，客户端可以使用转发链配合加密隧道来提高安全性。可以使用基于TCP的隧道，例如tls，wss，grpc等，也可以使用基于UDP的隧道，例如kcp, quic等。

=== "命令行"

    ```
    gost -L "tun://:0/:8421?net=192.168.123.2/24&keepAlive=true&route=192.168.101.0/24" -F relay+wss://1.2.3.4:443
    ```

=== "配置文件"

    ```yaml
    services:
    - name: tun
      addr: :0
      handler:
        type: tun
        chain: chain-0
	    metadata:
          keepAlive: true
          ttl: 10s
      listener:
        type: tun
        metadata:
          net: 192.168.123.2/24
          route: 192.168.101.0/24
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
          addr: 1.2.3.4:443
          connector:
            type: relay
          dialer:
            type: wss
    ```

使用转发链还有一个额外的好处，服务端可以不用暴露TUN服务的端口(8421)，仅需要暴露隧道的端口(443)，让VPN更加隐蔽。
