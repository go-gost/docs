# Shadowsocks

名称： `ss`

状态： Stable

SS连接器使用Shadowsocks协议进行数据交互。

=== "命令行"
    ```
	gost -L :8000 -F ss://AEAD_CHACHA20_POLY1305:123456@:8338
	```

=== "配置文件"
    ```yaml
	services:
	- name: service-0
	  addr: ":8000"
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
		  addr: :8338
		  connector:
			type: ss
			auth:
              username: AEAD_CHACHA20_POLY1305
              password: "123456"
		  dialer:
			type: tcp
	```

!!! note "`none` / `dummy` 密码模式 (v3.3.0+)"
    GOST 支持 `none` 和 `dummy` 密码模式（大小写不敏感），用于调试、测试和兼容性场景。此模式使用标准的 SS AEAD 协议帧格式（2字节长度前缀 + salt + 目标地址），但不进行实际的数据加密。

    === "命令行"
        ```
        gost -L ":8080" -F "ss://none@proxy.example.com:8338"
        ```
        ```
        gost -L ":8080" -F "ssu://none@proxy.example.com:8338"
        ```

    === "配置文件"
        ```yaml
        connector:
          type: ss
          auth:
            username: none
            password: ""
        ```

    !!! warning "安全提示"
        `none` / `dummy` 模式不提供任何数据机密性和完整性保护。仅用于调试、测试和兼容性场景，切勿在生产环境中使用。

## 参数列表

`nodelay` (bool, default=false)
:    默认情况下ss协议会等待客户端的请求数据，当收到请求数据后会把协议头部信息与请求数据一起发给服务端。当此参数设为true后，协议头部信息会立即发给服务端，不再等待客户端的请求。
