# Websocket

Websocket是GOST中的一种数据通道类型。

!!! tip "TLS证书配置"
    TLS配置请参考[TLS配置说明](/tutorials/tls/)。

## Websocket

未加密的Websocket数据通道。

=== "命令行"

    ```
    gost -L ws://:8080
    ```

=== "配置文件"

    ```yaml
    services:
    - name: service-0
      addr: :
      handler:
        type: auto
      listener:
        type: ws
    ```

## Websocket Secure

基于TLS加密的Websocket数据通道。

=== "命令行"

    ```
    gost -L wss://:8080
    ```

=== "配置文件"

    ```yaml
    services:
    - name: service-0
      addr: :
      handler:
        type: auto
      listener:
        type: wss
    ```

## 多路复用

GOST在Websocket基础之上扩展出具有多路复用(Multiplex)特性的传输类型`mws`和`mwss`。多路复用基于[xtaci/smux](https://github.com/xtaci/smux)库。

=== "命令行"

    ```
    gost -L mws://:8443
    ```

    ```
    gost -L mwss://:8443
    ```

=== "配置文件"

    ```yaml
    services:
    - name: service-0
      addr: :
      handler:
        type: auto
      listener:
        type: mws
        # type: mwss
    ```

## 参数选项

### 自定义请求路径

可以通过`path`选项自定义请求路径，默认值为`/ws`。

!!! note "路径匹配验证“
    仅当客户端和服务端设定的path参数相同时，连接才能成功建立。

#### 服务端

=== "命令行"

    ```bash
    gost -L wss://:8443?path=/ws
    ```

=== "配置文件"

    ```yaml
    services:
    - name: service-0
      addr: :8443
      handler:
        type: auto
      listener:
        type: wss
		metadata:
		  path: /ws
    ```

#### 客户端

=== "命令行"

    ```bash
    gost -L http://:8080 -F wss://:8443?path=/ws
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
            type: wss
            metadata:
              path: /ws
    ```

### 自定义请求主机名

客户端默认使用节点地址(-F参数或nodes.addr中指定的地址)作为请求主机名(`Host`头部信息)，可以通过`host`参数自定义请求主机名。

=== "命令行"

    ```bash
    gost -L http://:8080 -F wss://:8443?host=example.com
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
            type: wss
            metadata:
              host: example.com
    ```

### 自定义HTTP头

通过`header`选项可以自定义请求和响应头部信息。

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
        type: wss
        metadata:
          header:
            foo: bar
            baz: 123
```

### 心跳

客户端可以通过`keepAlive`选项开启心跳，并通过`ttl`选项设置心跳包发送的间隔时长。

=== "命令行"

    ```bash
    gost -L http://:8080 -F "wss://:8443?keepAlive=true&ttl=15s"
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
            type: wss
            metadata:
              keepAlive: true
              ttl: 15s
    ```

## 代理协议

Websocket数据通道可以与各种代理协议组合使用。

### HTTP Over Websocket

=== "命令行"

    ```bash
    gost -L http+wss://:8443
    ```

=== "配置文件"

    ```yaml
    services:
    - name: service-0
      addr: :8443
      handler:
        type: http
      listener:
        type: wss
        # type: mwss
    ```

### SOCKS5 Over Websocket

=== "命令行"

    ```bash
    gost -L socks5+wss://:8443
    ```

=== "配置文件"

    ```yaml
    services:
    - name: service-0
      addr: :8443
      handler:
        type: socks5
      listener:
        type: wss
        # type: mwss
    ```

### Relay Over Websocket

=== "命令行"

    ```bash
    gost -L relay+wss://:8443
    ```

=== "配置文件"

    ```yaml
    services:
    - name: service-0
      addr: :8443
      handler:
        type: relay
      listener:
        type: wss
        # type: mwss
    ```

## 端口转发

Websocket通道也可以用作端口转发。

### 服务端

=== "命令行"

    ```bash
    gost -L wss://:8443/:1080 -L socks5://:1080
    ```
	等同于
    ```bash
    gost -L forward+wss://:8443/:1080 -L socks5://:1080
    ```

=== "配置文件"

    ```yaml
    services:
    - name: service-0
      addr: :8443
      handler:
        type: forward
      listener:
        type: wss
      forwarder:
        nodes:
        - name: target-0
          addr: :1080
    - name: service-1
      addr: :1080
      handler:
        type: socks5
      listener:
        type: tcp
    ```

通过使用Websocket数据通道的端口转发，给1080端口的SOCKS5代理服务增加了Websocket数据通道。

此时8443端口等同于：

```bash
gost -L socks5+wss://:8443
```
