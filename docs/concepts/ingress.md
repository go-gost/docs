---
comments: true
---

# Ingress

!!! tip "动态配置"
    Ingress支持通过[Web API](/tutorials/api/overview/)进行动态配置。

!!! note "使用限制"
    Ingress目前仅在[反向代理隧道](/tutorials/reverse-proxy-tunnel/)中使用。

Ingress由一组规则组成，每个规则为主机名(Hostname)到服务端点(Endpoint)的映射，在反向代理中通过Ingress对入口点(EntryPoint)流量进行路由和负载均衡。

规则中的主机名也支持域名通配符，服务端点必须是一个合法的UUID。

## 域名通配符

Ingress规则中的主机名(hostname)支持以`.`或`*`开头的通配符格式。

例如：`.example.org`或`*.example.org`匹配example.org，abc.example.org，def.abc.example.org等子域名。

在查询一个规则时，会先查找完全匹配项，如果没有找到再查找通配符项，如果没有找到再依次查找上级域名通配符。

例如：abc.example.org，会先查找abc.example.org映射值，如果没有则查找.abc.example.org通配符项，如果没有则继续依次查找.example.org和.org通配符项。

## 数据源

Ingress可以配置多个数据源，目前支持的数据源有：内联，文件，redis，HTTP。

#### 内联

内联数据源直接在配置文件中通过`rules`参数设置数据。

```yaml
ingresses:
- name: ingress-0
  rules:
  - hostname: example.com
    endpoint: 4d21094e-b74c-4916-86c1-d9fa36ea677b
  - hostname: example.org
    endpoint: ac74d9dd-3125-442a-a7c1-f9e49e05faca
```

### 文件

指定外部文件作为数据源。通过`file.path`参数指定文件路径。

```yaml
ingresses:
- name: ingress-0
  file:
    path: /path/to/file
```

文件格式为按行分割的映射项，每一行为用空格分割的hostname-endpoint对，以`#`开始的部分为注释信息。

```text
# hostname endpoint

example.com  4d21094e-b74c-4916-86c1-d9fa36ea677b
example.org  ac74d9dd-3125-442a-a7c1-f9e49e05faca
```

### Redis

指定redis服务作为数据源，redis数据类型为[哈希(Hash)](https://redis.io/docs/data-types/hashes/)或[集合(Set)](https://redis.io/docs/data-types/sets/)类型。

```yaml
ingresses:
- name: ingress-0
  redis:
    addr: 127.0.0.1:6379
    db: 1
    password: 123456
    key: gost:ingresses:ingress-0
    type: hash
```

`addr` (string, required)
:    redis服务地址

`db` (int, default=0)
:    数据库名

`password` (string)
:    密码

`key` (string, default=gost)
:    redis key

`type` (string, default=hash)
:    数据类型，支持的类型有：哈希(`hash`)，集合(`set`)。

数据的每一项为：

```redis
> HGETALL gost:ingresses:ingress-0
1) "example.com"
2) "4d21094e-b74c-4916-86c1-d9fa36ea677b"
3) "example.org"
4) "ac74d9dd-3125-442a-a7c1-f9e49e05faca"
```

### HTTP

指定HTTP服务作为数据源。对于所请求的URL，HTTP返回200状态码则认为有效，返回的数据格式与文件数据源相同。

```yaml
ingresses:
- name: ingress-0
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
ingresses:
- name: ingress-0
  reload: 10s
  file:
    path: /path/to/file
  redis:
    addr: 127.0.0.1:6379
    db: 1
    password: 123456
    key: gost:ingresses:ingress-0
  http:
    url: http://127.0.0.1:8000
    timeout: 10s
```

## 插件

Ingress可以配置为使用外部[插件](/concepts/plugin/)服务，Ingress会将查询请求转发给插件服务处理。当使用插件时其他参数无效。

```yaml
ingresses:
- name: ingress-0
  plugin:
    addr: 127.0.0.1:8000
    tls: 
      secure: false
      serverName: example.com
```

`addr` (string, required)
:    插件服务地址

`tls` (duration, default=null)
:    设置后将使用TLS加密传输，默认不使用TLS加密。

### HTTP插件

```yaml
ingresses:
- name: ingress-0
  plugin:
    type: http
    addr: http://127.0.0.1:8000/ingress
```

#### 请求示例

```bash
curl -XGET http://127.0.0.1:8000/ingress?host=example.com
```

```json
{"endpoint":"4d21094e-b74c-4916-86c1-d9fa36ea677b"}
```
