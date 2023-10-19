# 反向代理隧道

在上一篇[反向代理](/tutorials/reverse-proxy/)教程中，利用端口转发实现了简单的反向代理功能，在本篇中将利用隧道功能实现类似于[Cloudflare Tunnel](https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/)的增强版反向代理。

## 隧道(Tunnel)

隧道是一条服务端和客户端之间的(逻辑上的)通道，服务端可以开启一个额外的公共入口点(EntryPoint)，由入口点进入的流量会通过隧道发送给客户端。每个隧道有一个唯一的ID(合法的UUID)，一个隧道可以有多个连接(连接池)来实现隧道的高可用性。

![Reverse Proxy - Remote TCP Port Forwarding](/images/reverse-proxy-rtcp2.png) 

### 服务端

=== "命令行"

    ```bash
    gost -L "relay://:8443?entryPoint=:80&tunnel=.example.com:4d21094e-b74c-4916-86c1-d9fa36ea677b,example.org:ac74d9dd-3125-442a-a7c1-f9e49e05faca"
    ```

    命令行中使用`tunnel`选项定义Ingress规则。`tunnel`选项的值为`,`分割的规则列表，每个规则为`:`分割的主机名和隧道ID。

=== "配置文件"

    ```yaml hl_lines="7 8"
    services:
    - name: service-0
      addr: :8443
      handler:
        type: relay
        metadata:
          entryPoint: ":80"
          ingress: ingress-0
      listener:
        type: tcp

    ingresses:
    - name: ingress-0
      rules:
      - hostname: ".example.com"
        endpoint: 4d21094e-b74c-4916-86c1-d9fa36ea677b
      - hostname: "example.org"
        endpoint: ac74d9dd-3125-442a-a7c1-f9e49e05faca
    ```

`entryPoint`指定流量的(公共)入口点，同时通过`ingress`选项指定[Ingress](/concepts/ingress/)对象来定义流量路由规则。

公共入口点不是必须的，如果不设置则所有隧道只能通过私有入口点(参见后面的私有隧道部分)进行访问。

!!! note "隧道ID分配"
    如果使用了Ingress，隧道将通过(虚拟)主机名进行路由，隧道的ID应当由服务端提前分配并记录在Ingress中。如果客户端使用了一个未在Ingress中注册的隧道ID，则流量无法路由到此客户端。

### 客户端

=== "命令行"

    ```bash
    gost -L rtcp://:0/192.168.1.1:80 -F relay://:8443?tunnel.id=4d21094e-b74c-4916-86c1-d9fa36ea677b
    ```

=== "配置文件"

    ```yaml
    services:
    - name: service-0
      addr: :0
      handler:
        type: rtcp
      listener:
        type: rtcp
        chain: chain-0
      forwarder:
        nodes:
        - name: target-0
          addr: 192.168.1.1:80
    chains:
    - name: chain-0
      hops:
      - name: hop-0
        nodes:
        - name: node-0
          addr: :8443
          connector:
            type: relay
            metadata:
              tunnel.id: 4d21094e-b74c-4916-86c1-d9fa36ea677b
          dialer:
            type: tcp
    ```

当Relay客户端设置了`tunnel.id`选项后便开启了Tunnel模式，此时rtcp服务中指定的`addr`参数无效。

本例中当流量进入入口点(服务端的80端口)后会嗅探流量信息获取所要访问的主机名，再通过主机名在Ingress中找到匹配的规则，获取对应的服务端点(endpoint即Tunnel ID)，最后在Tunnel的连接池中获取一个有效连接将流量通过此连接发送到客户端。

当主机名为`example.com`时，根据Ingress中的规则匹配到ID为4d21094e-b74c-4916-86c1-d9fa36ea677b的Tunnel。当流量到达客户端后再由rtcp服务转发给192.168.1.1:80服务。

!!! tip "高可用性"
    为了提高单个Tunnel的可用性，可以运行多个客户端，这些客户端使用相同的Tunnel ID。当需要从隧道获取连接时，将采用轮询机制，最多3次失败重试。

## 客户端路由

客户端也可以同时开启流量嗅探对流量进行再次路由。

```yaml
services:
- name: service-0
  addr: :0
  handler:
    type: rtcp
    metadata:
      sniffing: true
  listener:
    type: rtcp
    chain: chain-0
  forwarder:
    nodes:
    - name: example-com
      addr: 192.168.1.1:80
      host: example.com
    - name: sub-example-com
      addr: 192.168.1.2:80
      host: sub.example.com
    - name: fallback
      addr: 192.168.2.1:80
chains:
- name: chain-0
  hops:
  - name: hop-0
    nodes:
    - name: node-0
      addr: :8443
      connector:
        type: relay
        metadata:
          tunnel.id: 4d21094e-b74c-4916-86c1-d9fa36ea677b
      dialer:
        type: tcp
```

当主机名为`example.com`时，根据Ingress中的规则匹配到Tunnel 4d21094e-b74c-4916-86c1-d9fa36ea677b。当流量到达客户端后再由rtcp服务转发给192.168.1.1:80服务。

当主机名为`sub.example.com`时，根据Ingress中的规则匹配到Tunnel 4d21094e-b74c-4916-86c1-d9fa36ea677b。当流量到达客户端后再由rtcp服务转发给192.168.1.2:80服务。

当主机名为`abc.example.com`时，根据Ingress中的规则匹配到Tunnel 4d21094e-b74c-4916-86c1-d9fa36ea677b。当流量到达客户端后再由rtcp服务转发给192.168.2.1:80服务。

## 私有隧道

在Ingress中可以通过将隧道标记为私有来限制对隧道的访问，由公共入口点进入的流量无法路由到私有隧道。

若要使用私有隧道，用户(访问端)需要开启一个私有入口服务作为流量的入口点，此服务通过设置隧道ID来指定想要访问的隧道(不仅限于私有隧道)。

![Reverse Proxy - Web Private Tunnel](/images/private-tunnel-web.png) 

### 服务端

```yaml hl_lines="19"
services:
- name: service-0
  addr: :8443
  handler:
    type: relay
    metadata:
      entryPoint: ":80"
      ingress: ingress-0
  listener:
    type: tcp
ingresses:
- name: ingress-0
  rules:
  - hostname: "srv-0.local"
    endpoint: 4d21094e-b74c-4916-86c1-d9fa36ea677b
  - hostname: "srv-1.local"
    endpoint: 4d21094e-b74c-4916-86c1-d9fa36ea677b
  - hostname: "srv-2.local"
    endpoint: $ac74d9dd-3125-442a-a7c1-f9e49e05faca # private tunnel
  - hostname: "srv-3.local"
    endpoint: ac74d9dd-3125-442a-a7c1-f9e49e05faca
  - hostname: "ssh.srv-2.local" 
    endpoint: aede1f6a-762b-45da-b937-b6632356555a # tunnel for ssh TCP traffic
  - hostname: "redis.srv-3.local" 
    endpoint: aede1f6a-762b-45da-b937-b6632356555a # tunnel for redis TCP traffic
  - hostname: "dns.srv-2.local" 
    endpoint: aede1f6a-762b-45da-b937-b6632356555a # tunnel for DNS UDP traffic
  - hostname: "dns.srv-3.local" 
    endpoint: aede1f6a-762b-45da-b937-b6632356555a # tunnel for DNS UDP traffic
```

在Ingress的规则中，通过在endpoint所代表的隧道ID值前添加`$`便将此规则对应的隧道标记为私有，例如上面的srv-2.local主机对应的隧道ac74d9dd-3125-442a-a7c1-f9e49e05faca即为私有隧道，因此通过公共入口点80端口进入的流量无法使用此隧道。

!!! note "私有性"
    私有性的作用范围为Ingress的规则，而不是隧道本身，同一个隧道在不同的规则中可以有不同的私有性。例如上面例子当中，srv-2.local和srv-3.local使用的是相同的隧道，但srv-3.local对应规则中隧道不是私有的，因此通过公共入口点80端口进入去往srv-3.local主机的流量可以路由到此隧道。

### 客户端

=== "命令行"

    ```bash
    gost -L rtcp://:0/192.168.2.1:80 -F relay://:8443?tunnel.id=ac74d9dd-3125-442a-a7c1-f9e49e05faca
    ```

=== "配置文件"

    ```yaml
    services:
    - name: service-0
      addr: :0
      handler:
        type: rtcp
      listener:
        type: rtcp
        chain: chain-0
      forwarder:
        nodes:
        - name: srv-2.local
          addr: 192.168.2.1:80
    chains:
    - name: chain-0
      hops:
      - name: hop-0
        nodes:
        - name: node-0
          addr: :8443
          connector:
            type: relay
            metadata:
              tunnel.id: ac74d9dd-3125-442a-a7c1-f9e49e05faca
          dialer:
            type: tcp
    ```

客户端的配置与之前一致。

### 访问端

=== "命令行"

    自动嗅探主机名

    ```bash
    gost -L tcp://:8000?sniffing=true -F relay://:8443?tunnel.id=ac74d9dd-3125-442a-a7c1-f9e49e05faca
    ```

    或指定主机名

    ```bash
    gost -L tcp://:8000/srv-2.local -F relay://:8443?tunnel.id=ac74d9dd-3125-442a-a7c1-f9e49e05faca
    ```

=== "配置文件"
   
    ```yaml hl_lines="8 21"
      services:
      - name: service-0
        addr: :8000
        handler:
          type: tcp
          chain: chain-0
          metadata:
            sniffing: true
        listener:
          type: tcp
      chains:
      - name: chain-0
        hops:
        - name: hop-0
          nodes:
          - name: node-0
            addr: :8443
            connector:
              type: relay
              metadata:
                tunnel.id: ac74d9dd-3125-442a-a7c1-f9e49e05faca
              dialer:
                type: tcp
    ```

访问端开启私有入口服务监听在8000端口，通过设置`tunnel.id`选项指定所要使用的隧道。

## TCP服务

隧道并不限于Web流量，也可以应用于任何TCP服务(例如SSH)。例如上面服务端的Ingress中`ssh.srv-2.local`和`redis.srv-3.local`主机对应的隧道。

![Reverse Proxy - TCP Tunnel](/images/private-tunnel-tcp.png) 

### 客户端

```yaml hl_lines="13 16"
services:
- name: service-0
  addr: :0
  handler:
    type: rtcp
  listener:
    type: rtcp
    chain: chain-0
  forwarder:
    nodes:
    - name: ssh
      addr: 192.168.2.1:22
      host: ssh.srv-2.local
    - name: redis
      addr: 192.168.2.2:6379
      host: redis.srv-3.local
chains:
- name: chain-0
  hops:
  - name: hop-0
    nodes:
    - name: node-0
      addr: :8443
      connector:
        type: relay
        metadata:
          tunnel.id: aede1f6a-762b-45da-b937-b6632356555a
      dialer:
        type: tcp
```

客户端的转发器设置了两个目标节点：192.168.2.1:22的ssh服务和192.168.2.2:6379的redis服务。
注意每个节点上的`host`参数需要与服务端Ingress对应规则中的`hostname`相匹配。

### 访问端

=== "命令行"

    SSH服务

    ```bash
    gost -L tcp://:2222/ssh.srv-2.local -F relay://:8443?tunnel.id=aede1f6a-762b-45da-b937-b6632356555a
    ```

    或redis服务

    ```bash
    gost -L tcp://:6379/redis.srv-3.local -F relay://:8443?tunnel.id=aede1f6a-762b-45da-b937-b6632356555a
    ```

=== "配置文件"
   
    ```yaml hl_lines="11 12"
      services:
      - name: service-0
        addr: :2222
        handler:
          type: tcp
          chain: chain-0
        listener:
          type: tcp
        forwarder:
          nodes:
          - name: ssh
            addr: ssh.srv-2.local
          # - name: redis
          #   addr: redis.srv-3.local
      chains:
      - name: chain-0
        hops:
        - name: hop-0
          nodes:
          - name: node-0
            addr: :8443
            connector:
              type: relay
              metadata:
                tunnel.id: aede1f6a-762b-45da-b937-b6632356555a
              dialer:
                type: tcp
    ```

访问端需要在转发器中指定目标节点主机名，需要与服务端Ingress对应规则中的`hostname`相匹配。

## UDP服务

隧道也可以应用于任何UDP服务(例如DNS)。例如上面服务端的Ingress中`dns.srv-2.local`和`dns.srv-3.local`主机对应的隧道。

![Reverse Proxy - UDP Tunnel](/images/tunnel-udp.png) 

### 客户端

```yaml hl_lines="5 7 13 16"
services:
- name: service-0
  addr: :0
  handler:
    type: rudp
  listener:
    type: rudp
    chain: chain-0
  forwarder:
    nodes:
    - name: dns-1
      addr: 192.168.2.1:53
      host: dns.srv-2.local
    - name: dns-2
      addr: 192.168.2.2:53
      host: dns.srv-3.local
chains:
- name: chain-0
  hops:
  - name: hop-0
    nodes:
    - name: node-0
      addr: :8443
      connector:
        type: relay
        metadata:
          tunnel.id: aede1f6a-762b-45da-b937-b6632356555a
      dialer:
        type: tcp
```

客户端的转发器设置了两个目标节点：192.168.2.1:53的DNS服务和192.168.2.2:53的DNS服务。
注意每个节点上的`host`参数需要与服务端Ingress对应规则中的`hostname`相匹配。

### 访问端

=== "命令行"

    ```bash
    gost -L udp://:1053/dns.srv-2.local -L udp://:2053/dns.srv-3.local -F relay://:8443?tunnel.id=aede1f6a-762b-45da-b937-b6632356555a
    ```

=== "配置文件"
   
    ```yaml hl_lines="5 8 11 12"
      services:
      - name: service-0
        addr: :1053
        handler:
          type: udp
          chain: chain-0
        listener:
          type: udp
        forwarder:
          nodes:
          - name: dns-1
            addr: dns.srv-2.local
      - name: service-1
        addr: :2053
        handler:
          type: udp
          chain: chain-0
        listener:
          type: udp
        forwarder:
          nodes:
          - name: dns-2
            addr: dns.srv-3.local
      chains:
      - name: chain-0
        hops:
        - name: hop-0
          nodes:
          - name: node-0
            addr: :8443
            connector:
              type: relay
              metadata:
                tunnel.id: aede1f6a-762b-45da-b937-b6632356555a
              dialer:
                type: tcp
    ```

访问端需要在转发器中指定目标节点主机名，需要与服务端Ingress对应规则中的`hostname`相匹配。

## 直接路由

上面的隧道都是通过定义Ingress，根据Ingress规则中虚拟主机名来路由，这种方式可以看作是间接路由模式，Ingress在这里即是路由表，又可以看作是白名单。

也可以开启直接路由模式，访问端与客户端直接通过隧道ID进行匹配，当访问端未匹配上Ingress中的规则后会采用隧道ID直接匹配方式来查找客户端。Ingress是可选的。

!!! caution "提高安全性"
    当开启直接路由模式后，隧道的分配及使用完全由客户端控制，请确保服务端仅能够被受信任的用户访问，可以通过增加用户认证功能提高服务的安全性，以防止被滥用。


服务端通过`tunnel.direct`选项开启直接路由模式。

=== "命令行"

    ```bash
    gost -L relay://:8443?tunnel.direct=true
    ```

=== "配置文件"

    ```yaml hl_lines="7"
    services:
    - name: service-0
      addr: :8443
      handler:
        type: relay
        metadata:
          tunnel.direct: true
      listener:
        type: tcp
    ```

## 多路复用

隧道本身支持多路复用，单个隧道不仅限于某一种类型的流量使用，也支持同时传输不同类型的流量(Web，TCP，UDP)。

TCP和UDP服务可以共用同一个隧道，隧道会对TCP和UDP的客户端连接作区分，对于TCP的访问端仅会匹配TCP客户端，对于UDP的访问端仅会区配UDP客户端。

下面将通过一个具体的示例来说明。

## 示例 - 通过隧道进行iperf测试

![Reverse Proxy - iperf3](/images/tunnel-iperf.png) 

### 服务端


=== "命令行"

    Ingress模式

    ```bash
    gost -L relay://:8443?tunnel=iperf.local:22f43305-42f7-4232-bbbc-aa6c042e3bc3
    ```

    或直接路由模式

    ```bash
    gost -L relay://:8443?tunnel.direct=true
    ```

=== "配置文件"

    ```yaml 
    services:
    - name: service-0
      addr: :8443
      handler:
        type: relay
        metadata:
          ingress: ingress-0
          # direct routing mode
          # tunnel.direct: true 
      listener:
        type: tcp
    ingresses:
    - name: ingress-0
      rules:
      - hostname: "iperf.local"
        endpoint: 22f43305-42f7-4232-bbbc-aa6c042e3bc3
    ```

### 客户端

由于转发的目标只有一个，因此可以使用命令行直接转发，如果要转发多个服务需要通过配置文件在转发器中为每个目标节点定义主机名(`forwarder.nodes.host`)，通过主机名来匹配不同的服务。

=== "命令行"

    ```bash
    gost -L rtcp://:0/:5201 -L rudp://:0/:5201 -F relay://:8443?tunnel.id=22f43305-42f7-4232-bbbc-aa6c042e3bc3
    ```

=== "配置文件"

    ```yaml hl_lines="5 7 12 13 17 19 24 25" 
    services:
    - name: iperf-tcp
      addr: :0
      handler:
        type: rtcp
      listener:
        type: rtcp
        chain: chain-0
      forwarder:
        nodes:
        - name: iperf
          addr: :5201
          host: iperf.local
    - name: iperf-udp
      addr: :0
      handler:
        type: rudp
      listener:
        type: rudp
        chain: chain-0
      forwarder:
        nodes:
        - name: iperf
          addr: :5201
          host: iperf.local
    chains:
    - name: chain-0
      hops:
      - name: hop-0
        nodes:
        - name: node-0
          addr: :8443
          connector:
            type: relay
            metadata:
              tunnel.id: 22f43305-42f7-4232-bbbc-aa6c042e3bc3
          dialer:
            type: tcp
    ```

### 访问端

转发的目标地址需要与服务端的Ingress中规则对应的主机名匹配，如果要转发多个服务需要通过配置文件在转发器中为每个目标节点定义主机名(`forwarder.nodes.host`)，通过主机名来匹配不同的服务。

!!! note "UDP连接保持"
    UDP端口转发服务默认在进行完一次数据交互后连接状态便失效，这对于像DNS这种服务会很有效。但是对于需要多次数据交互的UDP服务，需要通过`keepalive`选项开启连接保持功能，另外可以通过`ttl`选项来控制超时时长，默认超过5秒无数据交互连接状态将会失效。

=== "命令行"

    Ingress模式

    ```bash
    gost -L tcp://:15201/iperf.local -L udp://:15201/iperf.local?keepalive=true -F relay://:8443?tunnel.id=22f43305-42f7-4232-bbbc-aa6c042e3bc3
    ```

    直接路由模式

    ```bash
    gost -L tcp://:15201 -L udp://:15201?keepalive=true -F relay://:8443?tunnel.id=22f43305-42f7-4232-bbbc-aa6c042e3bc3
    ```

=== "配置文件"
   
    ```yaml hl_lines="5 8 11 12"
      services:
      - name: iperf-tcp
        addr: :15201
        handler:
          type: tcp
          chain: chain-0
        listener:
          type: tcp
        forwarder:
          nodes:
          - name: iperf
            addr: iperf.local
      services:
      - name: iperf-udp
        addr: :15201
        handler:
          type: udp
          chain: chain-0
        listener:
          type: udp
          metadata:
            keepalive: true
            # ttl: 5s
        forwarder:
          nodes:
          - name: iperf
            addr: iperf.local
      chains:
      - name: chain-0
        hops:
        - name: hop-0
          nodes:
          - name: node-0
            addr: :8443
            connector:
              type: relay
              metadata:
                tunnel.id: 22f43305-42f7-4232-bbbc-aa6c042e3bc3
              dialer:
                type: tcp
    ```

### iperf3服务

启动iperf3服务。

```
iperf3 -s
```

### 执行iperf3测试

TCP测试

```
iperf3 -c 127.0.0.1 -p 15201
```

UDP测试

```
iperf3 -c 127.0.0.1 -p 15201 -u
```

## 公共反向代理服务

如果需要临时来反向代理内网服务提供公网访问，可以通过`GOST.PLUS`提供的公共反向代理服务将本地文件服务匿名暴露到公网来访问。

```sh
gost -L rtcp://:0/192.168.1.1:80 -F tunnel+wss://tunnel.gost.plus:443?tunnel.id=893787fd-fcd2-46a0-8dd4-f9103ae84df4
```

当正常连接到`gost.plus`服务后，会有类似如下日志信息：

```json
{"connector":"tunnel","dialer":"wss","hop":"hop-0","kind":"connector","level":"info",
"msg":"create tunnel on 134c714b65d54a4f:0/tcp OK, tunnel=893787fd-fcd2-46a0-8dd4-f9103ae84df4, connector=3464af8b-49c5-424c-89ea-b4e9af075a7d",
"node":"node-0","time":"2023-10-19T23:17:27.403+08:00"}
```

日志的`msg`信息中`134c714b65d54a4f`是为此服务生成的临时公共访问点，有效期为1小时。通过[https://134c714b65d54a4f.gost.plus](https://134c714b65d54a4f.gost.plus)便能立即访问到`192.168.1.1:80`服务。
