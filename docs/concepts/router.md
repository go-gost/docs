---
comments: true
---

# 路由器

!!! tip "动态配置"
    路由器支持通过[Web API](/tutorials/api/overview/)进行动态配置。

!!! note "使用限制"
    路由器目前仅在[TUN设备](/tutorials/tuntap/)中使用。

路由器由路由表组成，每个路由项为目标网络(Network)到网关(Gateway)的映射，在TUN设备中通过路由器实现流量的路由。

## 数据源

路由器可以配置多个数据源，目前支持的数据源有：内联，文件，redis，HTTP。

#### 内联

内联数据源直接在配置文件中通过`routes`参数设置数据。

```yaml
routers:
- name: router-0
  routes:
  - net: 192.168.1.0/24
    gateway: 192.168.123.2
  - net: 172.10.0.0/16
    gateway: 192.168.123.3
```

### 文件

指定外部文件作为数据源。通过`file.path`参数指定文件路径。

```yaml
routers:
- name: router-0
  file:
    path: /path/to/file
```

文件格式为按行分割的映射项，每一行为用空格分割的net-gateway对，以`#`开始的部分为注释信息。

```text
# net gateway

192.168.1.0/24  192.168.123.2
172.10.0.0/16  192.168.123.3
```

### Redis

指定redis服务作为数据源，redis数据类型为[哈希(Hash)](https://redis.io/docs/data-types/hashes/)或[集合(Set)](https://redis.io/docs/data-types/sets/)类型。

```yaml
routers:
- name: router-0
  redis:
    addr: 127.0.0.1:6379
    db: 1
    username: user
    password: 123456
    key: gost:routers:router-0
    type: hash
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

`type` (string, default=hash)
:    数据类型，支持的类型有：哈希(`hash`)，集合(`set`)。

数据的每一项为：

```redis
> HGETALL gost:routers:router-0
1) "192.168.1.0/24"
2) "192.168.123.2"
3) "172.10.0.0/16"
4) "192.168.123.3"
```

### HTTP

指定HTTP服务作为数据源。对于所请求的URL，HTTP返回200状态码则认为有效，返回的数据格式与文件数据源相同。

```yaml
routers:
- name: router-0
  http:
    url: http://127.0.0.1:8000
    timeout: 10s
```

`url` (string, required)
:    请求的URL

`timeout` (duration, default=0)
:    请求超时时长

## 优先级

当同时配置多个数据源时，优先级从高到低为: HTTP，redis，文件，内联。

## 热加载

文件，redis，HTTP数据源支持热加载。通过设置`reload`参数开启热加载，`reload`参数指定同步数据源数据的周期。

```yaml hl_lines="3"
routers:
- name: router-0
  reload: 10s
  file:
    path: /path/to/file
  redis:
    addr: 127.0.0.1:6379
    db: 1
    password: 123456
    key: gost:routers:router-0
  http:
    url: http://127.0.0.1:8000
    timeout: 10s
```

## 插件

路由器可以配置为使用外部[插件](/concepts/plugin/)服务，路由器会将路由查询请求转发给插件服务处理。当使用插件时其他参数无效。

```yaml
routers:
- name: router-0
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
routers:
- name: router-0
  plugin:
    type: http
    addr: http://127.0.0.1:8000/router
```

#### 请求示例

```bash
curl -XGET http://127.0.0.1:8000/router?dst=192.168.1.2
```

```json
{"net":"192.168.1.0/24","gateway":"192.168.123.2"}
```
