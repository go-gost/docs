# HTTP混淆

名称: `ohttp`

状态： GA

OHTTP拨号器使用HTTP协议建立数据通道。

=== "命令行"
    ```
    gost -L :8080 -F http+ohttp://:8443
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
            type: ohttp
    ```

## 参数列表

`host` (string)
:    指定HTTP请求`Host`头部字段值

`header` (map)
:    自定义HTTP请求头
