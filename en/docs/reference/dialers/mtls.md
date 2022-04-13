# 多路复用TLS

名称: `mtls`

状态： GA

多路复用TLS拨号器使用TLS协议进行通讯，并与mtls服务建立多路复用会话和数据通道。

=== "命令行"
    ```
    gost -L :8080 -F http+mtls://:8443
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
            type: mtls
    ```

## 参数列表

`muxKeepAliveDisabled` (bool, default=false)
:    多路复用会话设置。禁用心跳保活

`muxKeepAliveInterval` (duration, default=10s)
:    多路复用会话设置。心跳间隔

`muxKeepAliveTimeout` (duration, default=30s)
:    多路复用会话设置。心跳超时

`muxMaxFrameSize` (int, default=32768)
:    多路复用会话设置。最大数据帧大小(字节)

`muxMaxReceiveBuffer` (int, default=4194304)
:    多路复用会话设置。最大接收缓冲大小(字节)

`muxMaxStreamBuffer` (int, default=65536)
:    多路复用会话设置。最大流缓冲大小(字节)


TLS配置请参考[TLS配置说明](/tutorials/tls/)。