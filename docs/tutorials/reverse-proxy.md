# 反向代理

[反向代理](https://zh.wikipedia.org/wiki/%E5%8F%8D%E5%90%91%E4%BB%A3%E7%90%86)是代理服务的一种。服务器根据客户端的请求，从其关系的一组或多组后端服务器（如Web服务器）上获取资源，然后再将这些资源返回给客户端，客户端只会得知反向代理的IP地址，而不知道在代理服务器后面的服务器集群的存在。因此反向代理也可以看作是透明转发。

GOST中的端口转发服务也可以被当作是一种功能受限的反向代理，因其只能转发到固定的一个或一组后端服务。

反向代理是端口转发服务的一个扩展，其依托于端口转发功能，并通过嗅探转发的数据来获取特定协议(目前支持HTTP/HTTPS)中的目标主机信息。

## 本地端口转发

```yaml hl_lines="7 14 17"
services:
- name: https
  addr: :443
  handler:
    type: tcp
    metadata:
      sniffing: true
  listener:
    type: tcp
  forwarder:
    nodes:
    - name: google
      addr: www.google.com:443
      host: www.google.com
    - name: github
      addr: github.com:443
      host: "*.github.com"
      # host: .github.com
- name: http
  addr: :80
  handler:
    type: tcp
    metadata:
      sniffing: true
  listener:
    type: tcp
  forwarder:
    nodes:
    - name: example-com
      addr: example.com:80
      host: example.com
    - name: example-org
      addr: example.org:80
      host: example.org
```

通过`sniffing`选项来开启流量嗅探，并在`forwarder.nodes`中通过`host`选项可以对每一个节点设置(虚拟)主机名。

当开启流量嗅探后，转发服务会通过客户端的请求数据获取访问的目标主机，再通过转发器(forwarder)中的节点设置的虚拟主机名(node.host)找到最终转发的目标地址(node.addr)。

`node.host`也支持通配符，*.example.com或.example.com匹配example.com及其子域名：abc.example.com，def.abc.example.com等。

此时可以将对应的域名解析到本地通过反向代理来访问：

```bash
curl --resolve www.google.com:443:127.0.0.1 https://www.google.com
```

```bash
curl --resolve example.com:80:127.0.0.1 http://example.com
```

## 远程端口转发

远程端口转发服务同样也可以对流量进行嗅探。

```yaml hl_lines="7 15 18"
services:
- name: https
  addr: :443
  handler:
    type: rtcp
    metadata:
      sniffing: true
  listener:
    type: rtcp
	chain: chain-0
  forwarder:
    nodes:
    - name: local-0
      addr: 192.168.1.1:443
      host: srv-0.local
    - name: local-1
      addr: 192.168.1.2:443
      host: srv-1.local
	- name: fallback
	  addr: 192.168.2.1:443
- name: http
  addr: :80
  handler:
    type: rtcp
    metadata:
      sniffing: true
  listener:
    type: rtcp
	  chain: chain-0
  forwarder:
    nodes:
    - name: local-0
      addr: 192.168.1.1:80
      host: srv-0.local
    - name: local-1
      addr: 192.168.1.2:80
      host: srv-1.local
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

通过`sniffing`选项来开启流量嗅探，并在`forwarder.nodes`中通过`host`选项可以对每一个节点设置(虚拟)主机名。

此时可以将对应的域名解析到服务器地址通过反向代理来访问内网服务：

```bash
curl --resolve srv-0.local:443:SERVER_IP https://srv-0.local
```

```bash
curl --resolve srv-1.local:80:SERVER_IP http://srv-1.local
```

如果访问的目标主机没有与转发器中的节点设定的主机名匹配上，当存在没有设置主机名的节点，则会在这些节点中选择一个使用。


```bash
curl --resolve srv-2.local:443:SERVER_IP https://srv-2.local
```

由于srv-2.local没有匹配到节点，因此会被转发到fallback节点(192.168.2.443)。

## 特定应用转发

本地和远程端口转发服务也支持对特定的应用流量嗅探。目前支持的应用协议有：SSH。

### SSH

在forwarder.nodes中通过`protocol`选项指定节点协议类型为`ssh`，嗅探到SSH协议流量则会转发到此节点。

=== "本地端口转发"

    ```yaml hl_lines="14"
    services:
    - name: https
      addr: :443
      handler:
        type: tcp
        metadata:
          sniffing: true
      listener:
        type: tcp
      forwarder:
        nodes:
        - name: ssh-server
          addr: example.com:22
          protocol: ssh
    ```

=== "远程端口转发"

    ```yaml hl_lines="15"
    services:
    - name: https
      addr: :443
      handler:
        type: rtcp
        metadata:
          sniffing: true
      listener:
        type: rtcp
        chain: chain-0
      forwarder:
        nodes:
        - name: local-ssh
          addr: 192.168.2.1:22
          protocol: ssh
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

## 转发通道

除了原始TCP数据通道可以用来作为端口转发，其他数据通道也可以作为端口转发服务。

### TLS转发通道

HTTPS-to-HTTP反向代理。

TLS转发通道可以动态的给后端HTTP服务添加TLS支持。

```yaml
services:
- name: https
  addr: :443
  handler:
    type: forward
    metadata:
      sniffing: true
  listener:
    type: tls
  forwarder:
    nodes:
    - name: example-com
      addr: example.com:80
      host: .example.com
    - name: example-org
      addr: example.org:80
      host: .example.org
```

```bash
curl -k --resolve example.com:443:127.0.0.1 https://example.com
```

### HTTP3转发通道

HTTP3-to-HTTP反向代理。

HTTP3转发通道可以动态的给后端HTTP服务添加HTTP/3支持。

```yaml
services:
- name: http3
  addr: :443
  handler:
    type: http3
  listener:
    type: http3
  forwarder:
    nodes:
    - name: example-com
      addr: example.com:80
      host: .example.com
    - name: example-org
      addr: example.org:80
      host: .example.org
```

```bash
curl -k --http3 --resolve example.com:443:127.0.0.1 https://example.com
```