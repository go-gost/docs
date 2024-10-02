---
comments: true
---

# 跳跃点

!!! tip "动态配置"
    跳跃点在引用模式下支持通过[Web API](/tutorials/api/overview/)进行动态配置。

跳跃点是对转发链层级的抽象，是转发链的基本组成部分。一个跳跃点中包含一个或多个节点(Node)，和一个节点[选择器](/concepts/selector/)，在每次执行数据转发请求时，通过在转发链的每个跳跃点上使用选择器在节点组中选出一个节点，最终构成一条转发路径(Route)来处理请求。

跳跃点有两种使用方式：内联模式和引用模式。

## 内联模式

在转发链中可以直接定义跳跃点。

=== "命令行"

    ```
    gost -L http://:8080 -F https://192.168.1.1:8080 -F socks5+ws://192.168.1.2:1080
    ```

=== "配置文件"

    ```yaml hl_lines="12 20"
    services:
    - name: service-0
      addr: ":8080"
      handler:
        type: http
        chain: chain-0
      listener:
        type: tcp
    chains:
    - name: chain-0
      hops:
      - name: hop-0
        nodes:
        - name: node-0
          addr: 192.168.1.1:8080
          connector:
            type: http
          dialer:
            type: tls
      - name: hop-1
        nodes:
        - name: node-0
          addr: 192.168.1.2:1080
          connector:
            type: socks5
          dialer:
            type: ws
    ```

以上配置中有一条转发链(chain-0)，其中有两个跳跃点(hop-0，hop-1)，每个跳跃点中有一个节点。

## 引用模式

也可以单独定义跳跃点再通过引用跳跃点的名称来使用特定的跳跃点。

```yaml hl_lines="13 14 17 25"
services:
- name: service-0
  addr: ":8080"
  handler:
    type: http
    chain: chain-0
  listener:
    type: tcp

chains:
- name: chain-0
  hops:
  - name: hop-0
  - name: hop-1

hops:
- name: hop-0
  nodes:
  - name: node-0
    addr: 192.168.1.1:8080
    connector:
      type: http
	dialer:
      type: tls
- name: hop-1
  nodes:
  - name: node-0
    addr: 192.168.1.2:1080
    connector:
      type: socks5
    dialer:
      type: ws
```

在chain中通过`name`来引用`hops`中定义的跳跃点。

### 转发器

转发器中同样也可以通过引用模式来使用跳跃点。

```yaml hl_lines="9"
services:
- name: service-0
  addr: ":8080"
  handler:
    type: tcp 
  listener:
    type: tcp
  forwarder:
    hop: hop-0

hops:
- name: hop-0
  nodes:
  - name: target-0
    addr: 192.168.1.1:8080
  - name: target-1
    addr: 192.168.1.2:8080
```

!!! note "模式切换"

    当使用内联模式时，如果跳跃点中未定义节点或未使用插件则会自动切换到引用模式。

## 数据源

跳跃点可以配置多个数据源，目前支持的数据源有：内联，文件，redis，HTTP。

### 内联

内联数据源直接在配置文件中通过`nodes`参数指定节点列表。

```yaml
hops:
- name: hop-0
  nodes:
  - name: node-0
    addr: :8888
    connector:
      type: http
    dialer:
      type: tcp
  - name: node-1
    addr: :9999
    connector:
      type: socks5
    dialer:
      type: tcp
```

### 文件

指定外部文件作为数据源。通过`file.path`参数指定文件路径。

```yaml
hops:
- name: hop-0
  nodes: []
  file:
    path: /path/to/file
```

文件格式为JSON数组，数组每一项为节点配置信息。

```json
[
    {
        "name": "http",
        "addr": ":8888",
        "connector": {
            "type": "http",
            "auth": {
                "username": "user",
                "password": "pass"
            }
        },
        "dialer": {
            "type": "tcp"
        }
    },
    {
        "name": "socks5",
        "addr": ":9999",
        "connector": {
            "type": "socks5",
            "auth": {
                "username": "user",
                "password": "pass"
            }
        },
        "dialer": {
            "type": "tcp"
        }
    }
]
```

### Redis

指定redis服务作为数据源，redis数据类型必须为[字符串(Strings)](https://redis.io/docs/data-types/strings/)类型。

```yaml
hops:
- name: hop-0
  nodes: []
  redis:
    addr: 127.0.0.1:6379
    db: 1
    username: user
    password: 123456
    key: gost:hops:hop-0:nodes
```

`addr` (string, required)
:    redis服务地址

`db` (int, default=0)
:    数据库名

`username` (string)
:    用户名

`password` (string)
:    密码

`key` (string, default=gost)
:    redis key

数据内容与文件数据源的格式相同：

```redis
> GET gost:hops:hop-0:nodes
"[{\"name\":\"http\",...},{\"name\":\"socks5\",...}]"
```

### HTTP

指定HTTP服务作为数据源。对于所请求的URL，HTTP返回200状态码则认为有效，返回的数据格式与文件数据源相同。

```yaml
hops:
- name: hop-0
  nodes: []
  http:
    url: http://127.0.0.1:8000
    timeout: 10s
```

`url` (string, required)
:    请求的URL

`timeout` (duration, default=0)
:    请求超时时长

## 热加载

文件，redis，HTTP数据源支持热加载。通过设置`reload`参数开启热加载，`reload`参数指定同步数据源数据的周期。

```yaml hl_lines="3"
hops:
- name: hop-0
  reload: 10s
  file:
    path: /path/to/file
  redis:
    addr: 127.0.0.1:6379
    db: 1
    password: 123456
    key: gost:hops:hop-0:nodes
  http:
    url: http://127.0.0.1:8000
    timeout: 10s
  nodes: []
```

## 插件

跳跃点可以配置为使用外部[插件](/concepts/plugin/)服务，跳跃点会将节点选择请求转发给插件服务处理。当使用插件时其他参数无效。

```yaml
hops:
- name: hop-0
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
hops:
- name: hop-0
  plugin:
    type: http
    addr: http://127.0.0.1:8000/hop
```

#### 请求示例

```bash
curl -XPOST http://127.0.0.1:8000/hop -d '{"addr": "example.com:80", "client": "gost"}'
```

```json
{
    "name": "http",
    "addr": ":8888",
    "connector": {
        "type": "http",
        "auth": {
            "username": "user",
            "password": "pass"
        }
    },
    "dialer": {
        "type": "tcp"
    }
}
```

`client` (string)
:    用户身份标识，此信息由认证器生成。
