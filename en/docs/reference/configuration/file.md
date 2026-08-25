# Configuration file

GOST configuration file supports `yaml` and `json` format, the complete configuration structure is as follows:

=== "yaml"

    ```yaml
    services:
    - name: service-0
      addr: ":8080"
      interface: eth0
      sockopts:
        mark: 1
      admission: admission-0
      bypass: bypass-0
      resolver: resolver-0
      hosts: hosts-0
      handler:
        type: http
        auth:
          username: user
          password: pass
        auther: auther-0
        chain: chain-0
        retries: 1
        metadata: 
          foo: bar
          bar: baz
      listener:
        type: tcp
        auth:
          username: user
          password: pass
        auther: auther-0
        chain: chain-0
        tls:
          certFile: cert.pem
          keyFile: key.pem
          caFile: ca.pem
        metadata:
          abc: xyz
          def: 456
      forwarder:
        nodes:
        - name: target-0
          addr: 192.168.1.1:1234
        - name: target-1
          addr: 192.168.1.2:2345
        selector:
          strategy: rand
          maxFails: 1
          failTimeout: 30s

    chains:
    - name: chain-0
      selector:
        strategy: round
        maxFails: 1
        failTimeout: 30s
      hops:
      - name: hop-0
        interface: 192.168.1.2
        sockopts:
          mark: 1
        selector:
          strategy: rand
          maxFails: 3
          failTimeout: 60s
        bypass: bypass-0
        nodes:
        - name: node-0
          addr: ":1080"
          interface: eth1
          sockopts:
            mark: 1
          bypass: bypass-0
          connector:
            type: socks5
            auth:
              username: user
              password: pass
            metadata:
              foo: bar
          dialer:
            type: tcp
            auth:
              username: user
              password: pass
            tls:
              caFile: "ca.pem"
              secure: true
              serverName: "example.com"
            metadata:
              bar: baz 

    tls:
      certFile: "cert.pem"
      keyFile: "key.pem"
      caFile: "ca.pem"

    authers:
    - name: auther-0
      auths:
      - username: user1
        password: pass1
      - username: user2
        password: pass2

    admissions:
    - name: admission-0
      whitelist: false
      matchers:
      - 127.0.0.1
      - 192.168.0.0/16

    bypasses:
    - name: bypass-0
      whitelist: false
      matchers:
      - "*.example.com"
      - .example.org
      - 0.0.0.0/8

    resolvers:
    - name: resolver-0
      nameservers:
      - addr: udp://8.8.8.8:53
        chain: chain-0
        ttl: 60s
        prefer: ipv4
        clientIP: 1.2.3.4
        timeout: 3s
      - addr: tcp://1.1.1.1:53
      - addr: tls://1.1.1.1:853
      - addr: https://1.0.0.1/dns-query
        hostname: cloudflare-dns.com

    hosts:
    - name: hosts-0
      mappings:
      - ip: 127.0.0.1
        hostname: localhost
      - ip: 192.168.1.10
        hostname: foo.mydomain.org
        aliases:
        - foo
      - ip: 192.168.1.13
        hostname: bar.mydomain.org
        aliases:
        - bar
        - baz

    recorders:
    - name: recorder-0
      file:
        path: /path/to/recorder/file
        sep: "\n"
        rotation:
          maxSize: 100
          maxAge: 10
          maxBackups: 3
          localTime: false
          compress: false

    log:
      output: stderr
      level: debug
      format: json
      rotation:
        maxSize: 100
        maxAge: 10
        maxBackups: 3
        localTime: false
        compress: false

    profiling:
      addr: ":6060"
    
    api:
      addr: ":18080"
      pathPrefix: /api
      accesslog: true
      auth:
        username: user
        password: pass
      auther: auther-0

    metrics:
      addr: :9000
      path: /metrics
    ```

=== "json"

    ```json
    {
      "services": [
        {
          "name": "service-0",
          "addr": ":8080",
          "interface": "eth0",
          "admission": "admission-0",
          "bypass": "bypass-0",
          "resolver": "resolver-0",
          "hosts": "hosts-0",
          "handler": {
            "type": "http",
            "auth": {
              "username": "gost",
              "password": "gost"
            },
            "auther": "auther-0",
            "retries": 1,
            "chain": "chain-0",
            "metadata": {
              "bar": "baz",
              "foo": "bar"
            }
          },
          "listener": {
            "type": "tcp",
            "auth": {
              "username": "user",
              "password": "pass"
            },
            "auther": "auther-0",
            "chain": "chain-0",
            "tls": {
              "certFile": "cert.pem",
              "keyFile": "key.pem",
              "caFile": "ca.pem"
            },
            "metadata": {
              "abc": "xyz",
              "def": 456
            }
          },
          "forwarder": {
            "nodes": [
              {
                "name": "target-0",
                "addr": "192.168.1.1:1234"
              },
              {
                "name": "target-1",
                "addr": "192.168.1.2:2345"
              }
            ],
            "selector": {
              "strategy": "rand",
              "maxFails": 1,
              "failTimeout": 30
            }
          }
        }
      ],
      "chains": [
        {
          "name": "chain-0",
          "selector": {
            "strategy": "round",
            "maxFails": 1,
            "failTimeout": 30
          },
          "hops": [
            {
              "name": "hop-0",
              "interface": "192.168.1.2",
              "selector": {
                "strategy": "rand",
                "maxFails": 3,
                "failTimeout": 60
              },
              "bypass": "bypass-0",
              "nodes": [
                {
                  "name": "node-0",
                  "addr": ":1080",
                  "interface": "eth1",
                  "bypass": "bypass-0",
                  "connector": {
                    "type": "socks5",
                    "auth": {
                      "username": "user",
                      "password": "pass"
                    },
                    "metadata": {
                      "foo": "bar"
                    }
                  },
                  "dialer": {
                    "type": "tcp",
                    "auth": {
                      "username": "user",
                      "password": "pass"
                    },
                    "tls": {
                      "caFile": "ca.pem",
                      "secure": true,
                      "serverName": "example.com"
                    },
                    "metadata": {
                      "bar": "baz"
                    }
                  }
                }
              ]
            }
          ]
        }
      ],
      "authers": [
        {
          "name": "auther-0",
          "auths": [
            {
              "username": "user1",
              "password": "pass1"
            },
            {
              "username": "user2",
              "password": "pass2"
            }
          ]
        }
      ],
      "admissions": [
        {
          "name": "admission-0",
          "whitelist": false,
          "matchers": [
            "127.0.0.1",
            "192.168.0.0/16"
          ]
        }
      ],
      "bypasses": [
        {
          "name": "bypass-0",
          "whitelist": false,
          "matchers": [
            "*.example.com",
            ".example.org",
            "0.0.0.0/8"
          ]
        }
      ],
      "resolvers": [
        {
          "name": "resolver-0",
          "nameservers": [
            {
              "addr": "udp://8.8.8.8:53",
              "chain": "chain-0",
              "prefer": "ipv4",
              "clientIP": "1.2.3.4",
              "ttl": 60,
              "timeout": 30
            },
            {
              "addr": "tcp://1.1.1.1:53"
            },
            {
              "addr": "tls://1.1.1.1:853"
            },
            {
              "addr": "https://1.0.0.1/dns-query",
              "hostname": "cloudflare-dns.com"
            }
          ]
        }
      ],
      "hosts": [
        {
          "name": "hosts-0",
          "mappings": [
            {
              "ip": "127.0.0.1",
              "hostname": "localhost"
            },
            {
              "ip": "192.168.1.10",
              "hostname": "foo.mydomain.org",
              "aliases": [
                "foo"
              ]
            },
            {
              "ip": "192.168.1.13",
              "hostname": "bar.mydomain.org",
              "aliases": [
                "bar",
                "baz"
              ]
            }
          ]
        }
      ],
      "tls": {
        "certFile": "cert.pem",
        "keyFile": "key.pem",
        "caFile": "ca.pem"
      },
      "recorders": [
        {
          "name": "recorder-0",
          "file": {
            "path": "/path/to/recorder/file",
            "sep": "\n",
            "rotation": {
              "maxSize": 100,
              "maxAge": 10,
              "maxBackups": 3,
              "localTime": false,
              "compress": false
            }
          }
        }
      ],
      "log": {
        "output": "stderr",
        "level": "debug",
        "format": "json",
        "rotation": {
          "maxSize": 100,
          "maxAge": 10,
          "maxBackups": 3,
          "localTime": false,
          "compress": false
        }
      },
      "profiling": {
        "addr": ":6060",
        "enabled": true
      },
      "api": {
        "addr": ":18080",
        "pathPrefix": "/api",
        "accesslog": true,
        "auth": {
          "username": "user",
          "password": "password"
        },
        "auther": "auther-0"
      },
      "metrics": {
        "addr": ":9000",
        "path": "/metrics"
      }
    }
    ```

## Service

`name` (string, required)
:    service name

`addr` (string, required)
:    service address

`interface` (string)
:    network interface name or IP address

`sockopts` (object)
:    Socket options

`admission` (string, ref)
:    admission name, reference to `admissions.name`

`bypass` (string, ref)
:    bypass name, reference to `bypasses.name`

`resolver` (string, ref)
:    resolver name, reference to `resolvers.name`

`hosts` (string, ref)
:    hosts name, reference to `hosts.name`

`handler` (object, required)
:   handler object

`listener` (object, required)
:    listener object

`forwarder` (object)
:    forward object

### Handler

`type` (string, required)
:    handler type

`auther` (string)
:    auther name, reference to `authers.name`

`auth` (object)
:    auth info, ignored when `auther` is used.

`chain` (string, ref)
:    chain name, reference to `chains.name`

`retries` (int, default=0)
:    retry times after handler error

`metadata` (map)
:    options for handler

### Listener
    
`type` (string, required) 
:    监听器类型

`chain` (string, ref)
:    转发链名称，对应`chains.name`

`auther` (string)
:    认证器名称，引用`authers.name`

`auth` (object)
:    认证信息，如果设置了`auther`，此字段无效。

`tls` (object)
:    监听器实例TLS配置

`metadata` (map)
:    监听器实例相关参数

### Forwarder

`hop` (string, ref)
:    Reference to a named hop in `hops`. Mutually exclusive with `hopGroup` and inline nodes.

`hopGroup` (object)
:    :material-tag: 3.3.0 — Group of named hops with per-entry matchers and probes. See [Hop Group](../../concepts/forwarder.md#hop-group).

`hopGroup.hops` (list, required)
:    List of hop entries with `hop`, `matcher`, and `probe` fields.

`hopGroup.selector` (object)
:    Group-level load balancing selector. Supports the same [strategies](#selector) as the node selector.

`nodes` (objects)
:    target node list

`selector` (object)
:    load balancing strategy

## Chain

`name` (string, required)
:    转发链名称

`selector` (object)
:    Chain-level node selector for load balancing. Applies to nodes across all hops in the chain.

`hops` (hop-list)
:    Hop list

## Chain Group (chainGroup)

:material-tag: 3.3.0

The `chainGroup` parameter on a service's listener or handler selects from multiple chains using
a matcher-based routing DSL. Each chain entry can have its own matcher rule and health-check probe.

```yaml
chainGroup:
  chains:
  - chain: chain-primary
    matcher:
      rule: Host(`api.example.com`)
    probe:
      type: tcp
      addr: 127.0.0.1:8081
      interval: 10s
  - chain: chain-fallback
  selector:
    strategy: round
    maxFails: 1
    failTimeout: 30s
```

`chains` (list, required)
:    Chain entry list. Each entry is a chain reference string or a structured object.

### Chain Entry

`chain` (string, required)
:    Chain name, reference to `chains.name`.

`matcher` (object)
:    Optional routing rule. See [Node Matcher](#node-matcher) for the DSL reference.
     Nil = catch-all (always eligible). The matcher sees the target hostname from
     the request context.

`matcher.rule` (string)
:    Routing rule expression using the same DSL as [Node Matcher](#node-matcher).
     Common functions at the chain-group level: `Host()`, `ClientIP()`.
     See [Matcher](../../concepts/matcher.md) for the full DSL reference.

`probe` (object)
:    Optional chain-level health check. Probes the entire chain end-to-end by dialing
     through `Route.Dial()`. The probe marks the chain entry's own marker, independent
     of any node-level markers inside the chain.

### Probe

Probe configuration for chain entries. Same structure as [Node Probe](../../concepts/chain.md#probe).

`type` (string)
:    Probe type: `tcp`, `http`, or `cmd`.

`addr` (string)
:    Target address for TCP/HTTP probes. Required for non-cmd probes.

`interval` (duration)
:    Probe interval. Default: 30s.

`timeout` (duration)
:    Probe timeout. Default: 10s.

`httpPath` (string)
:    HTTP request path (HTTP probe only).

`httpHost` (string)
:    HTTP Host header (HTTP probe only).

`httpHeaders` (map)
:    Additional HTTP request headers (HTTP probe only).

`expectedStatus` (int)
:    Expected HTTP response status code. Default: 0 (any 2xx).

`command` (string)
:    Shell command to execute (CMD probe only). Exit code 0 = success.

### Backward Compatibility

Chain entries accept both formats:

```yaml
# Old: plain string
chains:
- chain-0
- chain-1

# New: structured object
chains:
- chain: chain-0
  matcher:
    rule: Host(`api.example.com`)
  probe:
    type: tcp
```


`name` (string, required)
:    跳跃点名称

`interface` (string)
:    网络接口名或IP地址

`sockopts` (object)
:    Socket参数

`selector` (object)
:    跳跃点层级节点选择器，如果设置，则覆盖转发链层级选择器

`bypass` (string, ref)
:    bypass名称，引用`bypasses.name`

`nodes` (node-list)
:    节点列表

## 节点(Node)

`name` (string, required)
:    节点名称

`addr` (string, required)
:    节点地址

`interface` (string)
:    网络接口名或IP地址，如果设置，则会覆盖`hop.interface`

`sockopts` (object)
:    Socket参数，如果设置，则会覆盖`hop.sockopts`

`bypass` (string, ref)
:    bypass名称，引用`bypasses.name`。
     如果未设置，则使用`hop.bypass`

`connector` (object)
:    连接器对象

`dialer` (object)
:    拨号器对象

### 连接器(Connector)

`type` (string, required)
:    连接器类型

`auth` (object)
:    认证信息

`metadata` (map)
:    连接器实例相关参数

### 拨号器(Dialer)

`type` (string, required)
:    拨号器类型

`auth` (object)
:    认证信息

`tls` (object)
:    TLS配置

`metadata` (map)
:    拨号器实例相关参数

### Node Matcher

:material-tag: 3.3.0

Each node can carry a `matcher` to participate in request-based routing. For the full
DSL reference (all functions, boolean operators, examples) see [Matcher](../../concepts/matcher.md).

`rule` (string)
:    Routing rule expression. Supports boolean operators (`&&`, `||`, `!`) and matcher functions:
     `Method`, `Path`, `PathPrefix`, `PathRegexp`, `Host`, `HostRegexp`, `Header`, `HeaderRegexp`,
     `Query`, `QueryRegexp`, `BodyRegexp`, `BodyJSON`, `ClientIP`, `Network`, `Proto`, `Bypass`, `Admission`.

`bodySize` (int)
:    Maximum size of HTTP request body prefix (in bytes) to read for body matchers. Default: 0 (disabled).

`priority` (int)
:    Node selection priority. 0 (default) auto-sets priority to the rule length so longer
      (more specific) rules outrank shorter ones. Negative disables priority ordering.

```yaml
matcher:
  rule: 'Method(`POST`) && Header(`Content-Type`, `application/json`) && BodyJSON(`output_config.effort`, `^(xhigh|max)$`)'
  bodySize: 65536
```

### Node HTTP Settings

`http` (object)
:    HTTP-level settings for the node: host override, header injection, URL rewriting, and body rewriting.

`http.host` (string)
:    Override the HTTP Host header.

`http.requestHeader` (map)
:    Additional HTTP request headers to inject.

`http.responseHeader` (map)
:    Additional HTTP response headers to inject.

`http.rewriteURL` (list)
:    URL path rewrite rules. Each entry has `match` (regex) and `replacement`.

`http.rewriteRequestBody` (list)
:    Request body rewrite rules. Each entry has:
      `match` (string) — regex or `json:<path>[=<regex>]` for JSON field matching; use `json-:<path>[=<regex>]` to delete the matched field instead of replacing it;
      `replacement` (string) — replacement value;
      `rewriter` (string) — optional external rewriter plugin;
      `type` (string) — optional content-type filter.

`http.rewriteResponseBody` (list)
:    Response body rewrite rules. Same structure as `rewriteRequestBody`.

```yaml
http:
  host: api.deepseek.com
  rewriteURL:
    - match: /v1/messages
      replacement: /anthropic/v1/messages
  requestHeader:
    Authorization: "Bearer sk-xxx"
  rewriteRequestBody:
    - match: json:model
      replacement: deepseek-v4-pro
    - match: json:output_config.effort=(xhigh|max)
      replacement: low
  rewriteResponseBody:
    - rewriter: anthropic-converter
```

## TLS

`certFile` (string)
:    证书公钥文件

`keyFile` (string)
:    证书私钥文件

`caFile` (string)
:    CA证书文件

`secure` (bool, default=false)
:    开启服务器证书和域名校验

`serverName` (string)
:    服务器域名，用于域名校验

:material-tag: 3.3.0

`rejectUnknownSNI` (bool, default=false)
:    拒绝SNI未知或为空的TLS握手，被拒绝的连接不会返回任何证书。

`serverNames` (list)
:    允许的SNI白名单。当`rejectUnknownSNI`开启且此列表非空时，任何不在列表中的SNI（包括空SNI）都会被拒绝；当列表为空且`rejectUnknownSNI`开启时，仅拒绝缺少或为空SNI的握手。

## 认证器(Auther)

`name` (string, required)
:    名称

`auths` (list)
:    认证信息列表

## 认证信息(Auth)

`username` (string)
:    用户名

`password` (string)
:    密码

## 节点选择器(Selector)

`strategy` (string, default=round)
:   Node selection strategy:

    * `round`, `rr` - round robin
    * `random`, `rand` - random
    * `fifo` - primary/standby mode
    * `hash` - based on a specific hash value (client IP or destination address)
    * `parallel` - race mode, dials all nodes concurrently and uses the first successful connection

`maxFails` (int, default=1)
:    节点连接最大失败次数

`failTimeout` (duration, default=30s)
:    节点失败标记超时时长

## 准入控制器(Admission)

`name` (string, required)
:    admission name

`whitelist` (bool, default=false)
:    whitelist mode

`matchers` (strings)
:    地址列表，支持IP，CIDR

## 分流器(Bypass)

`name` (string, required)
:    bypass名称

`reverse` (bool, default=false)
:    切换为白名单

`matchers` (strings)
:    地址列表，支持IP，CIDR，域名或域名通配符

## 域名解析器(Resolver)

`name` (string, required)
:    名称

`nameservers` (list)
:    域名服务列表

### 域名服务(Nameserver)

`addr` (string, required)
:    域名地址

`chain` (string, ref)
:    转发链名称，引用`chains.name`

`prefer` (string, default=ipv4)
:    IP地址类型优先级

     * `ipv4` - IPv4优先
     * `ipv6` - IPv6优先

`clientIP` (string)
:    客户端IP，设置后会开启ECS(EDNS Client Subnet)扩展功能。

`ttl` (duration)
:    DNS缓存有效期，默认使用DNS查询返回结果中的TTL。当设置为负值，则不使用缓存。

`timeout` (duration)

:     DNS请求超时时长

## 主机映射器(Hosts)

主机名-IP地址静态映射表

`name` (string, required)
:    映射表名称

`mappings` (list)
:    映射列表

### 映射列表项(mapping)

`ip` (string)
:    IP地址

`hostname` (string)
:    主机名

`aliases` (strings)
:    主机别名列表

## Socket参数(SockOpts)

`mark` (int)
:    Linux Socket SO_MARK参数选项

## Recorder

`name` (string, required)
:    Name

`file` (object)
:    File recorder

`tcp` (object)
:    TCP recorder

`http` (object)
:    HTTP recorder

`redis` (object)
:    Redis recorder

`plugin` (object)
:    gRPC plugin recorder

!!! info "Reference"
    See [Recorder](../../concepts/recorder.md) for detailed recorder configuration.

## 日志(log)

日志配置，设置日志级别，格式和输出方式。

`level` (string, default=info)
:    日志级别，支持的选项：`trace`，`debug`，`info`，`warn`，`error`，`fatal`。

`format` (string, default=json)
:    日志格式，支持的格式：`json`，`text`。

`output` (string, default=stderr)
:    日志输出方式：
  
     * `none` - 丢弃日志。
     * `stderr` - 标准错误流
     * `stdout` - 标准输出流
     * `/path/to/file` - 指定的文件路径

`rotation.maxSize` (int, default=100)
:    The maximum size in megabytes of the log file before it gets rotated. It defaults to 100 megabytes.

`rotation.maxAge` (int)
:    The maximum number of days to retain old log files based on the timestamp encoded in their filename. Note that a day is defined as 24 hours and may not exactly correspond to calendar days due to daylight savings, leap seconds, etc. The default is not to remove old log files based on age.

`rotation.maxBackups` (int)
:    the maximum number of old log files to retain. The default is to retain all old log files (though `maxAge` may still cause them to get deleted.)

`rotation.localTime` (bool, default=false)
:    Determines if the time used for formatting the timestamps in backup files is the computer's local time. The default is to use UTC time.

`rotation.compress` (bool, default=false)
:    Determines if the rotated log files should be compressed using gzip. The default is not to perform compression.


## Profiling

`addr` (string)
:    服务地址

`enabled` (bool, default=false)
:    是否开启

## API

`addr` (string)
:    WebAPI服务地址，设置后将开启WebAPI服务

`pathPrefix` (string)
:    设置API路径前缀

`accesslog` (bool, default=false)
:    开启API访问日志

`auth` (object)
:    认证信息，如果设置了`auther`，此字段无效。

`auther` (string)
:    认证器名称，引用`authers.name`

## Metrics

`addr` (string)
:    服务地址

`path` (string, default=/metrics)
:    访问路径