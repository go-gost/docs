# 多路复用Websocket

名称: `mws`, `mwss`

状态： GA

多路复用Websocket拨号器使用Websocket或Websocket Secure(Websocket Over TLS)协议进行通讯，并建立多路复用会话和数据通道。

## Websocket

=== "命令行"
    ```
    gost -L :8080 -F http+mws://:8443?path=/ws
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
            type: mws
		    metadata:
		      path: /ws
		      header:
		        foo: bar
    ```

## Websocket Over TLS

=== "命令行"
    ```
    gost -L :8080 -F http+mwss://:8443?path=/ws
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
            type: mwss
		    metadata:
		      path: /ws
		      header:
		        foo: bar
    ```

## 参数列表

`host` (string)
:    指定HTTP请求`Host`头部字段值

`path` (string, default=/ws)
:    请求URI

`header` (map)
:    自定义HTTP请求头

`keepAlive` (duration)
:    设置心跳间隔时长，默认不开启Websocket心跳

`handshakeTimeout` (duration)
:    设置握手超时时长

`readHeaderTimeout` (duration)
:    设置请求头读取超时时长

`readBufferSize` (int)
:    读缓冲区大小

`writeBufferSize` (int)
:    写缓冲区大小

`enableCompression` (bool, default=false)
:    开启压缩

`muxKeepAliveDisabled` (bool, default=false)
:    多路复用会话设置。禁用心跳保活

`muxKeepAliveInterval` (duration, default=10s)
:    多路复用会话设置。心跳间隔，默认值: 10s

`muxKeepAliveTimeout` (duration, default=30s)
:    多路复用会话设置。心跳超时

`muxMaxFrameSize` (int, default=32768)
:    多路复用会话设置。最大数据帧大小(字节)

`muxMaxReceiveBuffer` (int, default=4194304)
:    多路复用会话设置。最大接收缓冲大小(字节)

`muxMaxStreamBuffer` (int, default=65536)
:    多路复用会话设置。最大流缓冲大小(字节)


TLS配置请参考[TLS配置说明](/tutorials/tls/)。