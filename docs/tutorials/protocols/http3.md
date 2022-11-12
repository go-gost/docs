# HTTP3

HTTP3有两种模式：通道模式和反向代理模式。

## 数据通道

由于HTTP3协议本身是一个Web服务，不能直接作为数据通道使用。GOST中的HTTP3数据通道采用PHT-over-HTTP3，在HTTP3协议之上利用PHT来实现数据通道功能。

!!! note "WebTransport"
    [WebTransport](https://web.dev/webtransport/)目前处在早期草案阶段，待时机成熟后GOST会添加对其的支持。

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

