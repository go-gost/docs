# Limiting

!!! tip "Dynamic configuration"
    Limiter supports dynamic configuration via [Web API](/en/tutorials/api/overview/).

## Limiter

Requests can be limited by setting Limiters on each service. The current Limiter supports the limit on the bandwidth, request rate and max connections.

### Bandwidth Limiter

This type of limiter includes three levels: service, connection and IP, the three levels can be used in combination.

=== "CLI"

    ```bash
    gost -L ":8080?limiter.in=100MB&limiter.out=100MB&limiter.conn.in=10MB&limiter.conn.out=10MB"
    ```

=== "File (YAML)"

    ```yaml hl_lines="4 10"
    services:
    - name: service-0
      addr: ":8080"
      limiter: limiter-0
      handler:
        type: auto
      listener:
        type: tcp
    limiters:
    - name: limiter-0
      limits:
      - '$ 100MB 100MB'
      - '$$ 10MB'
      - '192.168.1.1  512KB 1MB'
      - '192.168.0.0/16  1MB  5MB'
    ```

The service-level rate limit is set through `limiter.in` and `limiter.out` on the command line, and the connection-level is set through `limiter.conn.in` and `limiter.conn.out` level speed limit.

Use the `limiter` parameter in the configuration file to use the specified limiter by referencing the limiter name (`limiters.name`).

A list of configurations is specified via the `limits` option, each configuration item consists of three parts separated by spaces:

* Scope: Limit scope, IP address or CIDR, such as 192.168.1.1, 192.168.0.0/16. There are two special values: `$` for service level and `$$` for connection level.

* Input: The rate at which the service receives data (per second). The supported units are: B, KB, MB, GB, TB, such as 128KB, 1MB, 10GB.

* Output: The rate at which the service sends data (per second), in the same unit as the input rate. The output rate is optional, if not set, it means unlimited.

### Request Rate Limiter

This type of limiter includes two levels: service and IP, the two levels can be used in combination.

=== "CLI"

    ```bash
    gost -L ":8080?rlimiter=10"
    ```

=== "File (YAML)"

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

The service-level request rate limit (requests per second) is set by `rlimiter` on the command line.

Use the `rlimiter` parameter in the configuration file to use the specified limiter by referencing the limiter name (`rlimiters.name`).

A list of configurations is specified via the `limits` option, each configuration item consists of three parts separated by spaces:

* Scope: Limit scope, IP address or CIDR, such as 192.168.1.1, 192.168.0.0/16. There are two special values: `$` for service level and `$$` for IP level. When a limit is set for a specific IP or CIDR, `$$` is ignored.

* Limit: Request rate limit value (request per second).

### Max Connections Limiter

This type of limiter includes two levels: service and IP, the two levels can be used in combination.

=== "CLI"

    ```bash
    gost -L ":8080?climiter=1000"
    ```

=== "File (YAML)"

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

The service-level limit is set by `climiter` on the command line.

Use the `climiter` parameter in the configuration file to use the specified limiter by referencing the limiter name (`climiters.name`).

A list of configurations is specified via the `limits` option, each configuration item consists of three parts separated by spaces:

* Scope: Limit scope, IP address or CIDR, such as 192.168.1.1, 192.168.0.0/16. There are two special values: `$` for service level and `$$` for IP level. When a limit is set for a specific IP or CIDR, `$$` is ignored.

* Limit: Max connections limit value.

## Data Source

The limiter can configure multiple data sources, currently supported data sources are: inline, file, redis.


### Inline

An inline data source means setting the data directly in the configuration file via the `limits` option.

=== "Bandwidth Limiter"

    ```yaml
    limiters:
    - name: limiter-0
      limits:
      - $ 100MB  200MB
      - $$ 10MB
      - 192.168.1.1  1MB 10MB
      - 192.168.0.0/16  512KB  1MB
    ```

=== "Request Rate Limiter"

    ```yaml
    rlimiters:
    - name: rlimiter-0
      limits:
      - $ 100
      - $$ 10
      - 192.168.1.1  50
      - 192.168.0.0/16  5
    ```

=== "Max Conn Limiter"

    ```yaml
    climiters:
    - name: climiter-0
      limits:
      - $ 1000
      - $$ 100
      - 192.168.1.1  200
      - 192.168.0.0/16  50
    ```

### File

Specify an external file as the data source. Specify the file path via the `file.path` option.

=== "Bandwidth Limiter"

    ```yaml
    limiters:
    - name: limiter-0
      file:
        path: /path/to/file
    ```

=== "Request Rate Limiter"

    ```yaml
    rlimiters:
    - name: rlimiter-0
      file:
        path: /path/to/file
    ```

=== "MaxConn Limiter"

    ```yaml
    climiters:
    - name: climiter-0
      file:
        path: /path/to/file
    ```

The file format is a list of speed limit configurations separated by lines. The part starting with `#` is the comment information. The format of each line is the same as the inline configuration.

=== "Bandwidth Limiter"

    ```yaml
    # ip/cidr  input  output(optional)

    $ 100MB  200MB
    $$ 10MB
    192.168.1.1  1MB 10MB
    192.168.0.0/16  512KB  1MB
    ```

=== "Request Rate Limiter"

    ```yaml
    # ip/cidr  rate(r/s)

    $ 100
    $$ 10
    192.168.1.1  20
    192.168.0.0/16  50
    ```

=== "MaxConn Limiter"

    ```yaml
    # ip/cidr  limit

    $ 1000
    $$ 100
    192.168.1.1  200
    192.168.0.0/16  50
    ```

### Redis

Specify the redis service as the data source, and the redis data type must be Set or List. The format of each item is the same as the inline configuration. 

=== "Bandwidth Limiter"

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

=== "Request Rate Limiter"

    ```yaml
    rlimiters:
    - name: rlimiter-0
      redis:
        addr: 127.0.0.1:6379
        db: 1
        password: 123456
        key: gost:rlimiters:rlimiter-0
        type: set
    ```

=== "MaxConn Limiter"

    ```yaml
    climiters:
    - name: climiter-0
      redis:
        addr: 127.0.0.1:6379
        db: 1
        password: 123456
        key: gost:climiters:climiter-0
        type: set
    ```

`addr` (string, required)
:    redis server address.

`db` (int, default=0)
:    database name.

`password` (string)
:    password

`key` (string, default=gost)
:    redis key

`type` (string, default=set)
:    redis data type: `set`, `list`

Each item of data is in a similar format to the file data source:

=== "Bandwidth Limiter"

    ```redis
    > SMEMBERS gost:limiters:limiter-0
    1) "$ 100MB  200MB"
    2) "$$ 10MB"
    3) "192.168.1.1  1MB 10MB"
    4) "192.168.0.0/16  512KB  1MB"
    ```

=== "Request Rate Limiter"

    ```redis
    > SMEMBERS gost:rlimiters:rlimiter-0
    1) "$ 100"
    2) "$$ 10"
    3) "192.168.1.1  20"
    4) "192.168.0.0/16  50"
    ```

=== "MaxConn Limiter"

    ```redis
    > SMEMBERS gost:climiters:climiter-0
    1) "$ 1000"
    2) "$$ 100"
    3) "192.168.1.1  200"
    4) "192.168.0.0/16  50"
    ```

## Priority

When configuring multiple data sources at the same time, the priority from high to low is: redis, file, inline. If the same scop exists in different data sources, the data with higher priority will overwrite the data with lower priority.

## Hot Reload

File and redis data sources support hot reloading. Enable hot loading by setting the `reload` property, which specifies the period for synchronizing the data source data.

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
```

## Plugin

对于流量速率限制器可以配置为使用外部[插件](/concepts/plugin/)服务，限制器会将查询请求转发给插件服务处理。当使用插件时其他参数无效。
Traffic limiter can be configured to use an external [plugin](/en/concepts/plugin/) service, and it will forward the request to the plugin server for processing. Other parameters are ignored when using plugin.

```yaml
limiters:
- name: limiter-0
  plugin:
    type: grpc
    # type: http
    addr: 127.0.0.1:8000
    tls: 
      secure: false
      serverName: example.com
```

`addr` (string, required)
:    plugin server address.

`tls` (duration, default=null)
:    TLS encryption will be used for transmission, TLS encryption is not used by default.

### HTTP Plugin

```yaml
limiters:
- name: limiter-0
  plugin:
    type: http
    addr: http://127.0.0.1:8000/limiter
```

#### Example

```bash
curl -XPOST http://127.0.0.1:8000/limiter \
-d'{"network":"tcp","addr":"example.com:443","client":"gost","src":"192.168.1.1:12345"}'
```

```json
{"in":1048576, "out":524288}
```

`network` (string, default=ip4)
:    network types: `tcp`,`udp`.

`addr` (string)
:    target request address

`client` (string)
:    user ID, generated by Authenticator plugin.

`src` (string)
:    client source address

`in` (int64)
:    Input rate(bytes/s)

`out` (int64)
:    Output rate(bytes/s)

## Limiter In Service Handler

For proxy services (HTTP, HTTP2, SOCKS4, SOCKS5, Relay), traffic limiter is also available to the Handler.

```yaml hl_lines="6"
services:
- name: service-0
  addr: ":8080"
  handler:
    type: http
    limiter: limiter-0
  listener:
    type: tcp
limiters:
- name: limiter-0
  plugin:
    addr: 127.0.0.1:8000
```

!!! tip "Limiter Based On Client ID"
    The GOST internal Limiter does not handle the logic for specific clients. If you need to implement this function, you can use an Authenticator plugin and a Handler Limiter plugin in combination. 
    
    The Authenticator plugin returns the client ID after successful authentication. GOST will pass this client ID information to the Limiter plugin server again, and the Limiter plugin server can implement different strategies based on the client ID.
    