# Websocket

名称: `ws`, `wss`

状态： Stable

Websocket拨号器使用Websocket或Websocket Secure(Websocket Over TLS)协议建立数据通道。

## Websocket

=== "命令行"
    ```
	gost -L :8080 -F http+ws://:8080?path=/ws
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
            type: ws
		    metadata:
		      path: /ws
		      header:
		        foo: bar
    ```

## Websocket Over TLS

=== "命令行"
    ```
	gost -L :8080 -F http+wss://:8443?path=/ws
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
            type: wss
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

`readBufferSize` (duration)
:    读缓冲区大小

`writeBufferSize` (duration)
:    写缓冲区大小

`enableCompression` (bool, default=false)
:    开启压缩


TLS配置请参考[TLS配置说明](/tutorials/tls/)。