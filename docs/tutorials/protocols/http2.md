# HTTP2

HTTP2有两种模式：代理模式和通道模式。

## 代理模式

在代理模式中，HTTP2被用作代理协议，HTTP2代理的数据通道层必须为`http2`。

=== "命令行"

    ```bash
    gost -L http2://:8443
    ```

=== "配置文件"

    ```yaml
    services:
    - name: service-0
      addr: :8443
      handler:
        type: http2
      listener:
        type: http2
    ```

## 通道模式

在通道模式中，HTTP2被用作数据通道，分为加密(h2)和明文(h2c)两种。

=== "命令行"

    ```bash
    gost -L http+h2://:8443
    ```

	```bash
    gost -L http+h2c://:8080
	```

=== "配置文件"

    ```yaml
    services:
    - name: service-0
      addr: :8443
      handler:
        type: http
      listener:
        type: h2
        # type: h2c
    ```

### 自定义请求路径

HTTP2数据通道默认使用`CONNECT`方法建立连接，可以通过`path`选项自定义请求路径，此时则采用`GET`方法建立连接。

!!! note "路径匹配验证"
    仅当客户端和服务端设定的path参数相同时，连接才能成功建立。

**服务端**

=== "命令行"

    ```bash
    gost -L http+h2://:8443?path=/http2
    ```

=== "配置文件"

    ```yaml
    services:
    - name: service-0
      addr: :8443
      handler:
        type: http
      listener:
        type: h2
		metadata:
		  path: /http2
    ```

**客户端**

=== "命令行"

    ```bash
    gost -L http://:8080 -F http+h2://:8443?path=/http2
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
          addr: :8443
          connector:
            type: http
          dialer:
            type: h2
            metadata:
              path: /http2
    ```

### 自定义请求主机名

HTTP2数据通道客户端默认使用节点地址(-F参数或nodes.addr中指定的地址)作为请求主机名(`Host`头部信息)，可以通过`host`参数自定义请求主机名。

=== "命令行"

    ```bash
    gost -L http://:8080 -F http+h2://:8443?host=example.com
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
          addr: :8443
          connector:
            type: http
          dialer:
            type: h2
            metadata:
              host: example.com
    ```

### 自定义HTTP请求头

通过`header`选项可以自定义请求头部信息。

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
      addr: :8443
      connector:
        type: http
      dialer:
        type: h2
        metadata:
          header:
            User-Agent: "gost/3.0"
            foo: bar
```