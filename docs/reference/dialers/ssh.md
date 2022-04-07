# SSH数据通道

名称: `ssh`

状态： GA

SSH拨号器使用SSH协议与SSH服务建立数据通道。

SSH拨号器支持简单用户名/密码认证和公钥认证。

## 用户名/密码认证

=== "命令行"
    ```
    gost -L :8080 -F http+ssh://gost:gost@:8443
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
            type: ssh
		    auth:
		      username: gost 
		      password: gost
    ```

!!! caution "认证信息"
    认证信息作用于拨号器，如果需要对连接器设置认证可以通过配置文件指定
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
		    auth:
		      username: gost 
		      password: gost
          dialer:
            type: ssh
    ```

## 公钥认证

=== "命令行"
    ```
    gost -L :8080 -F http+ssh://gost@:8443?privateKeyFile=/path/to/privateKeyFile
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
            type: ssh
		    auth:
		      username: gost
		    metadata:
		      privateKeyFile: /path/to/privateKeyFile
			  # optional passphrase for privateKeyFile
			  # passphrase: pass
    ```

## 参数列表

`privateKeyFile` (string)
:    证书私钥文件

`passphrase` (string)
:    证书密码
