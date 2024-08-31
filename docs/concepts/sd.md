---
comments: true
---

# 服务发现

!!! tip "动态配置"
    服务发现支持通过[Web API](/tutorials/api/overview/)进行动态配置。

!!! note "使用限制"
    服务发现目前仅在[反向代理隧道](/tutorials/reverse-proxy-tunnel-ha/)中使用。

服务发现为反向代理隧道提供了一种服务的注册和发现机制，服务发现目前仅能以插件的方式来使用。

服务发现定义了四个行为：

* Register - 当一个反向代理隧道客户端与服务端建立连接后，服务端会调用插件注册此客户端的连接信息。
* Deregister - 当客户端断开连接后，服务端会调用插件注销客户端的连接信息。
* Renew - 服务端会定期检查客户端连接状态，并反馈给插件，确保连接信息的有效性。
* Get - 当反向代理隧道服务端在本地无法找到相应的隧道，会调用插件获取隧道的连接信息。

所注册的服务相关信息有：

* ID - 客户端的连接ID。
* Name - 隧道ID。
* Node - 所连接的服务端节点ID。
* Network - 网络类型，tcp/udp。
* Address - 所连接的服务端节点地址。

## 插件

服务发现可以配置为使用外部[插件](/concepts/plugin/)服务。

```yaml
sds:
- name: sd-0
  plugin:
    type: grpc
    addr: 127.0.0.1:8000
    tls: 
      secure: false
      serverName: example.com
```

`type` (string, default=grpc)
:    插件类型：`grpc`, `http`。

`addr` (string, required)
:    插件服务地址。

`tls` (object, default=null)
:    设置后将使用TLS加密传输，默认不使用TLS加密。

### HTTP插件

```yaml
sds:
- name: sd-0
  plugin:
    type: http
    addr: http://127.0.0.1:8000/sd
```

#### 请求示例

**Register**

```bash
curl -XPOST http://127.0.0.1:8000/sd \
-d '{"id":"c23d4f42-c892-42b3-8b74-88ab6455d33a", 
"name":"c9ef8f8c-d687-4dca-be7a-1467b6565404", 
"node":"db670b91-61a5-4f7c-8014-3bbe994446ea",
"network":"tcp", \
"address":"10.42.0.100:80"}'
```

**Deregister**

```bash
curl -XDELETE http://127.0.0.1:8000/sd \
-d '{"id":"c23d4f42-c892-42b3-8b74-88ab6455d33a", 
"name":"c9ef8f8c-d687-4dca-be7a-1467b6565404", 
"node":"db670b91-61a5-4f7c-8014-3bbe994446ea"}'
```

**Renew**

```bash
curl -XPUT http://127.0.0.1:8000/sd \
-d '{"id":"c23d4f42-c892-42b3-8b74-88ab6455d33a", 
"name":"c9ef8f8c-d687-4dca-be7a-1467b6565404", 
"node":"db670b91-61a5-4f7c-8014-3bbe994446ea"}'
```

**Get**

```bash
curl -XGET http://127.0.0.1:8000/sd?name=c9ef8f8c-d687-4dca-be7a-1467b6565404
```

```json
{
  "services":[
    {
      "id":"c23d4f42-c892-42b3-8b74-88ab6455d33a",
      "name":"c9ef8f8c-d687-4dca-be7a-1467b6565404",
      "node":"db670b91-61a5-4f7c-8014-3bbe994446ea",
      "network":"tcp",
      "address":"10.42.0.100:80"
    }
  ]
}
```
