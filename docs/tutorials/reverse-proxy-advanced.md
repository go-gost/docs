# 反向代理Tunnel

在上一篇[反向代理](/tutorials/reverse-proxy/)教程中，利用端口转发实现了简单的反向代理功能，在本篇中将利用Relay协议的Tunnel功能实现类似于[Cloudflare Tunnel](https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/)的增强版反向代理。

## Relay协议的Tunnel功能

Tunnel是一条服务端和客户端之间的反向隧道，服务端会同时监听在入口点(EntryPoint)上，由入口点进入的流量会通过Tunnel发送给客户端。每个Tunnel有一个唯一的ID(合法的UUID)，一个Tunnel可以有多个连接(连接池)来实现Tunnel的高可用性。

![Reverse Proxy - Remote TCP Port Forwarding](/images/reverse-proxy-rtcp2.png) 

### 服务端

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
    隧道的ID应当由服务端提前分配并记录在Ingress中，如果客户端使用了一个未在Ingress中注册的隧道ID，则流量无法路由到此客户端。

### 客户端

=== "命令行"

    ```bash
    gost -L rtcp://:0/192.168.1.1:80 -F relay://:8443?tunnelID=4d21094e-b74c-4916-86c1-d9fa36ea677b
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
              tunnelID: 4d21094e-b74c-4916-86c1-d9fa36ea677b
          dialer:
            type: tcp
    ```

当Relay客户端设置了`tunnelID`选项后便开启了Tunnel模式，此时rtcp服务中指定的`addr`参数无效。

本例中当流量进入入口点(服务端的80端口)后会嗅探流量信息获取所要访问的主机名，再通过主机名在Ingress中找到匹配的规则，获取对应的服务端点(endpoint即Tunnel ID)，最后在Tunnel的连接池中获取一个有效连接(采用轮询机制，最多3次失败重试)将流量通过此连接发送到客户端。

当主机名为`example.com`时，根据Ingress中的规则匹配到ID为4d21094e-b74c-4916-86c1-d9fa36ea677b的Tunnel。当流量到达客户端后再由rtcp服务转发给192.168.1.1:80服务。

!!! tip "高可用性"
    为了提高单个Tunnel的可用性，可以运行多个客户端，这些客户端使用相同的Tunnel ID。

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
          tunnelID: 4d21094e-b74c-4916-86c1-d9fa36ea677b
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
    endpoint: $aede1f6a-762b-45da-b937-b6632356555a # private tunnel for ssh traffic
  - hostname: "redis.srv-3.local" 
    endpoint: $aede1f6a-762b-45da-b937-b6632356555a # private tunnel for redis traffic
```

在Ingress的规则中，通过在endpoint所代表的隧道ID值前添加`$`便将此规则对应的隧道标记为私有，例如上面的srv-2.local主机对应的隧道ac74d9dd-3125-442a-a7c1-f9e49e05faca即为私有隧道，因此通过公共入口点80端口进入的流量无法使用此隧道。

!!! note "私有性"
    私有性的作用范围为Ingress的规则，而不是隧道本身，同一个隧道在不同的规则中可以有不同的私有性。例如上面例子当中，srv-2.local和srv-3.local使用的是相同的隧道，但srv-3.local对应规则中隧道不是私有的，因此通过公共入口点80端口进入去往srv-3.local主机的流量可以路由到此隧道。

### 客户端

=== "命令行"

    ```bash
    gost -L rtcp://:0/192.168.2.1:80 -F relay://:8443?tunnelID=ac74d9dd-3125-442a-a7c1-f9e49e05faca
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
              tunnelID: ac74d9dd-3125-442a-a7c1-f9e49e05faca
          dialer:
            type: tcp
    ```

客户端的配置与之前一致。

### 访问端

=== "命令行"

    ```bash
    gost -L tcp://:8000?sniffing=true -F relay://:8443?tunnelID=ac74d9dd-3125-442a-a7c1-f9e49e05faca
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
                tunnelID: ac74d9dd-3125-442a-a7c1-f9e49e05faca
              dialer:
                type: tcp
    ```

访问端开启私有入口服务监听在8000端口，通过设置`tunnelID`选项指定所要使用的隧道。

### TCP服务

私有隧道也可以应用于非HTTP流量的TCP服务(例如SSH)。例如上面服务端的Ingress中`ssh.srv-2.local`和`redis.srv-3.local`主机对应的隧道。

![Reverse Proxy - TCP Private Tunnel](/images/private-tunnel-tcp.png) 

#### 客户端

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
          tunnelID: aede1f6a-762b-45da-b937-b6632356555a
      dialer:
        type: tcp
```

客户端的转发器设置了两个目标节点：192.168.2.1:22的ssh服务和192.168.2.2:6379的redis服务。
注意每个节点上的`host`参数需要与服务端Ingress对应规则中的`hostname`相匹配。

#### 访问端

=== "命令行"

    SSH服务
    ```bash
    gost -L tcp://:2222/ssh.srv-2.local:0 -F relay://:8443?tunnelID=aede1f6a-762b-45da-b937-b6632356555a
    ```
    或redis服务
    ```bash
    gost -L tcp://:6379/redis.srv-3.local:0 -F relay://:8443?tunnelID=aede1f6a-762b-45da-b937-b6632356555a
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
            addr: ssh.srv-2.local:0
          # - name: redis
          #   addr: redis.srv-3.local:0
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
                tunnelID: aede1f6a-762b-45da-b937-b6632356555a
              dialer:
                type: tcp
    ```

访问端需要在转发器中指定目标节点地址，需要与服务端Ingress对应规则中的`hostname`相匹配。
