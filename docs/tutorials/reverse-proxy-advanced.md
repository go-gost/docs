# 反向代理(高级)

在上一篇[反向代理](reverse-proxy/)教程中，利用端口转发功能实现了简单的反向代理功能，在本篇教程中将利用Relay协议的Tunnel功能实现类似于[Cloudflare Tunnel](https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/)的增强版反向代理。

## Relay协议的Tunnel功能

Tunnel是一条服务端和客户端之间的反向隧道，服务端由入口点(EntryPoint)进入的流量会通过Tunnel发送给客户端。每个Tunnel有一个唯一的ID，一个Tunnel可以有多个连接(连接池)来实现Tunnel的高可用性。

### 服务端

```yaml hl_lines="7 8"
services:
- name: service-0
  addr: :8443
  handler:
    type: relay
    metadata:
      entryPoint: ":8000"
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

当Relay服务设置了`entryPoint`选项后便开启了Tunnel模式，entryPoint指定流量的入口点。同时通过`ingress`选项指定[Ingress](/concepts/ingress/)来定义流量路由规则。

### 客户端

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

本例中当流量进入入口点(EntryPoint)后会嗅探流量信息获取所要访问的主机名，再通过主机名在Ingress中找到匹配的规则，获取对应的服务端点(endpoint即Tunnel ID)，最后在Tunnel的连接池中获取一个连接(采用轮询机制，最多3次失败重试)将流量通过此Tunnel发送到客户端。

当主机名为`example.com`时，根据Ingress中的规则匹配到Tunnel 4d21094e-b74c-4916-86c1-d9fa36ea677b。当流量到达客户端后再由rtcp服务转发给192.168.1.1:80服务。

为了提高Tunnel的可用性，可以运行多个客户端，这些客户端使用相同的Tunnel ID。

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
