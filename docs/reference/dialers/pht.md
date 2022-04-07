# Plain HTTP Tunnel

名称: `pht`

状态： Alpha

PHT拨号器使用HTTP协议与服务建立数据通道。

=== "命令行"
    ```
    gost -L :8080 http+pht://:8443
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
            type: pht
    ```

## 参数列表

`authorizePath` (string, default=/authorize)
:    用户授权接口URI

`pushPath` (string, default=/push)
:    数据发送URI

`pullPath` (string, default=/pull)
:   数据接收URI
