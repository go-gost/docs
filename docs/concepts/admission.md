---
comments: true
---

# 准入控制

!!! tip "动态配置"
    准入控制器支持通过[Web API](/tutorials/api/overview/)进行动态配置。

## 准入控制器

在每个服务上可以分别设置准入控制器来控制客户端接入。

=== "命令行"

    ```bash
    gost -L http://:8080?admission=127.0.0.1,192.168.0.0/16,example.com
    ```

	  通过`admission`参数来指定客户端地址匹配规则列表，规则以逗号分割的IP，CIDR或域名，域名会被解析为IP。

=== "配置文件"

    ```yaml hl_lines="4 10"
    services:
    - name: service-0
      addr: ":8080"
      admission: admission-0
      handler:
        type: http
      listener:
        type: tcp
    admissions:
    - name: admission-0
      matchers:
      - 127.0.0.1
      - 192.168.0.0/16
      - example.com
    ```

    服务中使用`admission`属性通过引用准入控制器名称(name)来使用指定的准入控制器。

## 黑名单与白名单

与分流器类似，准入控制器也可以设置黑名单或白名单模式，默认为黑名单模式。

=== "命令行"

    ```bash
    gost -L http://:8080?admission=~127.0.0.1,192.168.0.0/16
    ```

    通过在`admission`参数中增加`~`前缀将准入控制器设置为白名单模式。

=== "配置文件"

    ```yaml hl_lines="11"
    services:
    - name: service-0
      addr: ":8080"
      admission: admission-0
      handler:
        type: http
      listener:
        type: tcp
    admissions:
    - name: admission-0
      whitelist: true
      matchers:
      - 127.0.0.1
      - 192.168.0.0/16
    ```

	  在`admissions`中通过设置`whitelist`属性为`true`来开启白名单模式。

## 控制器组

通过使用`admissions`属性来指定准入控制器列表来使用多个控制器，当任何一个控制器拒绝则代表请求拒绝。

=== "配置文件"

    ```yaml hl_lines="4 5 6 12 17"
    services:
    - name: service-0
      addr: ":8080"
      admissions: 
      - admission-0
      - admission-1
      handler:
        type: http
      listener:
        type: tcp
    admissions:
    - name: admission-0
      whitelist: true
      matchers:
      - 192.168.0.0/16
      - 127.0.0.1
    - name: admission-1
      matchers:
      - 192.168.0.1
    ```

## 数据源

准入控制器可以配置多个数据源，目前支持的数据源有：内联，文件，redis，HTTP。

### 内联

内联数据源直接在配置文件中通过`matchers`参数设置数据。

```yaml
admissions:
- name: admission-0
  matchers:
  - 127.0.0.1
  - 192.168.0.0/16
  - example.com
```

### 文件

指定外部文件作为数据源。通过`file.path`参数指定文件路径。

```yaml
admissions:
- name: admission-0
  file:
    path: /path/to/file
```

文件格式为按行分割的地址列表，以`#`开始的部分为注释信息。

```text
# ip or cidr

127.0.0.1
192.168.0.0/16
example.com
```

### Redis

指定redis服务作为数据源，redis数据类型必须为[集合(Set)](https://redis.io/docs/data-types/sets/)类型。

```yaml
admissions:
- name: admission-0
  redis:
    addr: 127.0.0.1:6379
    db: 1
    password: 123456
    key: gost:admissions:admission-0
```

`addr` (string, required)
:    redis服务地址

`db` (int, default=0)
:    数据库名

`password` (string)
:    密码

`key` (string, default=gost)
:    redis key

数据的每一项与文件数据源的格式类似：

```redis
> SMEMBERS gost:admissions:admission-0
1) "127.0.0.1"
2) "192.168.0.0/16"
3) "example.com"
```

### HTTP

指定HTTP服务作为数据源。对于所请求的URL，HTTP返回200状态码则认为有效，返回的数据格式与文件数据源相同。

```yaml
admissions:
- name: admission-0
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
admissions:
- name: admission-0
  reload: 10s
  file:
    path: /path/to/file
  redis:
    addr: 127.0.0.1:6379
    db: 1
    password: 123456
    key: gost:admissions:admission-0
  http:
    url: http://127.0.0.1:8000
    timeout: 10s
```

## 插件

准入控制器可以配置为使用外部[插件](/concepts/plugin/)服务，控制器会将请求转发给插件服务处理。当使用插件时其他参数无效。

```yaml
admissions:
- name: admission-0
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
admissions:
- name: admission-0
  plugin:
    type: http
    addr: http://127.0.0.1:8000/admission
```

#### 请求示例

```bash
curl -XPOST http://127.0.0.1:8000/admission -d '{"addr": "example.com"}'
```

```json
{"ok": true}
```