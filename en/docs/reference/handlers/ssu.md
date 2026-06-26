# Shadowsocks UDP Relay

Name: `ssu`

Status： Stable

ssu处理器使用Shadowsocks UDP转发协议进行数据交互，用于转发UDP数据。

!!! tip "默认监听器"
    当不指定监听器时，SSU处理器默认使用UDP作为监听器。当然你也可以指定其他兼容类型的监听器(例如TCP, TLS等)。

=== "CLI"
    ```
	gost -L ssu://AEAD_CHACHA20_POLY1305:123456@:8338
	```
	等同于
	```
	gost -L ssu+udp://AEAD_CHACHA20_POLY1305:123456@:8338
	```
=== "File (YAML)"
    ```yaml
	services:
	- name: service-0
	  addr: ":8338"
	  handler:
		type: ssu
		auth:
		  username: AEAD_CHACHA20_POLY1305
		  password: "123456"
	  listener:
		type: udp
	```

## 参数列表

`bufferSize` (int, default=1500)
:    UDP数据缓冲大小

!!! note "`none` / `dummy` Cipher Mode (v3.3.0+)"
    GOST supports `none` and `dummy` cipher modes (case-insensitive) for debugging, testing, and compatibility. This mode uses the standard SS AEAD wire framing (2-byte length prefix + salt + target address) without actual UDP data encryption.

    === "CLI"
        ```
        gost -L "ssu://none@:8338"
        ```
        ```
        gost -L ":8080" -F "ssu://none@proxy.example.com:8338"
        ```

    === "File (YAML)"
        ```yaml
        auth:
          username: none
          password: ""
        ```

    !!! warning "Security"
        The `none` / `dummy` mode provides zero confidentiality or integrity protection. It is intended for debugging and testing only — never use it in production.

!!! note "认证信息"
    SSU理器只能使用单认证信息方式设置加密信息，不能支持认证器。