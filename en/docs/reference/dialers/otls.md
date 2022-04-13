# TLS混淆

名称: `otls`

状态： GA

OTLS拨号器使用伪TLS协议建立数据通道。

=== "命令行"
    ```
    gost -L :8080 -F http+otls://:8443
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
            type: otls
    ```

## 参数列表

`host` (string)
:    指定TLS请求SNI字段。

