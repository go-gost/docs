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

!!! note "`none` / `dummy` Cipher Mode (v3.3.0+)"
    GOST supports `none` and `dummy` cipher modes (case-insensitive) for debugging, testing, and compatibility. This mode uses the standard SS AEAD wire framing (2-byte length prefix + salt + target address) without actual encryption.

    === "CLI"
        ```
        gost -L ":8080" -F "ss://none@proxy.example.com:8338"
        ```
        ```
        gost -L ":8080" -F "ssu://none@proxy.example.com:8338"
        ```

    === "File (YAML)"
        ```yaml
        connector:
          type: ss
          auth:
            username: none
            password: ""
        ```

    !!! warning "Security"
        The `none` / `dummy` mode provides zero confidentiality or integrity protection. It is intended for debugging and testing only — never use it in production.

## 参数列表

`nodelay` (bool, default=false)
:    默认情况下ss协议会等待客户端的请求数据，当收到请求数据后会把协议头部信息与请求数据一起发给服务端。当此参数设为true后，协议头部信息会立即发给服务端，不再等待客户端的请求。
