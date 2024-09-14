---
comments: true
---

# 分流

!!! tip "动态配置"
    分流器支持通过[Web API](/tutorials/api/overview/)进行动态配置。


关于分流器的更详细说明和使用示例可以参考这篇[博文](/blog/2022/bypass/)。

## 分流器

在服务，跳跃点和转发链的节点上可以分别设置分流器，在数据转发过程中根据分流器中的规则对目标地址进行匹配测试来决定是否继续转发。

=== "命令行"

    ```bash
    gost -L http://:8080?bypass=10.0.0.0/8 -F http://192.168.1.1:8080?bypass=172.10.0.0/16,127.0.0.1,localhost,*.example.com,.example.org
    ```

    通过`bypass`参数来指定请求的目标地址匹配规则列表，规则是以逗号分割的IP，CIDR，域名或域名通配符。

=== "配置文件"

    ```yaml hl_lines="5 16 21 27 30"
    services:
    - name: service-0
      addr: ":8080"
      # service level bypass
      bypass: bypass-0
      handler:
        type: http
        chain: chain-0
      listener:
        type: tcp
    chains:
    - name: chain-0
      hops:
      - name: hop-0
        # hop level bypass
        bypass: bypass-1
        nodes:
        - name: node-0
          addr: 192.168.1.1:8080
          # node level
          # bypass: bypass-0
          connector:
            type: http
          dialer:
            type: tcp
    bypasses:
    - name: bypass-0
      matchers:
      - 10.0.0.0/8
    - name: bypass-1
      matchers:
      - 172.10.0.0/16
      - 127.0.0.1
      - localhost
      - '*.example.com'
      - .example.org
    ```

    使用`bypass`参数通过引用分流器名称(`bypasses.name`)来使用指定的分流器。

!!! tip "Hop级别的分流器"

    命令行模式下的bypass参数配置会应用到hop级别。

## 黑名单与白名单

分流器默认为黑名单模式，如果目标地址匹配上黑名单则数据转发将终止。

也可以将分流器设置为白名单模式，与黑名单相反，只有目标地址与分流器中的规则相匹配才继续进行数据中转。

=== "命令行"

    ```bash
    gost -L http://:8080 -F http://:8081?bypass=~172.10.0.0/16,127.0.0.1,localhost,*.example.com,.example.org
    ```

    通过在`bypass`参数中增加`~`前缀将分流器设置为白名单模式。

=== "配置文件"

    ```yaml hl_lines="24"
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
        bypass: bypass-0
        nodes:
        - name: node-0
          addr: :8081
          # bypass: bypass-0
          connector:
            type: http
          dialer:
            type: tcp
    bypasses:
    - name: bypass-0
      whitelist: true
      matchers:
      - 172.10.0.0/16
      - 127.0.0.1
      - localhost
      - '*.example.com'
      - .example.org
    ```

    在`bypasses`中通过设置`whitelist`属性为`true`来开启白名单模式。

## 分流器组

通过使用`bypasses`参数来指定分流器列表来使用多个分流器，当任何一个分流器规则未匹配成功则代表未通过。

=== "配置文件"

    ```yaml hl_lines="4 5 6 16 17 18 22 23 24"
    services:
    - name: service-0
      addr: ":8080"
      # bypasses: 
      # - bypass-0
      # - bypass-1
      handler:
        type: http
        chain: chain-0
      listener:
        type: tcp
    chains:
    - name: chain-0
      hops:
      - name: hop-0
        bypasses: 
        - bypass-0
        - bypass-1
        nodes:
        - name: node-0
          addr: :8081
          # bypasses: 
          # - bypass-0
          # - bypass-1
          connector:
            type: http
          dialer:
            type: tcp
    bypasses:
    - name: bypass-0
      whitelist: true
      matchers:
      - 172.10.0.0/16
    - name: bypass-1
      matchers:
      - 127.0.0.1
      - 172.10.0.1
      - localhost
      - '*.example.com'
      - .example.org
    ```

## 端口匹配

对于IP，域名和域名通配符规则也可以包含端口或端口范围，CIDR规则不支持端口匹配。

=== "命令行"

    ```bash
    gost -L http://:8080?bypass=192.168.1.1:80,192.168.1.2:0-65535,example.com:80,.example.com:443
    ```

=== "配置文件"

    ```yaml hl_lines="4"
    services:
    - name: service-0
      addr: ":8080"
      bypass: bypass-0
      handler:
        type: http
      listener:
        type: tcp
    bypasses:
    - name: bypass-0
      matchers:
      - 192.168.1.1:80
      - 192.168.1.1:0-65535
      - example.com:80
      - .example.com:443
    ```

## 分流器类型

### 服务上的分流器

当服务上设置了分流器，如果请求的目标地址未通过分流器规则测试(未匹配白名单规则或匹配黑名单规则)，则此请求会被拒绝。

=== "命令行"

    ```bash
    gost -L http://:8080?bypass=example.com
    ```

=== "配置文件"

    ```yaml hl_lines="4"
    services:
    - name: service-0
      addr: ":8080"
      bypass: bypass-0
      handler:
        type: http
      listener:
        type: tcp
    bypasses:
    - name: bypass-0
      matchers:
      - example.com
    ```

8080端口的HTTP代理服务使用了黑名单分流，`example.org`的请求会正常处理，`example.com`的请求会被拒绝。

### 跳跃点上的分流器

当跳跃点(Hop)上设置了分流器，如果请求的目标地址未通过分流器规则测试(未匹配白名单规则或匹配黑名单规则)，则转发链将终止于此跳跃点，且不包括此跳跃点。

=== "命令行"

    ```bash
    gost -L http://:8080 -F http://:8081?bypass=~example.com,.example.org -F http://:8082?bypass=example.com
    ```

=== "配置文件"

    ```yaml hl_lines="13 22"
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
        bypass: bypass-0
        nodes:
        - name: node-0
          addr: :8081
          connector:
            type: http
          dialer:
            type: tcp
      - name: hop-1
        bypass: bypass-1
        nodes:
        - name: node-0
          addr: :8082
          connector:
            type: http
          dialer:
            type: tcp
    bypasses:
    - name: bypass-0
      whitelist: true
      matchers:
      - example.com
      - .example.org
    - name: bypass-1
      matchers:
      - example.com
    ```

当请求`www.example.com`时未通过第一个跳跃点(hop-0)的分流器(bypass-0)，因此请求不会使用转发链。

当请求`example.com`时，通过第一个跳跃点(hop-0)的分流器(bypass-0)，但未通过第二个跳跃点(hop-1)的分流器(bypass-1)，因此请求将使用转发链第一层级的节点(:8081)进行数据转发。

当请求`www.example.org`时，通过两个跳跃点的分流器，因此请求将使用完整的转发链进行转发。

### 转发链节点上的分流器

当转发链使用多个节点时，可以通过在节点上设置分流器来对请求进行精准分流。

=== "配置文件"

    ```yaml hl_lines="16 23"
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
          addr: :8081
          bypass: bypass-0
          connector:
            type: http
          dialer:
            type: tcp
        - name: node-1
          addr: :8082
          bypass: bypass-1
          connector:
            type: http
          dialer:
            type: tcp
    bypasses:
    - name: bypass-0
      matchers:
      - example.org
    - name: bypass-1
      matchers:
      - example.com
    ```

当请求`example.com`时，通过了节点node-0上的分流器bypass-0，但未通过节点node-1上的分流器bypass-1，因此请求只会使用节点node-0进行转发。

当请求`example.org`时，未通过节点node-0上的分流器bypass-0，通过了节点node-1上的分流器，因此请求只会使用节点node-1进行转发。

### 转发器节点上的分流器

此类型分流器类似于转发链节点上的分流器，目前仅应用于[DNS代理服务](/tutorials/dns/)。

## 数据源

分流器可以配置多个数据源，目前支持的数据源有：内联，文件，redis，HTTP。

### 内联

内联数据源直接在配置文件中通过`matchers`参数设置数据。

```yaml
bypasses:
- name: bypass-0
  matchers:
  - 127.0.0.1
  - 172.10.0.0/16
  - localhost
  - '*.example.com'
  - .example.org
```

### 文件

指定外部文件作为数据源。通过`file.path`参数指定文件路径。

```yaml
bypasses:
- name: bypass-0
  file:
    path: /path/to/file
```

文件格式为按行分割的地址列表，以`#`开始的部分为注释信息。

```txt
# ip, cidr, domain or wildcard
127.0.0.1
172.10.0.0/16
localhost
*.example.com
.example.org
```

### Redis

指定redis服务作为数据源，redis数据类型必须为[集合(Set)](https://redis.io/docs/data-types/sets/)类型。

```yaml
bypasses:
- name: bypass-0
  redis:
    addr: 127.0.0.1:6379
    db: 1
    password: 123456
    key: gost:bypasses:bypass-0
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
> SMEMBERS gost:bypasses:bypass-0
1) "127.0.0.1"
2) "172.10.0.0/16"
3) "localhost"
4) "*.example.com"
5) ".example.org"
```

### HTTP

指定HTTP服务作为数据源。对于所请求的URL，HTTP返回200状态码则认为有效，返回的数据格式与文件数据源相同。

```yaml
bypasses:
- name: bypass-0
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
bypasses:
- name: bypass-0
  reload: 10s
  file:
    path: /path/to/file
  redis:
    addr: 127.0.0.1:6379
    db: 1
    password: 123456
    key: gost:bypasses:bypass-0
  http:
    url: http://127.0.0.1:8000
    timeout: 10s
```

## 插件

分流器可以配置为使用外部[插件](/concepts/plugin/)服务，分流器会将请求转发给插件服务处理。当使用插件时其他参数无效。

```yaml
bypasses:
- name: bypass-0
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
bypasses:
- name: bypass-0
  plugin:
    type: http
    addr: http://127.0.0.1:8000/bypass
```

#### 请求示例

```bash
curl -XPOST http://127.0.0.1:8000/bypass -d '{"addr": "example.com:80", "client": "gost"}'
```

```json
{"ok": true}
```

`client` (string)
:    用户身份标识，此信息由认证器生成。

!!! tip "基于用户标识的分流"
    GOST内部的分流器逻辑未处理针对特定用户的分流逻辑，如果需要实现此功能需要组合使用认证器和分流器插件。
    
    认证器在认证成功后返回用户标识，GOST会将此用户标识信息再次传递给分流器插件服务，分流器插件服务就可以根据用户标识来做不同的分流策略。