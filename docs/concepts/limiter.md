---
comments: true
---

# 限速限流

!!! tip "动态配置"
    限速器支持通过[Web API](../tutorials/api/overview.md)进行动态配置。

## 限制器

在每个服务上可以通过设置限制器来对请求进行限制，目前的限制器支持对上下行流量速率，请求速率和并发连接数的限制。

### 流量速率限制

流量速率限制包括服务，连接和IP三个级别的限速，三个级别可以组合使用。

=== "命令行"

    ```bash
    gost -L ":8080?limiter.in=100MB&limiter.out=100MB&limiter.conn.in=10MB&limiter.conn.out=10MB"
    ```

=== "配置文件"

    ```yaml hl_lines="4 10"
    services:
    - name: service-0
      addr: ":8080"
      limiter: limiter-0
      handler:
        type: auto
      listener:
        type: tcp
      metadata:
        limiter.refreshInterval: 30s
        limiter.scope: service
    limiters:
    - name: limiter-0
      limits:
      - '$ 100MB 100MB'
      - '$$ 10MB'
      - '192.168.1.1  512KB 1MB'
      - '192.168.0.0/16  1MB  5MB'
    ```

命令行中通过`limiter.in`和`limiter.out`来设置服务级别的限速，通过`limiter.conn.in`和`limiter.conn.out`来设置连接级别的限速。

配置文件中使用`limiter`参数通过引用限速器名称(`limiters.name`)来使用指定的限速器。

通过`limits`选项指定配置列表，每一个配置项包含空格分割的三个部分：

* 作用域(Scope)：限速作用范围，IP地址或CIDR，例如192.168.1.1，192.168.0.0/16。其中两个特殊的值: `$`代表服务级别，`$$`代表连接级别。

* 入站速率(Input)：服务接收数据的速率(每秒流量)，支持的单位有: B，KB，MB，GB，TB，例如 128KB，1MB，10GB。0或负值代表无限制。

* 出站速率(Output)：服务发送数据的速率(每秒流量)，单位同入站速率。出站速率可选，0或负值代表无限制。

`limiter.refreshInterval` (duration, default=30s)
:    设置限制器插件同步配置间隔时长。

`limiter.scope` (string) :material-tag: 3.1.0
:    设置限制器插件请求作用域。 `service` - 仅请求服务级别，`conn` - 仅请求连接级别。默认(不设置或为空)同时请求服务级别和连接级别。

### 请求速率限制

请求速率限制包括服务，IP两个级别的限速，两个级别可以组合使用。

=== "命令行"

    ```bash
    gost -L ":8080?rlimiter=10"
    ```

=== "配置文件"

    ```yaml hl_lines="4 10"
    services:
    - name: service-0
      addr: ":8080"
      rlimiter: rlimiter-0
      handler:
        type: auto
      listener:
        type: tcp
    rlimiters:
    - name: rlimiter-0
      limits:
      - '$ 100'
      - '$$ 10'
      - '192.168.1.1  50'
      - '192.168.0.0/16  5'
    ```

命令行中通过`rlimiter`来设置服务级别的请求速率限制(每秒请求数)。

配置文件中使用`rlimiter`参数通过引用限制器名称(`rlimiters.name`)来使用指定的限制器。

通过`limits`选项指定配置列表，每一个配置项包含空格分割的两个部分：

* 作用域(Scope)：作用范围，IP地址或CIDR，例如192.168.1.1，192.168.0.0/16。其中两个特殊的值: `$`代表服务级别，`$$`代表IP级别默认限制，当给特定IP或CIDR设置了限制数，则`$$`会被忽略。

* 请求速率(Rate)：请求速率值(每秒请求数)。

### 并发连接数限制

并发连接数限制包括服务，IP两个级别的限速，两个级别可以组合使用。

=== "命令行"

    ```bash
    gost -L ":8080?climiter=1000"
    ```

=== "配置文件"

    ```yaml hl_lines="4 10"
    services:
    - name: service-0
      addr: ":8080"
      climiter: climiter-0
      handler:
        type: auto
      listener:
        type: tcp
    climiters:
    - name: climiter-0
      limits:
      - '$ 1000'
      - '$$ 100'
      - '192.168.1.1  10'
    ```

命令行中通过`climiter`来设置服务级别的最大并发连接数。

配置文件中使用`climiter`参数通过引用限制器名称(`climiters.name`)来使用指定的限制器。

通过`limits`选项指定配置列表，每一个配置项包含空格分割的两个部分：

* 作用域(Scope)：作用范围，IP地址或CIDR，例如192.168.1.1，192.168.0.0/16。其中两个特殊的值: `$`代表服务级别，`$$`代表IP级别默认限制，当给特定IP或CIDR设置了限制数，则`$$`会被忽略。

* 最大连接数(Limit)：最大并发连接数值。

## 数据源

限制器可以配置多个数据源，目前支持的数据源有：内联，文件，redis。

### 内联

内联数据源是指直接在配置文件中通过`limits`参数设置数据。

=== "流量速率"

    ```yaml
    limiters:
    - name: limiter-0
      limits:
      - $ 100MB  200MB
      - $$ 10MB
      - 192.168.1.1  1MB 10MB
      - 192.168.0.0/16  512KB  1MB
    ```

=== "请求速率"

    ```yaml
    rlimiters:
    - name: rlimiter-0
      limits:
      - $ 100
      - $$ 10
      - 192.168.1.1  50
      - 192.168.0.0/16  5
    ```

=== "并发连接"

    ```yaml
    climiters:
    - name: climiter-0
      limits:
      - $ 1000
      - $$ 100
      - 192.168.1.1  200
      - 192.168.0.0/16  50
    ```

### 文件

指定外部文件作为数据源。通过`file.path`参数指定文件路径。

=== "流量速率"

    ```yaml
    limiters:
    - name: limiter-0
      file:
        path: /path/to/file
    ```

=== "请求速率"

    ```yaml
    rlimiters:
    - name: rlimiter-0
      file:
        path: /path/to/file
    ```

=== "并发连接"

    ```yaml
    climiters:
    - name: climiter-0
      file:
        path: /path/to/file
    ```

文件格式为按行分割的限速配置列表，以`#`开始的部分为注释信息，每项配置格式同内联配置。

=== "流量速率"

    ```yaml
    # ip/cidr  input  output(optional)

    $ 100MB  200MB
    $$ 10MB
    192.168.1.1  1MB 10MB
    192.168.0.0/16  512KB  1MB
    ```

=== "请求速率"

    ```yaml
    # ip/cidr  rate(r/s)

    $ 100
    $$ 10
    192.168.1.1  20
    192.168.0.0/16  50
    ```

=== "并发连接"

    ```yaml
    # ip/cidr  limit

    $ 1000
    $$ 100
    192.168.1.1  200
    192.168.0.0/16  50
    ```

### Redis

指定redis服务作为数据源，redis数据类型必须为[集合(Set)](https://redis.io/docs/data-types/sets/)或[列表(List)](https://redis.io/docs/data-types/lists/)类型，每项配置格式同内联配置。

=== "流量速率"

    ```yaml
    limiters:
    - name: limiter-0
      redis:
        addr: 127.0.0.1:6379
        db: 1
        password: 123456
        key: gost:limiters:limiter-0
        type: set
    ```

=== "请求速率"

    ```yaml
    rlimiters:
    - name: rlimiter-0
      redis:
        addr: 127.0.0.1:6379
        db: 1
        username: user
        password: 123456
        key: gost:rlimiters:rlimiter-0
        type: set
    ```

=== "并发连接"

    ```yaml
    climiters:
    - name: climiter-0
      redis:
        addr: 127.0.0.1:6379
        db: 1
        username: user
        password: 123456
        key: gost:climiters:climiter-0
        type: set
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

`type` (string, default=set)
:    数据类型，支持的类型有：集合(`set`)，列表(`list`)。

数据的每一项与文件数据源的格式类似：

=== "流量速率"

    ```redis
    > SMEMBERS gost:limiters:limiter-0
    1) "$ 100MB  200MB"
    2) "$$ 10MB"
    3) "192.168.1.1  1MB 10MB"
    4) "192.168.0.0/16  512KB  1MB"
    ```

=== "请求速率"

    ```redis
    > SMEMBERS gost:rlimiters:rlimiter-0
    1) "$ 100"
    2) "$$ 10"
    3) "192.168.1.1  20"
    4) "192.168.0.0/16  50"
    ```

=== "并发连接"

    ```redis
    > SMEMBERS gost:climiters:climiter-0
    1) "$ 1000"
    2) "$$ 100"
    3) "192.168.1.1  200"
    4) "192.168.0.0/16  50"
    ```

### HTTP

指定HTTP服务作为数据源。对于所请求的URL，HTTP返回200状态码则认为有效，返回的数据格式与文件数据源相同。

=== "流量速率"

    ```yaml
    limiters:
    - name: limiter-0
      http:
        url: http://127.0.0.1:8000
        timeout: 10s
    ```

=== "请求速率"

    ```yaml
    rlimiters:
    - name: rlimiter-0
      http:
        url: http://127.0.0.1:8000
        timeout: 10s
    ```

=== "并发连接"

    ```yaml
    climiters:
    - name: climiter-0
      http:
        url: http://127.0.0.1:8000
        timeout: 10s
    ```

`url` (string, required)
:    请求的URL

`timeout` (duration, default=0)
:    请求超时时长

## 优先级

当同时配置多个数据源时，优先级从高到低为: HTTP，redis，文件，内联。如果在不同数据源中存在相同的作用域，则优先级高的会覆盖优先级低的配置。

## 热加载

文件，redis，HTTP数据源支持热加载。通过设置`reload`参数开启热加载，`reload`参数指定同步数据源数据的周期。

```yaml hl_lines="3"
limiters:
- name: limiter-0
  reload: 60s
  file:
    path: /path/to/file
  redis:
    addr: 127.0.0.1:6379
    db: 1
    password: 123456
    key: gost:limiters:limiter-0
  http:
    url: http://127.0.0.1:8000
    timeout: 10s
```

## 插件

对于流量速率限制器可以配置为使用外部[插件](plugin.md)服务，限制器会将查询请求转发给插件服务处理。当使用插件时其他参数无效。

```yaml
limiters:
- name: limiter-0
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
limiters:
- name: limiter-0
  plugin:
    type: http
    addr: http://127.0.0.1:8000/limiter
```

#### 请求示例

```bash
curl -XPOST http://127.0.0.1:8000/limiter \
-d'{"scope":"client","service":"service-0","network":"tcp","addr":"example.com:443","client":"gost","src":"192.168.1.1:12345"}'
```

```json
{"in":1048576, "out":524288}
```

`scope` (string)
:    作用域，`service` - 服务级别，`conn` - 连接级别，`client` - 用户级别。

`service` (string)
:    服务名。

`network` (string)
:    网络地址类型：`tcp`，`udp`。

`addr` (string)
:    请求目标地址。

`client` (string)
:    用户身份标识，此信息由认证器生成。

`src` (string)
:    客户端地址。

`in` (int64)
:    入站速率(bytes/s)，0或负值代表无限制。

`out` (int64)
:    出站速率(bytes/s)，0或负值代表无限制。

## 处理器(Handler)上的限制器

对于支持认证的处理器(HTTP，HTTP2，SOCKS4，SOCKS5，Relay，Tunnel)，流量速率限制器也可以用在这些类型的处理器上。

```yaml hl_lines="6"
services:
- name: service-0
  addr: ":8080"
  handler:
    type: http
    limiter: limiter-0
    metadata:
      limiter.refreshInterval: 30s
  listener:
    type: tcp
limiters:
- name: limiter-0
  plugin:
    addr: 127.0.0.1:8000
```

### 基于用户标识的限流

GOST内部的限制器逻辑未处理针对特定用户的流量限制，如果需要实现此功能需要组合使用认证器和处理器上的限制器插件。
    
认证器在认证成功后返回用户标识，GOST会将此用户标识信息再次传递给限制器插件服务，并设置作用域为用户级别(scope=client)，限制器插件服务就可以根据用户标识来做不同的限流配置。

!!! tip "Tunnel处理器"
    对于Tunnel处理器，限流单位为单个隧道，client值为Tunnel ID。