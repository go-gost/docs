# uTLS

名称: `utls`

状态： GA

uTLS拨号器使用[uTLS](https://github.com/refraction-networking/utls)库建立TLS数据通道，可通过`fingerprint`参数模拟各种客户端的ClientHello特征（浏览器指纹），用于规避基于TLS指纹的识别。

=== "命令行"
    ```
    gost -L :8080 -F http+utls://:8443
    ```
=== "配置文件"
    ```yaml
    services:
    - name: service-0
      addr: ":8080"
      handler:
        type: auto
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
            type: utls
            metadata:
              fingerprint: chrome
            tls:
              secure: false
    ```

## 参数列表

`fingerprint` (string)
:    TLS指纹（ClientHello）类型，可选值：`chrome`，`firefox`，`ios`，`safari`，`edge`，`randomized`，`randomized-alpn`，`randomized-noalpn`，`golang`，`custom`。为空或`golang`时回退到标准`crypto/tls`。

`handshakeTimeout` (duration)
:    TLS握手超时时间。

`keepalive` (bool)
:    是否开启TCP Keep-Alive。

`keepalive.idle` (duration)
:    TCP Keep-Alive空闲时间。

`keepalive.interval` (duration)
:    TCP Keep-Alive探测间隔。

`keepalive.count` (int)
:    TCP Keep-Alive探测次数。

TLS相关配置（如`secure`，`serverName`，`caFile`，`certFile`，`keyFile`等）请参考[TLS配置说明](/tutorials/tls/)。
