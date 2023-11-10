# HTTP3

HTTP3有两种模式：通道模式和反向代理模式。

## 数据通道

HTTP3的数据通道有两种模式：PHT和WebTransport。

### PHT

由于HTTP3和HTTP协议类似，本身是用作Web数据传输，不能直接作为数据通道使用。GOST中的HTTP3数据通道采用PHT-over-HTTP3，在HTTP3协议之上利用[PHT](/tutorials/protocols/pht/)来实现数据通道功能。

=== "命令行"

  ```bash
	gost -L "h3://:8443?authorizePath=/authorize&pushPath=/push&pullPath=/pull"
	```

=== "配置文件"

    ```yaml
    services:
    - name: service-0
      addr: ":8443"
      handler:
        type: auto
      listener:
        type: h3
        metadata:
          authorizePath: /authorize
          pullPath: /pull
          pushPath: /push
    ```

### WebTransport

与HTTP协议中的Websocket类似，HTTP3中也定义了一个用于双向数据传输的扩展协议[WebTransport](https://web.dev/webtransport/)。

=== "命令行"

    ```bash
    gost -L "wt://:8443"
    ```

=== "配置文件"

    ```yaml
    services:
    - name: service-0
      addr: ":8443"
      handler:
        type: auto
      listener:
        type: wt
    ```

## 反向代理

HTTP3-to-HTTP反向代理。

HTTP3反向代理服务可以动态的给后端HTTP服务添加HTTP/3支持。

```yaml
services:
- name: http3
  addr: :443
  handler:
    type: http3
  listener:
    type: http3
  forwarder:
    nodes:
    - name: example-com
      addr: example.com:80
      host: .example.com
    - name: example-org
      addr: example.org:80
      host: .example.org
```

```bash
curl -k --http3 --resolve example.com:443:127.0.0.1 https://example.com
```

