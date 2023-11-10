# HTTP

HTTP代理是利用HTTP协议的[CONNECT方法](https://developer.mozilla.org/zh-CN/docs/Web/HTTP/Methods/CONNECT)实现的代理服务。

## 标准HTTP代理

一个最简单的无加密无认证的HTTP代理服务。

=== "命令行"

    ```bash
    gost -L http://:8080
    ```

=== "配置文件"

    ```yaml
    services:
    - name: service-0
      addr: :8080
      handler:
        type: http
      listener:
        type: tcp
    ```

## 标准HTTP代理(开启认证)

一个无加密具有用户认证的HTTP代理服务。

=== "命令行"

    ```bash
    gost -L http://user:pass@:8080
    ```

=== "配置文件"

    ```yaml
    services:
    - name: service-0
      addr: :8080
      handler:
        type: http
        auth:
          username: user
          password: pass
      listener:
        type: tcp
    ```

## 参数选项

### 自定义HTTP头

通过`header`选项可以自定义请求和响应头部信息。

```yaml hl_lines="7 8 9 22 23 24"
services:
- name: service-0
  addr: :8080
  handler:
    type: http
    chain: chain-0
    header:
      Proxy-Agent: "gost/3.0"
      foo: bar
  listener:
    type: tcp
chains:
- name: chain-0
  hops:
  - name: hop-0
    nodes:
    - name: node-0
      addr: :8443
      connector:
        type: http
        metadata:
          header:
            User-Agent: "gost/3.0"
            foo: bar
      dialer:
        type: tcp
```

## 数据通道

HTTP代理可以与各种数据通道组合使用。

### HTTP Over TLS

标准HTTPS代理服务。

=== "命令行"

    ```bash
    gost -L https://:8443
    ```
    等同于
    ```
    gost -L http+tls://:8443
    ```

=== "配置文件"

    ```yaml
    services:
    - name: service-0
      addr: :8443
      handler:
        type: http
      listener:
        type: tls
    ```

### HTTP Over Websocket

=== "命令行"

    ```bash
    gost -L http+ws://:8080
    ```

    ```bash
    gost -L http+wss://:8080
    ```

=== "配置文件"

    ```yaml
    services:
    - name: service-0
      addr: :8080
      handler:
        type: http
      listener:
        type: ws
        # type: wss
    ```

### HTTP Over KCP

=== "命令行"

    ```bash
    gost -L http+kcp://:8080
    ```

=== "配置文件"

    ```yaml
    services:
    - name: service-0
      addr: :8080
      handler:
        type: http
      listener:
        type: kcp
    ```

## UDP数据转发

HTTP代理在标准协议基础之上扩展了对UDP数据的支持，实现UDP-Over-HTTP功能。
HTTP代理服务UDP转发功能默认关闭，需要通过`udp`选项开启。

**服务端**

=== "命令行"

    ```bash
    gost -L http://:8080?udp=true
    ```

=== "配置文件"

    ```yaml
    services:
    - name: service-0
      addr: :8080
      handler:
        type: http
        metadata:
          udp: true
      listener:
        type: tcp
    ```

**客户端**

=== "命令行"

    ```bash
    gost -L udp://:10053/1.1.1.1:53 -F http://:8080
    ```

=== "配置文件"

    ```yaml
    services:
    - name: service-0
      addr: :10053
      handler:
        type: udp
        chain: chain-0
      listener:
        type: udp
      forwarder:
        nodes:
        - name: target-0
          addr: 1.1.1.1:53
    chains:
    - name: chain-0
      hops:
      - name: hop-0
        nodes:
        - name: node-0
          addr: :8080
          connector:
            type: http
          dialer:
            type: tcp
    ```