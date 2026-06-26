# Shadowsocks UDP

名称： `ssu`

状态： Stable

ssu连接器使用Shadowsocks UDP转发协议进行数据交互。

!!! tip "默认监听器"
    当不指定拨号器时，SSU处理器默认使用UDP作为拨号器。当然你也可以指定其他兼容类型的拨号器(例如TCP, TLS等)。
    
=== "命令行"
    ```
	gost -L :8000 -F ssu://AEAD_CHACHA20_POLY1305:123456@:8338
	```
	等同于
	```
	gost -L :8000 -F ssu+udp://AEAD_CHACHA20_POLY1305:123456@:8338
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
			type: ssu
			auth:
              username: AEAD_CHACHA20_POLY1305
              password: "123456"
		  dialer:
			type: udp
	```

!!! note "`none` / `dummy` Cipher Mode (v3.3.0+)"
    GOST supports `none` and `dummy` cipher modes (case-insensitive) for debugging, testing, and compatibility. This mode uses the standard SS AEAD wire framing (2-byte length prefix + salt + target address) without actual UDP data encryption.

    === "CLI"
        ```
        gost -L ":8080" -F "ssu://none@proxy.example.com:8338"
        ```

    === "File (YAML)"
        ```yaml
        connector:
          type: ssu
          auth:
            username: none
            password: ""
        ```

    !!! warning "Security"
        The `none` / `dummy` mode provides zero confidentiality or integrity protection. It is intended for debugging and testing only — never use it in production.

## 参数列表

`bufferSize` (int, default=1500)
:    UDP数据缓冲大小
