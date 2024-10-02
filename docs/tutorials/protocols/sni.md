---
comments: true
---

# SNI

[SNI](https://www.cloudflare.com/zh-cn/learning/ssl/what-is-sni/)(Server Name Indication)是TLS协议的扩展，包含在TLS握手的流程中(Client Hello)，用来标识所访问目标主机名。SNI代理通过解析TLS握手信息中的SNI部分，从而获取目标访问地址。

SNI代理同时也接受HTTP请求，使用HTTP的`Host`头作为目标访问地址。

## 标准SNI代理

=== "命令行"

    ```bash
    gost -L sni://:443
    ```

=== "配置文件"

    ```yaml
    services:
    - name: service-0
      addr: :443
      handler:
        type: sni
      listener:
        type: tcp
    ```

## Host混淆

SNI客户端可以通过`host`选项来指定Host别名，SNI客户端会将TLS握手中的SNI部分或HTTP请求头中的Host替换为host选项指定的内容。

=== "命令行"

    ```bash
    gost -L http://:8080 -F sni://:443?host=example.com
    ```

=== "配置文件"

    ```yaml
    services:
    - name: service-0
      addr: :8080
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
          addr: :443
          connector:
            type: sni
            metadata:
              host: example.com
          dialer:
            type: tcp
    ```


## 数据通道

SNI代理属于数据处理层，因此也可以与各种数据通道组合使用。

### SNI Over TLS

=== "命令行"

    ```bash
    gost -L sni+tls://:8443
    ```

=== "配置文件"

    ```yaml
    services:
    - name: service-0
      addr: :8443
      handler:
        type: sni
      listener:
        type: tls
    ```

### SNI Over Websocket

=== "命令行"

    ```bash
    gost -L sni+ws://:8080
    ```

    ```bash
    gost -L sni+wss://:8080
    ```

=== "配置文件"

    ```yaml
    services:
    - name: service-0
      addr: :8080
      handler:
        type: sni 
      listener:
        type: ws
        # type: wss
    ```

### SS Over KCP

=== "命令行"

    ```bash
    gost -L sni+kcp://:8080
    ```

=== "配置文件"

    ```yaml
    services:
    - name: service-0
      addr: :8080
      handler:
        type: sni
      listener:
        type: kcp
    ```
