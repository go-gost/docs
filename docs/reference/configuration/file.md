# 配置文件

!!! tip "建议"
    在使用配置文件前，建议先了解一下GOST中的一些基本概念和架构，对于理解配置文件会有很大帮助。
	
	你也可以随时在命令行模式下使用`-O -`查看对应的配置。

!!! note "注意"
    如果`-C`和`-L`参数都未指定，GOST会默认使用当前目录，`/etc/gost/`或`$HOME/gost/`目录中的`gost.yml`文件作为配置文件。

如果需要更精细的进行配置，可以使用外部配置文件。GOST的配置文件使用yaml格式。配置文件的结构如下：

??? example "配置示例"

    ```yaml
    log:
      output: stderr
      level: debug
      format: json

    services:
    - name: service-0
      addr: ":8080"
      handler:
        type: http
        chain: chain-0
        metadata: {}
      listener:
        type: tcp
        metadata: {}

    chains:
    - name: chain-0
      hops:
      - name: hop-0
        nodes:
        - name: node-0
          addr: ":1080"
          connector:
            type: socks5
            metadata: {}
          dialer:
            type: tcp
            metadata: {}

    tls:
      cert: "cert.pem"
      key: "key.pem"
      # ca: "root.ca"

    bypasses:
    - name: bypass-0
      reverse: false
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
      entries:
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

    profiling:
      addr: ":6060"
      enabled: true

    ```

## 参数说明

`log`
:    日志配置，设置日志级别，格式和输出方式。

     * `level` - 默认值：`info`。日志级别，支持的选项：`debug`，`info`，`warn`，`error`，`fatal`。
     * `format` - 默认值：`json`。日志格式，支持的格式：`json`，`text`。
     * `output` - 默认值：`stderr`。日志输出方式：
       
         > `none` - 丢弃日志。

         > `stderr` - 标准错误流

         > `stdout` - 标准输出流

         > `/path/to/file` - 指定的文件路径

`services`
:    服务列表。

     * `name` - 服务名
     * `addr` - 服务地址
     * `handler` - 处理器对象
     * `listener` - 监听器对象

`services.handler`
:    处理器对象。

     * `type` - 类型
     * `retries` - 请求处理失败重试次数
     * `chain` - 转发链名称，对应`chains.name`
     * `bypass` - 对应`bypasses.name`
     * `resolver` - 对应`resolvers.name`
     * `hosts` - 对应`hosts.name`
     * `auths` - 认证信息列表
     * `tls` - TLS证书信息
     * `metadata` - 处理器实例特有选项

`services.listener`
:    监听器对象。
    
     * `type` - 类型
     * `chain` - 对应`chains.name`
     * `auths` - 认证信息列表
     * `tls` - TLS证书信息
     * `metadata` - 监听器实例特有选项